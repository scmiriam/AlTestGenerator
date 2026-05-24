"""
doc_parser.py — Parsea el libro de testing AL (Markdown) en secciones tipadas.
"""
import re
from dataclasses import dataclass, field


# ── Modelos de datos ──────────────────────────────────────────────────

@dataclass
class Section:
    chapter_num: int
    chapter_title: str
    section_title: str
    content_type: str          # test_example | concept | summary | reference
    pages: list = field(default_factory=list)
    content: str = ""

    @property
    def chunk_id(self) -> str:
        safe_section = re.sub(r"[^a-z0-9]+", "_", self.section_title.lower()).strip("_")
        return f"ch{self.chapter_num}_{safe_section}"

    @property
    def page_range(self) -> str:
        if not self.pages:
            return "?"
        return f"{min(self.pages)}\u2013{max(self.pages)}"

    def __repr__(self) -> str:
        return (
            f"Section(ch={self.chapter_num}, "
            f"type={self.content_type!r}, "
            f"pages={self.page_range}, "
            f"title={self.section_title!r})"
        )


# ── Helpers de clasificación ──────────────────────────────────────────

_CONTENT_TYPE_RULES = [
    ("test example",    "test_example"),
    ("summary",         "summary"),
    ("further reading", "reference"),
    ("introduction",    "concept"),
    ("framework",       "concept"),
]

def _detect_content_type(section_title: str) -> str:
    lower = section_title.lower()
    for keyword, ctype in _CONTENT_TYPE_RULES:
        if keyword in lower:
            return ctype
    return "concept"


# Patrones de headers Markdown
_CHAPTER_RE = re.compile(r"^# (\d+)\s+(.+)$")
_SECTION_RE = re.compile(r"^## (.+?) - Page: (\d+)$")


# ── Parser principal ──────────────────────────────────────────────────

def parse_markdown(md_text: str) -> list:
    """
    Recorre el markdown línea a línea y agrupa el contenido por sección.
    Devuelve una lista de Section ordenadas por aparición en el documento.
    """
    sections = []
    current_chapter_num   = 0
    current_chapter_title = ""
    current_section       = None

    for raw_line in md_text.splitlines():
        line = raw_line.strip()

        ch_match = _CHAPTER_RE.match(line)
        if ch_match:
            current_chapter_num   = int(ch_match.group(1))
            current_chapter_title = ch_match.group(2).strip()
            continue

        sec_match = _SECTION_RE.match(line)
        if sec_match:
            sec_title = sec_match.group(1).strip()
            page_num  = int(sec_match.group(2))

            if current_section and current_section.section_title == sec_title:
                current_section.pages.append(page_num)
            else:
                if current_section:
                    sections.append(current_section)
                current_section = Section(
                    chapter_num   = current_chapter_num,
                    chapter_title = current_chapter_title,
                    section_title = sec_title,
                    content_type  = _detect_content_type(sec_title),
                    pages         = [page_num],
                )
        else:
            if current_section and line:
                current_section.content += raw_line + "\n"

    if current_section:
        sections.append(current_section)

    return sections
