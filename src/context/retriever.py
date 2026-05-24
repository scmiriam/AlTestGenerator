"""
retriever.py — Recuperación de contexto base para el agente RAG.
Capa de contexto y memoria: búsqueda en vectorstore y localización de ficheros AL.
"""
import re
from pathlib import Path

from src.context.embedder import get_retriever_for_query, build_hybrid_retriever
from src.execution.project_config import ProjectConfig

# ── Límites de contexto ───────────────────────────────────────────────

RAG_CHUNK_PREVIEW  = 400
SOURCE_FILE_LIMIT  = 4_000
TEST_EXAMPLE_LIMIT = 3_000


# ── Helpers de lectura de ficheros AL ────────────────────────────────

def _cut_at_procedure(content: str, limit: int) -> str:
    """Corta el contenido antes del límite intentando respetar el final de un procedimiento."""
    window = content[:limit]
    for prefix in ("\n    procedure ", "\n    local procedure ", "\nprocedure "):
        cut = window.rfind(prefix)
        if cut > limit // 2:
            return content[:cut] + f"\n\n// ... [truncated at procedure boundary — {len(content)} chars total]"
    return window + f"\n// ... [truncated — {len(content)} chars total]"


def _read_truncated(path: Path, limit: int) -> str:
    content = path.read_text(encoding="utf-8", errors="replace")
    if len(content) <= limit:
        return f"// {path.name}\n\n{content}"
    return f"// {path.name}\n\n{_cut_at_procedure(content, limit)}"


def _common_prefix_len(a: str, b: str) -> int:
    for i, (x, y) in enumerate(zip(a, b)):
        if x != y:
            return i
    return min(len(a), len(b))


# ── Recuperación desde vectorstore ────────────────────────────────────

def _retrieve_rag(query: str, vectorstore, all_docs: list, k: int,
                  exclude_stems: set[str] | None = None) -> str:
    retriever = get_retriever_for_query(vectorstore, all_docs, k)
    docs      = retriever.invoke(query)

    # Dedup: máximo 2 chunks por fichero fuente para evitar contexto repetido
    seen: dict[str, int] = {}
    deduped = []
    for doc in docs:
        src = doc.metadata.get("source_file", "__book__")
        if exclude_stems and src != "__book__":
            if Path(src).stem.lower() in exclude_stems:
                continue
        if seen.get(src, 0) < 2:
            deduped.append(doc)
            seen[src] = seen.get(src, 0) + 1

    parts = []
    for doc in deduped:
        meta = doc.metadata
        if "chapter_num" in meta:
            header = f"[book | ch{meta['chapter_num']} — {meta['section_title']}]"
        else:
            proc   = meta.get("procedure_name") or "header"
            header = (f"[{meta.get('content_type')} | {meta.get('object_type')} "
                      f"{meta.get('object_name')} → {proc}]")
        parts.append(f"{header}\n{doc.page_content[:RAG_CHUNK_PREVIEW]}")
    return "\n\n---\n\n".join(parts) if parts else "No results found."


def _retrieve_examples(query: str, vectorstore, all_docs: list, k: int = 3) -> str:
    """Recupera chunks de test examples (company_example) relevantes para la query."""
    retriever = build_hybrid_retriever(
        vectorstore         = vectorstore,
        all_docs            = all_docs,
        k                   = k,
        content_type_filter = "company_example",
    )
    docs = retriever.invoke(query)
    if not docs:
        return "No test examples found."

    seen: dict[str, int] = {}
    parts = []
    for doc in docs:
        src = doc.metadata.get("source_file", "unknown")
        if seen.get(src, 0) >= 2:
            continue
        seen[src] = seen.get(src, 0) + 1
        proc   = doc.metadata.get("procedure_name") or "header"
        header = (f"[example | {doc.metadata.get('object_name')} → {proc} "
                  f"| {src}]")
        parts.append(f"{header}\n{doc.page_content[:RAG_CHUNK_PREVIEW]}")
    return "\n\n---\n\n".join(parts) if parts else "No test examples found."


# ── Localización de ficheros en el proyecto AL ────────────────────────

def _find_source_file(query: str, config: ProjectConfig,
                      exclude_stems: set[str] | None = None) -> str:
    tokens   = re.findall(r'[A-Za-z][A-Za-z0-9]+', query)
    al_files = [f for f in config.all_al_files()
                if not config.is_test_file(f)
                and (not exclude_stems or f.stem.lower() not in exclude_stems)]

    for token in tokens:
        for f in al_files:
            if f.stem.lower() == token.lower():
                return _read_truncated(f, SOURCE_FILE_LIMIT)

    for token in sorted(tokens, key=len, reverse=True):
        for f in al_files:
            if token.lower() in f.stem.lower():
                return _read_truncated(f, SOURCE_FILE_LIMIT)

    return "// Source file not found — use list_al_files() and read_al_file() to locate it."


def _find_test_example(query: str, config: ProjectConfig,
                       exclude_stems: set[str] | None = None) -> str:
    tokens     = re.findall(r'[A-Za-z][A-Za-z0-9]+', query)
    test_files = [f for f in config.all_al_files()
                  if config.is_test_file(f) and "library" not in f.stem.lower()
                  and (not exclude_stems or f.stem.lower() not in exclude_stems)]

    if not test_files:
        return "// No test example found."

    src_files = [f for f in config.all_al_files()
                 if not config.is_test_file(f)
                 and (not exclude_stems or f.stem.lower() not in exclude_stems)]
    src_stem = None
    for token in sorted(tokens, key=len, reverse=True):
        match = next((f for f in src_files if token.lower() in f.stem.lower()), None)
        if match:
            src_stem = match.stem.lower()
            break

    if src_stem:
        best = max(test_files,
                   key=lambda f: _common_prefix_len(src_stem, f.stem.lower()))
        if _common_prefix_len(src_stem, best.stem.lower()) >= 4:
            return _read_truncated(best, TEST_EXAMPLE_LIMIT)

    for token in sorted(tokens, key=len, reverse=True):
        for f in test_files:
            if token.lower() in f.stem.lower():
                return _read_truncated(f, TEST_EXAMPLE_LIMIT)

    return _read_truncated(test_files[0], TEST_EXAMPLE_LIMIT)
