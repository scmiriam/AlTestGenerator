"""
chunker.py — Convierte secciones del libro en Documents de LangChain.
Respeta la sintaxis AL (procedure, begin, end) para no cortar código a medias.
"""
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter

# ── Configuración ─────────────────────────────────────────────────────

# Separadores en orden de preferencia — respetan la sintaxis de AL
AL_SEPARATORS = [
    "\nprocedure ",
    "\nlocal procedure ",
    "\ntrigger ",
    "\nbegin\n",
    "\nend;\n",
    "\nend.\n",
    "\n\n",
    "\n",
    " ",
]

CHUNK_SIZE    = 2_400   # caracteres (~600-700 tokens para BGE-M3)
CHUNK_OVERLAP = 240     # ~10% — suficiente para no perder contexto entre chunks

_splitter = RecursiveCharacterTextSplitter(
    chunk_size       = CHUNK_SIZE,
    chunk_overlap    = CHUNK_OVERLAP,
    separators       = AL_SEPARATORS,
    length_function  = len,
    is_separator_regex=False,
)


# ── Conversión Section → Documents ────────────────────────────────────

def section_to_documents(section) -> list:
    """
    Convierte una Section en uno o varios Documents con metadata enriquecida.
    El prefijo jerárquico se antepone a cada chunk para que el LLM siempre
    sepa de qué capítulo/sección proviene el contexto recuperado.
    """
    if not section.content.strip():
        return []

    header = (
        f"# Chapter {section.chapter_num}: {section.chapter_title}\n"
        f"## Section: {section.section_title}\n"
        f"Pages: {section.page_range}\n"
        "---\n"
    )

    full_text  = header + section.content
    raw_chunks = _splitter.split_text(full_text)

    docs = []
    for idx, chunk in enumerate(raw_chunks):
        docs.append(Document(
            page_content=chunk,
            metadata={
                "chunk_id":      f"{section.chunk_id}__{idx}",
                "chunk_index":   idx,
                "chunk_total":   len(raw_chunks),
                "chapter_num":   section.chapter_num,
                "chapter_title": section.chapter_title,
                "section_title": section.section_title,
                "content_type":  section.content_type,
                "page_start":    min(section.pages) if section.pages else 0,
                "page_end":      max(section.pages) if section.pages else 0,
            },
        ))

    return docs


def sections_to_documents(sections: list) -> list:
    """Convierte una lista de Section en todos sus Documents."""
    all_docs = []
    for section in sections:
        all_docs.extend(section_to_documents(section))
    return all_docs
