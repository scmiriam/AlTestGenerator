"""
agent.py — ALTestAgent: agente RAG híbrido para generar tests AL de Business Central.

Arquitectura:
  1. Contexto base (Python): RAG + fichero fuente + test de referencia
  2. Tool calls extra (LLM): hasta MAX_EXTRA_CALLS rondas adicionales
  3. Generación final (LLM): codeunit AL completo
"""
import re
import textwrap
from pathlib import Path

from langchain.schema import Document
from langchain_core.messages import HumanMessage, SystemMessage, ToolMessage

from src.embedder import (
    DEFAULT_PERSIST,
    EMBEDDING_MODEL,
    get_retriever_for_query,
    load_all_docs,
    load_embeddings,
    load_vectorstore,
)
from src.llm_factory import create_llm
from src.al_tools import AL_TOOLS, init_tools
from src.project_config import ProjectConfig

# ── Constantes de truncado ────────────────────────────────────────────

RAG_CHUNK_PREVIEW  = 600
SOURCE_FILE_LIMIT  = 4_000
TEST_EXAMPLE_LIMIT = 3_000
MAX_EXTRA_CALLS    = 2


# ── Helpers de retrieval base ─────────────────────────────────────────

def _read_truncated(path: Path, limit: int) -> str:
    content   = path.read_text(encoding="utf-8", errors="replace")
    truncated = content[:limit]
    if len(content) > limit:
        truncated += f"\n// ... [truncated — {len(content)} chars total]"
    return f"// {path.name}\n\n{truncated}"


def _retrieve_rag(query: str, vectorstore, all_docs: list, k: int) -> str:
    retriever = get_retriever_for_query(vectorstore, all_docs, k)
    docs      = retriever.invoke(query)
    parts     = []
    for doc in docs:
        meta = doc.metadata
        if "chapter_num" in meta:
            header = f"[book | ch{meta['chapter_num']} \u2014 {meta['section_title']}]"
        else:
            proc   = meta.get("procedure_name") or "header"
            header = (f"[{meta.get('content_type')} | {meta.get('object_type')} "
                      f"{meta.get('object_name')} \u2192 {proc}]")
        parts.append(f"{header}\n{doc.page_content[:RAG_CHUNK_PREVIEW]}")
    return "\n\n---\n\n".join(parts) if parts else "No results found."


def _find_source_file(query: str, config: ProjectConfig) -> str:
    tokens   = re.findall(r'[A-Za-z][A-Za-z0-9]+', query)
    al_files = [f for f in config.all_al_files() if not config.is_test_file(f)]

    for token in tokens:
        for f in al_files:
            if f.stem.lower() == token.lower():
                return _read_truncated(f, SOURCE_FILE_LIMIT)

    for token in sorted(tokens, key=len, reverse=True):
        for f in al_files:
            if token.lower() in f.stem.lower():
                return _read_truncated(f, SOURCE_FILE_LIMIT)

    return "// Source file not found — use a tool to read the file if needed."


def _find_test_example(query: str, config: ProjectConfig) -> str:
    tokens     = re.findall(r'[A-Za-z][A-Za-z0-9]+', query)
    test_files = [f for f in config.all_al_files()
                  if config.is_test_file(f) and "library" not in f.stem.lower()]

    for token in sorted(tokens, key=len, reverse=True):
        for f in test_files:
            if token.lower() in f.stem.lower():
                return _read_truncated(f, TEST_EXAMPLE_LIMIT)

    if test_files:
        return _read_truncated(test_files[0], TEST_EXAMPLE_LIMIT)

    return "// No test example found."


# ── Prompts ───────────────────────────────────────────────────────────

_SYSTEM = textwrap.dedent("""\
    You are an expert in writing automated tests for Microsoft Dynamics 365 \
    Business Central using Application Language (AL).

    You will receive a base context (source code, reference test, RAG snippets).
    If you need additional information, you may call the available tools \
    (at most 2 times). Then generate the complete test codeunit.

    Rules:
    1. Produce a complete, compilable AL codeunit with Subtype = Test.
    2. Each test procedure must have the [Test] attribute.
    3. Use Assert or LibraryAssert for all assertions.
    4. Follow GIVEN / WHEN / THEN comment structure inside each test.
    5. Use helper procedures (Initialize, Create*, Verify*) to keep tests readable.
    6. Reuse the library codeunit from the reference test if it exists.
    7. Output ONLY AL code — no prose, no markdown fences.
""")

_HUMAN = textwrap.dedent("""\
    ## Source code to test
    {source_code}

    ## Reference test (same project)
    {test_example}

    ## Knowledge base snippets
    {rag_chunks}

    ## Request
    {question}
""")


# ── Loop de tool calls extra ──────────────────────────────────────────

def _run_extra_tool_calls(messages: list, llm_with_tools, tools_by_name: dict,
                          show_context: bool) -> list:
    """Ejecuta hasta MAX_EXTRA_CALLS rondas de tool calling."""
    for i in range(MAX_EXTRA_CALLS):
        response = llm_with_tools.invoke(messages)
        messages.append(response)

        if not getattr(response, "tool_calls", None):
            return messages

        for tc in response.tool_calls:
            name    = tc["name"]
            args    = tc["args"]
            tool_fn = tools_by_name.get(name)
            result  = tool_fn.invoke(args) if tool_fn else f"Unknown tool: {name}"

            if show_context:
                print(f"\n  [extra tool {i+1}] {name}({args})")
                print(f"  \u2192 {str(result)[:300]}...")

            messages.append(ToolMessage(content=str(result), tool_call_id=tc["id"]))

    return messages


# ── ALTestAgent ───────────────────────────────────────────────────────

class ALTestAgent:
    def __init__(self, provider: str, model=None,
                 persist_dir: str = DEFAULT_PERSIST,
                 device: str = "cpu", k: int = 6):
        print("[agent] Cargando modelo de embedding y vectorstore...")
        embeddings       = load_embeddings(device=device, model_name=EMBEDDING_MODEL)
        self.vectorstore = load_vectorstore(embeddings, persist_dir=persist_dir)
        self.all_docs    = load_all_docs(self.vectorstore)
        self.config      = ProjectConfig.from_env()
        self.k           = k

        print(f"[agent] Proyecto  : {self.config.name}")
        print(f"[agent] Chunks    : {len(self.all_docs)}")

        llm = create_llm(provider=provider, model=model)
        init_tools(self.vectorstore, self.all_docs, self.config, k)

        self.llm_with_tools = llm.bind_tools(AL_TOOLS)
        self.llm_plain      = llm
        self.tools_by_name  = {t.name: t for t in AL_TOOLS}

    def generate(self, query: str, show_context: bool = False) -> str:
        """
        Genera un codeunit AL de tests para la query dada.

        Args:
            query:        Descripción en lenguaje natural del test a generar.
            show_context: Si True, imprime el contexto base y las tool calls.
        """
        rag_chunks   = _retrieve_rag(query, self.vectorstore, self.all_docs, self.k)
        source_code  = _find_source_file(query, self.config)
        test_example = _find_test_example(query, self.config)

        if show_context:
            print(f"\n{'─'*60}\nSOURCE FILE (base)\n{'─'*60}")
            print(source_code[:400])
            print(f"\n{'─'*60}\nTEST EXAMPLE (base)\n{'─'*60}")
            print(test_example[:400])
            print(f"\n{'─'*60}\nRAG CHUNKS (base)\n{'─'*60}")
            print(rag_chunks[:600])

        human_content = _HUMAN.format(
            source_code  = source_code,
            test_example = test_example,
            rag_chunks   = rag_chunks,
            question     = query,
        )

        messages = [
            SystemMessage(content=_SYSTEM),
            HumanMessage(content=human_content),
        ]
        messages = _run_extra_tool_calls(
            messages, self.llm_with_tools, self.tools_by_name, show_context
        )

        messages.append(HumanMessage(
            content="Now generate the complete AL test codeunit. Output ONLY AL code."
        ))
        response = self.llm_plain.invoke(messages)
        return response.content
