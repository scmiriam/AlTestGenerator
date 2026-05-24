# AL Test Generator — Copilot Instructions

This workspace uses a custom MCP server to generate AL test codeunits for
Microsoft Dynamics 365 Business Central. Copilot must never generate AL test
code itself — all generation is delegated to the MCP agent.

## Available MCP tools

| Tool | Purpose |
|------|---------|
| `generate_al_test` | Generate a new AL test codeunit from a natural-language description |
| `generate_al_test_from_recording` | Generate a test codeunit driven by a Business Central UI recording (YAML) |
| `search_al_knowledge` | Search the knowledge base (book + curated test examples). Does NOT search project source code |
| `refresh_examples` | Incrementally re-index the curated test examples in Data/TestExamples |
| `rebuild_vectorstore` | Full rebuild from scratch — book + test examples only; use for first-time setup or when the book changes |

## Workflow

Read the decision tree top to bottom and follow the first matching case.

---

### Case 1 — Generate a new test codeunit (default)

**Step 1 — Prepend visible context to the query (no file reads)**

Before calling the tool, prepend any context directly visible in the editor:
- If the user has a procedure or block **selected**, include its name and the
  object it belongs to (e.g. `"selected: procedure PostGuarantee in codeunit DTNGARManagement"`).
- If the **active file** is clearly the object to be tested, include its object
  type, ID, and name (e.g. `"active file: codeunit 70800 \"DTNGAR Management\""`).
- If the user has **attached a project file** to the chat, include its path in
  the query (e.g. `"attached file: C:\path\to\MyObject.al"`).

Do not read file contents, do not look up signatures, do not add anything else.
The agent discovers everything else on its own.

**Step 2 — Call the MCP tool**

- With a `.yml` recording → `generate_al_test_from_recording(query, recording_path)`
- Otherwise → `generate_al_test(query)`

**Step 3 — Write the file**

- Derive the filename from the codeunit name
  (e.g. `codeunit 50201 "DTNGARBondTests"` → `DTNGARBondTests.Codeunit.al`).
- Locate the tests directory (look for `src/Tests`, `Tests`, or `test` next to `app.json`).
- Write the file there. Do not show the code in chat. Do not modify the agent's output.
- Confirm the filename, full path, and validated codeunit ID to the user.

---

### Case 2 — Add a test to an existing codeunit (only when explicitly requested)

1. Read the target codeunit file in full.
2. Build an enriched query that includes the codeunit content, so the agent
   knows its ID, existing procedures, variable declarations, and helper methods.
   End the query with:
   `"Output only the new [Test] procedure(s) to insert, no codeunit wrapper."`

   Example:
   > "Add a single [Test] procedure to the existing codeunit below. The test
   > should cover the cancellation path of PostGuarantee in DTNGARManagement:
   > guarantee status is Closed, expect an error. Output only the new [Test]
   > procedure(s) to insert, no codeunit wrapper.
   >
   > Existing codeunit:
   > \`\`\`al
   > codeunit 50200 DTNGARBondTests
   > ...
   > \`\`\`"

3. Call `generate_al_test(query)` with the enriched query.
4. Insert the returned procedure(s) before the last closing `}` of the file.
5. If the output contains a `// NOTE FOR Initialize():` comment block:
   - Add the listed `DeleteAll(true)` calls at the top of `Initialize()`.
   - If `Initialize()` does not exist, create it with those calls before any other setup.
   - Remove the comment block before saving.
6. Save the file and confirm the insertion to the user.

---

## Rules

- Never generate AL test code directly. All generation is done by the MCP agent.
- Never invent AL identifiers. If context is unclear, build the best query possible and let the agent resolve it.
- The active project is set automatically from `${workspaceFolder}` — do not pass
  `project_root` to generation tools unless the user explicitly switches projects.
- To update indexed examples, call `refresh_examples()`.
- To fully rebuild the knowledge base, call `rebuild_vectorstore()`.
- Project source code is NOT in the knowledge base — the agent navigates it directly with tools.
