"""
al_parser.py — Parsea ficheros .al de Business Central y genera Documents por procedimiento.
Cada fichero queda clasificado como 'app_code' o 'company_example' según su carpeta.
"""
import re
from pathlib import Path

from langchain.schema import Document
from langchain.text_splitter import RecursiveCharacterTextSplitter

# ── Configuración ─────────────────────────────────────────────────────

AL_CHUNK_SIZE    = 2_400
AL_CHUNK_OVERLAP = 240

_FALLBACK_SPLITTER = RecursiveCharacterTextSplitter(
    chunk_size         = AL_CHUNK_SIZE,
    chunk_overlap      = AL_CHUNK_OVERLAP,
    separators         = ["\nbegin\n", "\nend;\n", "\n\n", "\n", " "],
    length_function    = len,
    is_separator_regex = False,
)


# ── Expresiones regulares ─────────────────────────────────────────────

_OBJECT_RE = re.compile(
    r'^\s*(?P<obj_type>codeunit|table|page|report|xmlport|query|enum|interface|'
    r'tableextension|pageextension|reportextension|enumextension|'
    r'permissionset|permissionsetextension|profile|controladdin)\s+'
    r'(?P<obj_id>\d+)\s+'
    r'(?:"(?P<name_q>[^"]+)"|(?P<name_u>[A-Za-z_][A-Za-z0-9_ ]*))',
    re.IGNORECASE | re.MULTILINE,
)

_PROC_RE = re.compile(
    r'^[ \t]{0,12}'
    r'(?:local\s+|internal\s+|protected\s+)?'
    r'(?P<kind>procedure|trigger)\s+'
    r'(?:"(?P<name_q>[^"]+)"|(?P<name_u>[A-Za-z_][A-Za-z0-9_]*))',
    re.IGNORECASE | re.MULTILINE,
)

_SUBTYPE_TEST_RE = re.compile(r'Subtype\s*=\s*Test\s*;', re.IGNORECASE)
_TEST_ATTR_RE    = re.compile(r'\[Test\]',                re.IGNORECASE)


# ── Lógica principal ──────────────────────────────────────────────────

def _al_prefix(object_type: str, object_id: int, object_name: str,
               proc_name) -> str:
    """Cabecera contextual prepuesta a cada chunk."""
    line = f"// [{object_type} {object_id}] {object_name}"
    if proc_name:
        line += f" \u2192 {proc_name}"
    return line + "\n"


def parse_al_file(filepath: Path, is_test_dir: bool) -> list:
    """
    Parsea un único fichero .al y devuelve sus Documents.

    Args:
        filepath:    Ruta absoluta al fichero .al.
        is_test_dir: True si la carpeta está clasificada como tests.
    """
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []

    obj_match = _OBJECT_RE.search(text)
    if not obj_match:
        return []

    object_type  = obj_match.group("obj_type").lower()
    object_id    = int(obj_match.group("obj_id"))
    object_name  = (obj_match.group("name_q") or obj_match.group("name_u") or "").strip()

    is_test_object = bool(_SUBTYPE_TEST_RE.search(text))
    content_type   = "company_example" if (is_test_dir or is_test_object) else "app_code"
    source_file    = filepath.name

    proc_matches = list(_PROC_RE.finditer(text))
    sections_al  = []  # (proc_name, is_test_proc, raw_text)

    if not proc_matches:
        sections_al.append((None, False, text))
    else:
        header_raw = text[:proc_matches[0].start()].rstrip()
        if header_raw.strip():
            sections_al.append((None, False, header_raw))

        for idx, m in enumerate(proc_matches):
            end      = proc_matches[idx + 1].start() if idx + 1 < len(proc_matches) else len(text)
            proc_raw = text[m.start():end].rstrip()

            proc_name = (m.group("name_q") or m.group("name_u") or "Unknown").strip()

            before       = text[max(0, m.start() - 200): m.start()]
            is_test_proc = bool(_TEST_ATTR_RE.search(before))

            sections_al.append((proc_name, is_test_proc, proc_raw))

    docs = []
    for proc_name, is_test_proc, raw in sections_al:
        full_text = _al_prefix(object_type, object_id, object_name, proc_name) + raw

        if len(full_text) > AL_CHUNK_SIZE + 200:
            sub_chunks = _FALLBACK_SPLITTER.split_text(full_text)
        else:
            sub_chunks = [full_text]

        for sub_idx, chunk_text in enumerate(sub_chunks):
            safe_obj  = re.sub(r"[^a-z0-9]+", "_", object_name.lower()).strip("_")
            safe_proc = re.sub(r"[^a-z0-9]+", "_", (proc_name or "header").lower()).strip("_")
            chunk_id  = f"{object_type}_{safe_obj}__{safe_proc}__{sub_idx}"

            docs.append(Document(
                page_content=chunk_text,
                metadata={
                    "chunk_id":          chunk_id,
                    "chunk_index":       sub_idx,
                    "chunk_total":       len(sub_chunks),
                    "content_type":      content_type,
                    "object_type":       object_type,
                    "object_id":         object_id,
                    "object_name":       object_name,
                    "procedure_name":    proc_name or "",
                    "is_test_object":    is_test_object,
                    "is_test_procedure": is_test_proc,
                    "source_file":       source_file,
                },
            ))

    return docs


def parse_al_directory(src_dirs: list, test_dirs: list) -> list:
    """
    Escanea directorios de fuentes y de tests y parsea todos los .al.

    Args:
        src_dirs:  Directorios con código de la app  (content_type = 'app_code').
        test_dirs: Directorios con tests             (content_type = 'company_example').
    """
    all_docs = []

    for directory in src_dirs:
        for filepath in sorted(Path(directory).rglob("*.al")):
            all_docs.extend(parse_al_file(filepath, is_test_dir=False))

    for directory in test_dirs:
        for filepath in sorted(Path(directory).rglob("*.al")):
            all_docs.extend(parse_al_file(filepath, is_test_dir=True))

    return all_docs
