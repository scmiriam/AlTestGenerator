"""
al_tools.py — Tools de LangChain que el LLM puede invocar durante la generación.
Inicializa el estado global con init_tools() antes de usar el agente.
"""
from langchain_core.tools import tool

from src.embedder import get_retriever_for_query

# ── Estado global inyectado por init_tools() ─────────────────────────

_tool_vectorstore = None
_tool_all_docs    = []
_tool_config      = None
_tool_k           = 8


def init_tools(vs, docs: list, cfg, k: int = 8) -> None:
    """Inyecta el vectorstore, documentos y configuración en las tools."""
    global _tool_vectorstore, _tool_all_docs, _tool_config, _tool_k
    _tool_vectorstore = vs
    _tool_all_docs    = docs
    _tool_config      = cfg
    _tool_k           = k


# ── Definición de las tools ───────────────────────────────────────────

@tool
def rag_search(query: str) -> str:
    """
    Search the knowledge base for AL testing best practices, real company
    test examples, and application source code relevant to the query.
    Use this tool first to get an overview of how similar things are tested.

    Args:
        query: Natural language description of what you are looking for.
    """
    retriever = get_retriever_for_query(
        vectorstore = _tool_vectorstore,
        all_docs    = _tool_all_docs,
        k           = _tool_k,
    )
    docs = retriever.invoke(query)
    if not docs:
        return "No relevant results found."

    parts = []
    for doc in docs:
        meta = doc.metadata
        ct   = meta.get("content_type", "?")
        if "chapter_num" in meta:
            header = f"[book | {ct} | ch{meta['chapter_num']} \u2014 {meta['section_title']}]"
        else:
            proc   = meta.get("procedure_name") or "header"
            header = (f"[{ct} | {meta.get('object_type')} {meta.get('object_name')} "
                      f"\u2192 {proc} | {meta.get('source_file')}]")
        parts.append(f"{header}\n{doc.page_content[:800]}")

    return "\n\n---\n\n".join(parts)


@tool
def list_al_files(filter: str = "") -> str:
    """
    List all AL files in the current project (source code and tests).
    Optionally filter by a keyword that must appear in the filename.

    Args:
        filter: Optional keyword to filter filenames (case-insensitive).
    """
    if _tool_config is None:
        return "Project not configured."

    files = _tool_config.all_al_files()
    if filter:
        files = [f for f in files if filter.lower() in f.name.lower()]

    if not files:
        return f"No AL files found" + (f" matching '{filter}'." if filter else ".")

    lines = []
    for f in files:
        kind = "test" if _tool_config.is_test_file(f) else "src"
        lines.append(f"[{kind}] {f.name}  \u2192  {f}")

    return "\n".join(lines)


@tool
def read_al_file(filename: str) -> str:
    """
    Read the full content of an AL file from the current project.
    Use this tool when you need to inspect the exact code of a table,
    codeunit, page, or test file before generating a new test.

    Args:
        filename: Name of the AL file (with or without .al extension).
    """
    if _tool_config is None:
        return "Project not configured."

    path = _tool_config.find_file(filename)
    if path is None:
        all_files = _tool_config.all_al_files()
        matches   = [f for f in all_files if filename.lower() in f.name.lower()]
        if not matches:
            return (f"File '{filename}' not found. "
                    f"Use list_al_files() to see available files.")
        if len(matches) > 1:
            names = ", ".join(f.name for f in matches)
            return f"Multiple files match '{filename}': {names}. Be more specific."
        path = matches[0]

    MAX_CHARS = 6_000
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
        kind    = "test" if _tool_config.is_test_file(path) else "src"
        header  = f"// [{kind}] {path.name}\n\n"
        if len(content) > MAX_CHARS:
            content = content[:MAX_CHARS] + f"\n\n// ... [truncated — {len(content)} chars total]"
        return header + content
    except OSError as e:
        return f"Error reading file: {e}"


AL_TOOLS = [rag_search, list_al_files, read_al_file]
