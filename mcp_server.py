import sys
import logging
from pathlib import Path
from dotenv import load_dotenv

PROJECT_DIR  = Path(__file__).parent
PERSIST_DIR  = str(PROJECT_DIR / "chroma_al_testing")
EXAMPLES_DIR = PROJECT_DIR / "Data" / "TestExamples"

# Cargar variables de entorno y añadir raíz al path
load_dotenv(PROJECT_DIR / ".env")
sys.path.insert(0, str(PROJECT_DIR))

from mcp.server.fastmcp import FastMCP
from src.orchestration.agent import ALTestAgent

logging.basicConfig(stream=sys.stderr, level=logging.INFO)
log = logging.getLogger(__name__)

mcp   = FastMCP("AL Test Generator")
agent = None


def _get_agent() -> ALTestAgent:
    global agent
    if agent is None:
        log.info("Cargando ALTestAgent...")
        agent = ALTestAgent(
            provider    = "claude",
            persist_dir = PERSIST_DIR,
            device      = "cpu",
            k           = 6,
        )
    return agent


# ── Generación de tests ───────────────────────────────────────────────

@mcp.tool()
def generate_al_test(query: str, project_root: str = "") -> str:
    """
    Generate a complete AL test codeunit for a Business Central procedure.
    If project_root is provided it becomes the active project for this session.

    Args:
        query:        Description of what to test, e.g.
                      'Generate tests for PostGuarantee in DTNGARManagement'
        project_root: Absolute path to the AL project root (folder with app.json).
                      If empty, uses the project set by set_active_project or .env.
    """
    a = _get_agent()
    if project_root:
        try:
            a.set_project(project_root)
        except FileNotFoundError as e:
            return str(e)
    return a.generate(query)


@mcp.tool()
def generate_al_test_from_recording(query: str, recording_path: str,
                                    project_root: str = "") -> str:
    """
    Generate an AL test codeunit using a Business Central UI recording (YAML)
    as the authoritative specification of the test scenario.
    If project_root is provided it becomes the active project for this session.

    Args:
        query:          Description of what to test.
        recording_path: Absolute or relative path to the YAML recording file.
        project_root:   Absolute path to the AL project root (folder with app.json).
                        If empty, uses the project set by set_active_project or .env.
    """
    path = Path(recording_path)
    if not path.is_absolute():
        path = PROJECT_DIR / path
    if not path.exists():
        return f"Recording file not found: {path}"

    a = _get_agent()
    if project_root:
        try:
            a.set_project(project_root)
        except FileNotFoundError as e:
            return str(e)
    return a.generate(query, recording_path=path)


# ── Búsqueda en base de conocimiento ─────────────────────────────────

@mcp.tool()
def search_al_knowledge(query: str) -> str:
    """
    Search the AL testing knowledge base (book + curated test examples).
    Does NOT search the current project's source code — use list_al_files
    and read_al_file for that.

    Args:
        query: Natural language search query.
    """
    from src.context.retriever import _retrieve_rag
    a = _get_agent()
    return _retrieve_rag(query, a.vectorstore, a.all_docs, a.k)


# ── Gestión del vectorstore ───────────────────────────────────────────

@mcp.tool()
def refresh_examples(examples_dir: str = "") -> str:
    """
    Incrementally re-index the curated test examples in the knowledge base.
    Use this when files in Data/TestExamples have been added or updated.
    The book knowledge is unaffected.

    Args:
        examples_dir: Path to the test examples directory.
                      Defaults to Data/TestExamples next to this server.
    """
    try:
        from src.context.al_parser import parse_al_file
        from src.context.embedder import load_all_docs

        ex_dir = Path(examples_dir) if examples_dir else EXAMPLES_DIR
        if not ex_dir.exists():
            return f"Examples directory not found: {ex_dir}"

        al_files = sorted(ex_dir.rglob("*.al"))
        if not al_files:
            return f"No .al files found in {ex_dir}"

        new_docs = []
        for f in al_files:
            new_docs.extend(parse_al_file(f, is_test_dir=True))

        a  = _get_agent()
        vs = a.vectorstore

        # Eliminar chunks de ejemplos previos identificados por source_file
        existing = vs.get(include=["metadatas"])
        ex_stems = {f.stem.lower() for f in al_files}
        old_ids  = [
            id_ for id_, meta in zip(existing["ids"], existing["metadatas"])
            if not meta.get("chapter_num")
            and Path(meta.get("source_file", "")).stem.lower() in ex_stems
        ]
        if old_ids:
            vs.delete(ids=old_ids)

        vs.add_documents(new_docs)
        a.all_docs = load_all_docs(vs)

        return (
            f"Examples refreshed: {len(old_ids)} old chunks removed, "
            f"{len(new_docs)} new chunks from {len(al_files)} files added."
        )
    except Exception as e:
        log.exception("refresh_examples failed")
        return f"Error refreshing examples: {e}"


@mcp.tool()
def rebuild_vectorstore(examples_dir: str = "", markdown_path: str = "") -> str:
    """
    Fully rebuild the knowledge base from scratch (book + test examples).
    Use this the first time to initialize the store, or when book_al_testing.md
    has been updated. For everyday example updates use refresh_examples instead.
    The current project's source code is NOT indexed — it is navigated with tools.

    Args:
        examples_dir:  Path to the test examples directory.
                       Defaults to Data/TestExamples next to this server
                       (C:\\Users\\mscarafu\\TFGLaberit\\Data\\TestExamples).
        markdown_path: Absolute path to an alternative Markdown book file.
                       If provided, it replaces book_al_testing.md as the
                       knowledge-base source. Defaults to Data/book_al_testing.md.
    """
    global agent
    try:
        from src.context.al_parser import parse_al_file
        from src.context.embedder import load_embeddings, ingest_documents, EMBEDDING_MODEL
        from src.context.doc_parser import parse_markdown
        from src.context.chunker import sections_to_documents

        ex_dir = Path(examples_dir) if examples_dir else EXAMPLES_DIR

        # 1. Libro de best practices (default o alternativo)
        book_path = Path(markdown_path) if markdown_path else PROJECT_DIR / "Data" / "book_al_testing.md"
        book_docs = []
        if not book_path.exists():
            if markdown_path:
                return f"Markdown file not found: {book_path}"
            log.warning("book_al_testing.md not found, skipping book knowledge.")
        else:
            sections  = parse_markdown(book_path.read_text(encoding="utf-8"))
            book_docs = sections_to_documents(sections)
        log.info("Book: %d chunks from %s", len(book_docs), book_path)

        # 2. Test examples
        example_docs = []
        if ex_dir.exists():
            for f in sorted(ex_dir.rglob("*.al")):
                example_docs.extend(parse_al_file(f, is_test_dir=True))
        log.info("Examples: %d chunks from %s", len(example_docs), ex_dir)

        all_docs = book_docs + example_docs
        if not all_docs:
            return "No documents found. Check that book_al_testing.md and TestExamples exist."

        # Reutilizar el modelo de embedding si el agente ya está en memoria
        if agent is not None:
            embeddings = agent.vectorstore._embedding_function
        else:
            embeddings = load_embeddings(device="cpu", model_name=EMBEDDING_MODEL)

        ingest_documents(all_docs, embeddings, persist_dir=PERSIST_DIR, overwrite=True)

        # Forzar recarga del agente para que use el nuevo vectorstore
        agent = None

        return (
            f"Vectorstore rebuilt: {len(book_docs)} book chunks (from {book_path.name}) + "
            f"{len(example_docs)} example chunks (from {ex_dir.name}). "
            f"Total: {len(all_docs)}."
        )
    except Exception as e:
        log.exception("rebuild_vectorstore failed")
        return f"Error rebuilding vectorstore: {e}"


if __name__ == "__main__":
    mcp.run(transport="stdio")  # stdio: VS Code lanza el proceso directamente
