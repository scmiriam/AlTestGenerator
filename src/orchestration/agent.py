"""
agent.py — ALTestAgent: agente RAG híbrido para generar tests AL de Business Central.

Arquitectura:
  1. Contexto base (Python): RAG + fichero fuente + test de referencia + grabación UI opcional
  2. Tool calls extra (LLM): hasta MAX_EXTRA_CALLS rondas adicionales
  3. Generación final (LLM): codeunit AL completo
"""
import json
import textwrap
from datetime import datetime, timezone
from pathlib import Path

import yaml

from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage

from src.context.embedder import (
    DEFAULT_PERSIST,
    EMBEDDING_MODEL,
    load_all_docs,
    load_embeddings,
    load_vectorstore,
)
from src.context.retriever import (
    _retrieve_rag,
    _retrieve_examples,
    _find_source_file,
    _find_test_example,
)
from src.orchestration.llm_factory import create_llm
from src.execution.al_tools import make_tools
from src.execution.project_config import ProjectConfig
from src.execution.al_compiler import compile_al

# ── Constantes del agente ─────────────────────────────────────────────

MAX_EXTRA_CALLS    = 4
MAX_FIX_ATTEMPTS   = 2

# Precios en USD por millón de tokens — actualizar en https://openai.com/api/pricing
# y https://www.anthropic.com/pricing cuando cambien.
_MODEL_PRICING: dict[str, tuple[float, float]] = {
    #                              (input $/M, output $/M)
    "gpt-4.1":           (2.00,   8.00),
    "claude-sonnet-4-6": (3.00,  15.00),
}


def _accumulate(usage_acc: dict, response) -> None:
    meta = getattr(response, "usage_metadata", None) or {}
    usage_acc["input_tokens"]  += meta.get("input_tokens", 0)
    usage_acc["output_tokens"] += meta.get("output_tokens", 0)


def _log_usage(operation: str, model: str, usage_acc: dict, log_path: Path) -> None:
    inp, out   = usage_acc["input_tokens"], usage_acc["output_tokens"]
    price_in, price_out = _MODEL_PRICING.get(model, (0.0, 0.0))
    cost = (price_in * inp + price_out * out) / 1_000_000
    record = {
        "ts":            datetime.now(timezone.utc).isoformat(),
        "operation":     operation,
        "model":         model,
        "input_tokens":  inp,
        "output_tokens": out,
        "total_tokens":  inp + out,
        "cost_usd":      round(cost, 6),
    }
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")
    print(f"[usage] {operation} | in={inp} out={out} | ${cost:.4f}")


# ── Parser de grabaciones UI (YAML) ──────────────────────────────────

_STEP_HANDLERS = {
    "invoke":          lambda s: _fmt_invoke(s),
    "page-shown":      lambda s: f"[Page opened] \"{s['source']['page']}\"" + (" (modal)" if s.get("modal") else ""),
    "page-closed":     lambda s: f"[Page closed] \"{s['source']['page']}\"",
    "focus":           lambda s: f"[Focus] Field \"{s['target'][-1].get('field', '?')}\"",
    "input":           lambda s: f"[Input] \"{s['target'][-1].get('field', '?')}\" = \"{s.get('value', '')}\"",
    "set-current-row": lambda s: f"[Select row] position {s.get('targetRecord', {}).get('relative', '?')} in repeater",
    "message":         lambda s: f"[Message] \"{s.get('text', '')}\"",
}


def _fmt_invoke(step: dict) -> str:
    target      = step.get("target", [])
    invoke_type = step.get("invokeType", "")
    action = next((t.get("action") for t in target if "action" in t), None)
    field  = next((t.get("field")  for t in target if "field"  in t), None)
    page   = next((t.get("page")   for t in target if "page"   in t), "?")

    if action:
        return f"[Action] \"{action}\" on page \"{page}\" (invokeType={invoke_type or 'default'})"
    if field:
        return f"[Invoke {invoke_type or 'default'}] Field \"{field}\" on page \"{page}\""
    return f"[Invoke {invoke_type or 'default'}] Page \"{page}\""


def _parse_recording(yaml_path: Path) -> str:
    """Convierte una grabación YAML de Business Central en texto estructurado para el LLM."""
    data = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))

    name        = data.get("name", yaml_path.stem)
    description = data.get("description", "")
    profile     = (data.get("start") or {}).get("profile", "unknown")
    steps       = data.get("steps", [])

    lines = [
        f"## UI Recording: \"{name}\"",
        f"Description : {description}" if description else "",
        f"Start profile: {profile}",
        "",
        "### Step-by-step flow:",
    ]

    for i, step in enumerate(steps, 1):
        step_type = step.get("type", "unknown")
        handler   = _STEP_HANDLERS.get(step_type)
        if handler:
            try:
                line = handler(step)
            except Exception:
                line = f"[{step_type}] {step.get('description', '')}"
        else:
            line = f"[{step_type}] {step.get('description', '')}"
        lines.append(f"{i:>3}. {line}")

    return "\n".join(l for l in lines if l is not None)


# ── Prompts ───────────────────────────────────────────────────────────

_SYSTEM_BASE = """\
You are a Senior Software Engineer expert in AL and Microsoft Dynamics 365 Business Central,
specialized in writing test codeunits that not only compile but validate real business logic correctly.

You have access to tools (up to {max_calls} calls total).
Follow the three protocols below in order — do not skip any of them.

---

## Protocol 1 — Discovery (run before writing any code)

Spend your tool budget in strict priority order:

**Priority 1 — always, 1–2 calls**
1. Call list_al_files() to map the project structure.
2. Call read_al_file() on the source object being tested to get exact field names,
   types, OnValidate triggers, and procedure signatures.

**Priority 2 — 1–2 calls, if budget allows**
3. If a Library codeunit exists in src/ (name contains "Library" or "Lib"),
   call read_al_file() on it. Its helpers MUST be preferred over Microsoft libraries
   or direct table inserts for any setup the library already covers.

**Priority 3 — remaining calls, for genuine unknowns only**
- Verify a procedure signature you are unsure about.
- Read a report's RequestPage fields before using TestRequestPage.
- Look up a field name you cannot confirm from the source already in context.
- Do NOT re-verify things already visible in the source code or reference test.

**Rule for .alpackages**
If read_al_file() returns "not found", the object lives in .alpackages.
Use read_alpackage_symbols() — never read_al_file() — for those objects.
read_alpackage_symbols() returns field names, types, and procedure signatures
for standard BC objects, Microsoft libraries, and any other extension package.

---

## Protocol 2 — Test generation

### Output scope

| Request | Output |
|---------|--------|
| Single test | Only the [Test] procedure — no codeunit wrapper, no external variable declarations. First statement must be Initialize(). Append a `// NOTE FOR Initialize():` comment listing every table the test writes to. |
| Full suite / codeunit | A complete, compilable AL codeunit with Subtype = Test. |

Example NOTE block:
```
// NOTE FOR Initialize(): add DeleteAll(true) for:
//   - "DTNGAR Guarantee" (DTNGARGuarantee.DeleteAll(true))
//   - "DTNGAR Setup"     (DTNGARSetup.DeleteAll(true))
```

### Structure rules
- Follow GIVEN / WHEN / THEN comment structure in every test.
- Every test procedure must carry the [Test] attribute.
- Use helper procedures (Initialize, Create*, Verify*) in full codeunits.
- Do NOT add a Caption property to codeunits with Subtype = Test.
- Output ONLY AL code — no prose, no markdown fences.

### Test isolation (mandatory — prevents test pollution)
- Include a local Initialize() that calls DeleteAll(true) on every table any test writes to.
  Call Initialize() as the very first statement of every [Test] procedure, no exceptions.
- Declare Record variables LOCAL to a test procedure unless they must be shared with a handler.
  Codeunit-level Record variables retain state across tests and cause false failures.
- Never rely on Commit() to clean up — records written after Commit() persist for all
  subsequent tests in the same run. Initialize() is the only safe cleanup.
- If the object uses NumberSeries / NoSeries, reset it in Initialize() by deleting and
  re-inserting the setup row that defines the series, so each test starts from the same
  first number and avoids "already exists" errors.

### Test naming and scope
- Pattern: `ActionOrFeature_Condition_ExpectedResult`
  Examples: `TransferBond_AlreadyTransferred_RaisesError`, `PostInvoice_MissingVAT_ThrowsSetupError`
- Each test covers exactly ONE scenario. If two scenarios need separate assertions,
  write two separate tests.

### Negative tests — asserterror
```
asserterror SomeProc(args);
Assert.ExpectedError('expected error message fragment');
```
- asserterror catches the error and lets the test continue. Without it, an unexpected
  error aborts the test with a runtime failure instead of a controlled assertion.
- Always follow asserterror with Assert.ExpectedError() or Assert.ExpectedErrorCode().
  An asserterror with no follow-up assertion accepts ANY error — never leave it bare.
- After asserterror, AL rolls back the current transaction. Do not assert record state
  afterwards — the records no longer exist.

### Assertions
- Declare Assert as `Assert: Codeunit Assert` — NOT `Codeunit "Library Assert"`.
- After the action under test, always validate that relevant status or state fields
  changed to the expected value.

### GIVEN — master data and BC-specific setup

**Library priority order (strict):**
1. Project Library helpers (confirmed in Protocol 1 Priority 2) — mandatory if they exist.
2. Microsoft test library codeunits from .alpackages (extensions named "Test Library",
   "Test Libraries", or "Assert"):

| Library | ID | Key procedures |
|---------|----|----------------|
| Library - Random | 130440 | RandDec(), RandInt(), RandText() |
| Library - Sales | 130509 | CreateCustomer, CreateSalesHeader… |
| Library - Purchase | 130512 | CreateVendor, CreatePurchaseHeader… |
| Library - Inventory | 132201 | CreateItem, CreateLocation… |
| Library - ERM | 131300 | Posting setup, VAT, G/L accounts |
| Library - Dimension | 131001 | Dimensions and dimension values |
| Library - Utility | 131000 | General test utilities |

3. Direct table inserts — only when no library covers the need (fragile, last resort).

**Additional rules:**
- Use read_alpackage_symbols() to verify exact procedure signatures before calling any library.
- Always initialize VAT posting groups, general posting setup, and inventory setup before
  posting documents — tests fail at runtime without this.
- NEVER hardcode numeric values (amounts, quantities, percentages, counts).
  Always use LibraryRandom.RandDec() or LibraryRandom.RandInt() — no exceptions.
- Variable types must match parameter types exactly. Never pass a wrong type.

### WHEN — executing the action under test
- Call the codeunit procedure, page action, or report directly.
- Use TestPage only to test UI behaviour (field editability, action visibility,
  page-triggered messages) — never to create setup data.
- NEVER call methods directly on Page or Report objects. Use the appropriate handler:
  - Pages → TestPage inside [ModalPageHandler] or [PageHandler].
  - Reports with a RequestPage → TestRequestPage inside [RequestPageHandler].
- Before using a TestPage or TestRequestPage, verify available fields and actions with
  read_al_file() (project source) or read_alpackage_symbols() (dependency).
  Only use fields that appear in the page/report definition — never assume a table field
  is accessible on a TestPage.
- TestRequestPage is only valid when the report has a RequestPage section. If it does not,
  run the report directly without a handler.

### THEN — asserting results
- Read results directly from tables using FindFirst / FindSet and Assert codeunit methods.
- Always validate status and state fields explicitly after the action.

### Handler functions

Add a handler ONLY when the code under test triggers a UI interaction
(dialog, modal page, message). Handlers on tests that never trigger UI interactions
are dead code and cause compilation warnings.

| Attribute | Triggers | Signature |
|-----------|----------|-----------|
| [MessageHandler] | Message() | (Msg: Text[1024]) |
| [ConfirmHandler] | Confirm() | (Question: Text[1024]; VAR Reply: Boolean) |
| [StrMenuHandler] | StrMenu() | (Options: Text[1024]; VAR Choice: Integer; Instruction: Text[1024]) |
| [PageHandler] | PAGE.RUN (non-modal) | (VAR Page: TestPage "Name") |
| [ModalPageHandler] | Modal pages / card dialogs | (VAR Page: TestPage "Name") |
| [RequestPageHandler] | REPORT.RUN / RUNMODAL | (VAR RequestPage: TestRequestPage "Name") — never for modal pages |
| [ReportHandler] | Reports without a RequestPage | (VAR Report: Report "Name") |

**Handler navigation rule:**
Never use GoToKey() unless the table has a single-field primary key.
For composite keys (e.g. Type + No.), GoToKey() with fewer fields silently fails.
Use SetFilter() + First() instead:
```
Page.Filter.SetFilter("No.", RecordNo);
Page.First();
```

- Only add [HandlerFunctions(...)] for handlers you explicitly define in this codeunit.
- Use TestPermissions only when the scenario explicitly tests permissions.

---

## Protocol 3 — Anti-hallucination (hard rules, no exceptions)

- **Only use identifiers confirmed** by read_al_file(), read_alpackage_symbols(),
  the source code, the reference test, or RAG snippets. Never invent or guess.
- **Verify parameter types** before every call. Record vs. VAR Record, Code vs. Text,
  Integer vs. Decimal are NOT interchangeable in AL.
- **For non-Microsoft extension codeunits** in .alpackages: call read_alpackage_symbols()
  twice — first with the codeunit name (all signatures), then with the specific procedure
  name (full implementation, field constraints, cross-record rules).
- **Copy enum and option literals exactly** as they appear in the source —
  spelling, casing, and spacing must match character for character.
- **Never fabricate** table fields, record variables, or setup procedures.
  If a helper is needed and not in context, call rag_search() to find it.
- **Never hardcode numeric literals** (amounts, quantities, percentages, runtime IDs).
  Use LibraryRandom — applies to every test, with or without a recording.
- **Never use a library codeunit** (Library - *, Assert, etc.) that was not confirmed
  to exist in .alpackages via read_alpackage_symbols(). Do not rely on training knowledge.
- **To share values between a test and a handler** (e.g. a record No.),
  declare codeunit-level global variables. Never use "Library Variable Storage" unless
  confirmed in .alpackages — it does not exist in all projects.
- **For TestRequestPage:** only use fields listed under "// RequestPage fields:" in the
  read_alpackage_symbols() output. If the output says "// RequestPage: no fields found",
  do NOT use TestRequestPage — run the report directly.
"""

_SYSTEM_RECORDING_RULES = """

---

## UI Recording rules

A UI recording is provided. It describes the exact sequence of pages, fields, lookups,
and actions a user performed. Treat it as the authoritative specification of the test
scenario and replicate every step as AL test code.

| Recording step | How to translate it |
|----------------|---------------------|
| Input | Set that field on the page or record variable. Use LibraryRandom for numeric fields; LibraryRandom.RandText() or a readable constant for text fields. |
| Lookup (invokeType=Lookup + set-current-row) | Use FindFirst/FindSet or a Library helper to get any valid record — never hardcode the specific record from the recording. |
| Action (invokeType=New, Ok, or named action) | Trigger that action on the relevant page. |
| Final Message step | Assert the outcome using the appropriate AL mechanism (posted entry, status field, etc.). |
"""

_HUMAN = """\
    ## Source code to test
    {source_code}

    ## Reference test (same project)
    {test_example}

    ## Curated test examples (always consult these)
    {examples}

    ## Knowledge base snippets
    {rag_chunks}

    ## Project constraints
    {id_hint}
    {recording_section}

    ## Request
    {question}
"""


# ── Loop de tool calls extra ──────────────────────────────────────────

def _run_extra_tool_calls(messages: list, llm_with_tools, tools_by_name: dict,
                          show_context: bool, label: str = "extra",
                          usage_acc: dict | None = None) -> list:
    """Ejecuta hasta MAX_EXTRA_CALLS rondas de tool calling."""
    for i in range(MAX_EXTRA_CALLS):
        response = llm_with_tools.invoke(messages)
        if usage_acc is not None:
            _accumulate(usage_acc, response)
        messages.append(response)

        if not getattr(response, "tool_calls", None):
            return messages

        for tc in response.tool_calls:
            name    = tc["name"]
            args    = tc["args"]
            tool_fn = tools_by_name.get(name)
            result  = tool_fn.invoke(args) if tool_fn else f"Unknown tool: {name}"

            if show_context:
                print(f"\n  [{label} tool {i+1}] {name}({args})")
                print(f"  → {str(result)[:300]}...")

            messages.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))

    return messages


# ── ALTestAgent ───────────────────────────────────────────────────────

class ALTestAgent:
    def __init__(self, provider: str, model=None,
                 persist_dir: str = DEFAULT_PERSIST,
                 device: str = "cpu", k: int = 6,
                 exclude_files: list[str] | None = None):
        print("[agent] Cargando modelo de embedding y vectorstore...")
        embeddings       = load_embeddings(device=device, model_name=EMBEDDING_MODEL)
        self.vectorstore = load_vectorstore(embeddings, persist_dir=persist_dir)
        self.all_docs    = load_all_docs(self.vectorstore)
        self.config      = ProjectConfig.from_env()
        self.k           = k

        self.exclude_stems: set[str] = (
            {f.lower() for f in exclude_files} if exclude_files else set()
        )

        print(f"[agent] Proyecto  : {self.config.name}")
        print(f"[agent] Chunks    : {len(self.all_docs)}")
        if self.exclude_stems:
            print(f"[agent] Excluidos : {self.exclude_stems}")

        llm   = create_llm(provider=provider, model=model)
        tools = make_tools(self.vectorstore, self.all_docs, self.config, k)

        self.llm_with_tools = llm.bind_tools(tools)
        self.llm_plain      = llm
        self.tools_by_name  = {t.name: t for t in tools}
        self.model_name     = model or {"openai": "gpt-4.1", "claude": "claude-sonnet-4-6"}.get(provider, provider)

    def set_project(self, project_root: str | Path) -> None:
        """Cambia el proyecto activo para esta sesión del agente."""
        self.config = ProjectConfig.from_path(project_root)
        print(f"[agent] Proyecto activo: {self.config.name} ({self.config.project_root})")

    def generate(self, query: str, show_context: bool = False,
                 recording_path: str | Path | None = None,
                 config_override: "ProjectConfig | None" = None) -> str:
        """
        Genera un codeunit AL de tests para la query dada.

        Args:
            query:           Descripción en lenguaje natural del test a generar.
            show_context:    Si True, imprime el contexto base y las tool calls.
            recording_path:  Ruta opcional a un fichero YAML de grabación de BC.
            config_override: ProjectConfig alternativo para esta llamada (no persiste).
        """
        ex     = self.exclude_stems or None
        config = config_override or self.config

        rag_chunks   = _retrieve_rag(query, self.vectorstore, self.all_docs, self.k, ex)
        examples     = _retrieve_examples(query, self.vectorstore, self.all_docs)
        source_code  = _find_source_file(query, config, ex)
        test_example = _find_test_example(query, config, ex)

        id_ranges = config.get_id_ranges()
        if id_ranges:
            ranges_str = ", ".join(f"{r['from']}–{r['to']}" for r in id_ranges)
            id_hint = f"The project's valid object ID ranges are: {ranges_str}. Use a codeunit ID within one of these ranges."
        else:
            id_hint = "No idRanges found in app.json — use a reasonable ID in the 50000–99999 range."

        has_recording = recording_path is not None
        if has_recording:
            rec_path = Path(recording_path)
            recording_text    = _parse_recording(rec_path)
            recording_section = recording_text + "\n"
        else:
            recording_section = ""

        if show_context:
            print(f"\n{'─'*60}\nSOURCE FILE (base)\n{'─'*60}")
            print(source_code[:400])
            print(f"\n{'─'*60}\nTEST EXAMPLE (base)\n{'─'*60}")
            print(test_example[:400])
            print(f"\n{'─'*60}\nRAG CHUNKS (base)\n{'─'*60}")
            print(rag_chunks[:600])
            if recording_section:
                print(f"\n{'─'*60}\nUI RECORDING\n{'─'*60}")
                print(recording_section)

        # System prompt: reglas de grabación solo cuando hay recording
        system_text = _SYSTEM_BASE.format(max_calls=MAX_EXTRA_CALLS)
        if has_recording:
            system_text += _SYSTEM_RECORDING_RULES

        human_content = _HUMAN.format(
            source_code       = source_code,
            test_example      = test_example,
            examples          = examples,
            rag_chunks        = rag_chunks,
            id_hint           = id_hint,
            recording_section = recording_section,
            question          = query,
        )

        messages = [
            SystemMessage(content=[
                {"type": "text", "text": system_text, "cache_control": {"type": "ephemeral"}}
            ]),
            HumanMessage(content=[
                {"type": "text", "text": human_content, "cache_control": {"type": "ephemeral"}}
            ]),
        ]
        usage_acc = {"input_tokens": 0, "output_tokens": 0}
        messages = _run_extra_tool_calls(
            messages, self.llm_with_tools, self.tools_by_name, show_context,
            usage_acc=usage_acc
        )

        messages.append(HumanMessage(content="Generate. Output ONLY AL code."))
        response = self.llm_plain.invoke(messages)
        _accumulate(usage_acc, response)
        code = response.content

        # ── Bucle de autocorrección con alc.exe ───────────────────────
        for attempt in range(1, MAX_FIX_ATTEMPTS + 1):
            errors = compile_al(self.config.project_root, code)
            if not errors:
                break

            error_text = "\n".join(errors)
            if show_context:
                print(f"\n{'─'*60}\nCOMPILATION ERRORS (attempt {attempt})\n{'─'*60}")
                print(error_text)

            # Contexto mínimo: solo source code + código generado + errores.
            # No se incluyen RAG chunks ni test example — no son necesarios para corregir
            # errores de compilación y ahorran miles de tokens por intento.
            fix_messages = [
                messages[0],  # SystemMessage (cacheado)
                HumanMessage(content=(
                    f"## Source code to test\n{source_code}\n\n"
                    f"## Generated code (attempt {attempt})\n{code}\n\n"
                    f"## Compilation errors ({len(errors)})\n{error_text}\n\n"
                    "If you need to verify a procedure or field, use the available tools. "
                    "Then output ONLY the corrected AL code."
                )),
            ]
            fix_messages = _run_extra_tool_calls(
                fix_messages, self.llm_with_tools, self.tools_by_name,
                show_context, label=f"fix{attempt}", usage_acc=usage_acc
            )
            fix_messages.append(HumanMessage(
                content="Output ONLY the corrected AL code — no prose, no markdown fences."
            ))
            response = self.llm_plain.invoke(fix_messages)
            _accumulate(usage_acc, response)
            code = response.content

        # Verificación final: el último código generado nunca ha pasado por compile_al
        errors = compile_al(self.config.project_root, code)
        if errors and show_context:
            print(f"\n{'─'*60}\nFINAL CODE HAS {len(errors)} ERROR(S) — returned as best effort\n{'─'*60}")
            for e in errors:
                print(e)

        _log_usage("generate", self.model_name, usage_acc, config.project_root / "usage_log.jsonl")
        return code
