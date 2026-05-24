"""
al_tools.py — Tools de LangChain que el LLM puede invocar durante la generación.
Usa make_tools() para obtener una lista de tools ligadas a un estado concreto.
"""
from pathlib import Path

from langchain_core.tools import tool

from src.context.embedder import get_retriever_for_query


def make_tools(vectorstore, all_docs: list, config, k: int = 8) -> list:
    """Crea tools LangChain ligadas al vectorstore, docs y config dados (sin globals)."""

    @tool
    def rag_search(query: str) -> str:
        """
        Search the knowledge base for AL testing best practices and reference
        test examples. The knowledge base contains the AL testing book and
        curated test examples — NOT the current project's source code.
        To read project files use list_al_files() and read_al_file() instead.

        Args:
            query: Natural language description of what you are looking for.
        """
        retriever = get_retriever_for_query(vectorstore=vectorstore, all_docs=all_docs, k=k)
        docs = retriever.invoke(query)
        if not docs:
            return "No relevant results found."

        parts = []
        for doc in docs:
            meta = doc.metadata
            ct   = meta.get("content_type", "?")
            if "chapter_num" in meta:
                header = f"[book | {ct} | ch{meta['chapter_num']} — {meta['section_title']}]"
            else:
                proc   = meta.get("procedure_name") or "header"
                header = (f"[{ct} | {meta.get('object_type')} {meta.get('object_name')} "
                          f"→ {proc} | {meta.get('source_file')}]")
            parts.append(f"{header}\n{doc.page_content[:400]}")

        return "\n\n---\n\n".join(parts)

    @tool
    def list_al_files(filter: str = "") -> str:
        """
        List all AL files in the current project (source code and tests).
        Optionally filter by a keyword that must appear in the filename.

        Args:
            filter: Optional keyword to filter filenames (case-insensitive).
        """
        files = config.all_al_files()
        if filter:
            files = [f for f in files if filter.lower() in f.name.lower()]

        if not files:
            return f"No AL files found" + (f" matching '{filter}'." if filter else ".")

        lines = []
        for f in files:
            kind = "test" if config.is_test_file(f) else "src"
            lines.append(f"[{kind}] {f.name}  →  {f}")

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
        path = config.find_file(filename)
        if path is None:
            all_files = config.all_al_files()
            matches   = [f for f in all_files if filename.lower() in f.name.lower()]
            if not matches:
                return (
                    f"File '{filename}' not found in project source. "
                    f"If this object belongs to a BC standard library or another extension "
                    f"it resides in .alpackages (binary, unreadable). "
                    f"In that case do NOT invent field or procedure names — "
                    f"use only identifiers explicitly visible in the provided source code or reference tests."
                )
            if len(matches) > 1:
                names = ", ".join(f.name for f in matches)
                return f"Multiple files match '{filename}': {names}. Be more specific."
            path = matches[0]

        MAX_CHARS = 6_000
        try:
            content = path.read_text(encoding="utf-8", errors="replace")
            kind    = "test" if config.is_test_file(path) else "src"
            header  = f"// [{kind}] {path.name}\n\n"
            if len(content) > MAX_CHARS:
                content = content[:MAX_CHARS] + f"\n\n// ... [truncated — {len(content)} chars total]"
            return header + content
        except OSError as e:
            return f"Error reading file: {e}"

    @tool
    def read_alpackage_symbols(object_name: str) -> str:
        """
        Look up fields and procedure signatures of an AL object from .alpackages.
        Use this when read_al_file() cannot find an object because it belongs
        to a dependency (standard BC, another extension, or a library package).
        Returns field names + types and procedure signatures — enough to write
        correct calls without inventing identifiers.

        Args:
            object_name: Name or partial name of the AL object OR procedure to find.
                         For non-Microsoft extensions this tool also searches by
                         procedure name — call it first with the codeunit name to get
                         all procedure signatures, then with the procedure name to read
                         its full body (e.g. first "DTNGAR Management", then
                         "GenerateGuaranteeTransaction").
        """
        import zipfile, json

        alpackages = config.project_root / ".alpackages"
        if not alpackages.exists():
            return f".alpackages not found at {alpackages}"

        app_files = sorted(alpackages.glob("*.app"))
        if not app_files:
            return "No .app files found in .alpackages."

        name_lower   = object_name.lower()
        results      = []
        _MAX_RESULTS = 3
        _MAX_FIELDS  = 40
        _MAX_METHODS = 30

        def _summarise_json_obj(obj: dict, section: str, pkg: str) -> str:
            ext = obj.get("ExtendedObjectName", "")
            name_part = (f"\"{obj.get('Name','')}\" extends \"{ext}\""
                         if ext else f"\"{obj.get('Name','')}\"")
            lines = [f"// [{pkg}] {section[:-1]} {obj.get('Id','')} {name_part}"]
            fields = obj.get("Fields", obj.get("Variables", []))
            for f in fields[:_MAX_FIELDS]:
                tname = (f.get("TypeDefinition") or {}).get("Name", "?")
                lines.append(f"  field({f.get('Id','')}; {f.get('Name','')}; {tname})")
            if len(fields) > _MAX_FIELDS:
                lines.append(f"  // ... +{len(fields) - _MAX_FIELDS} more fields")
            # RequestPage fields (reports / report extensions)
            req_page = obj.get("RequestPage") or {}
            req_fields = req_page.get("Fields", req_page.get("Controls", req_page.get("DataItems", [])))
            if req_fields:
                lines.append("  // RequestPage fields:")
                for f in req_fields[:_MAX_FIELDS]:
                    tname = (f.get("TypeDefinition") or {}).get("Name", "?")
                    lines.append(f"    field({f.get('Id','')}; {f.get('Name','')}; {tname})")
            elif "Report" in section:
                lines.append("  // RequestPage: no fields found in symbols")
            methods = obj.get("Methods", [])
            for m in methods[:_MAX_METHODS]:
                params = ", ".join(
                    f"{p.get('Name','')}: {(p.get('TypeDefinition') or {}).get('Name','')}"
                    for p in (m.get("Parameters") or [])
                )
                ret = (m.get("ReturnTypeDefinition") or {}).get("Name", "")
                sig = f"  procedure {m.get('Name','')}({params})"
                if ret:
                    sig += f": {ret}"
                lines.append(sig)
            if len(methods) > _MAX_METHODS:
                lines.append(f"  // ... +{len(methods) - _MAX_METHODS} more procedures")
            return "\n".join(lines)

        _BASE_SECTIONS = ("Tables", "Codeunits", "Pages", "Reports", "Enums")
        _EXT_SECTIONS  = ("TableExtensions", "PageExtensions", "ReportExtensions", "EnumExtensions")
        _MAX_PROC_CHARS = 4_000

        def _read_al_source(zf, al_name: str, search: str) -> str:
            """
            Object name match  → all procedure signatures (one line each).
            Procedure name match → full body of matching procedures.
            """
            from src.context.al_parser import _PROC_RE as _re
            src   = zf.read(al_name).decode("utf-8", errors="replace")
            procs = list(_re.finditer(src))
            tag   = f"// [{Path(al_name).stem}]"

            # Check if search matches any procedure name
            proc_hits = [
                (i, m) for i, m in enumerate(procs)
                if search in (m.group("name_q") or m.group("name_u") or "").lower()
            ]

            if proc_hits:
                # Return full body of matching procedures
                parts = [tag]
                for i, m in proc_hits:
                    end  = procs[i + 1].start() if i + 1 < len(procs) else len(src)
                    body = src[m.start():end].rstrip()
                    if len(body) > _MAX_PROC_CHARS:
                        body = body[:_MAX_PROC_CHARS] + "\n// ... [truncated]"
                    parts.append(body)
                return "\n\n".join(parts)

            # Return: object header + all procedure signatures
            header = src[:procs[0].start()].rstrip() if procs else src[:500]
            sigs   = []
            for m in procs:
                pname    = (m.group("name_q") or m.group("name_u") or "").strip()
                kind     = m.group("kind").lower()
                sig_line = src[m.start():m.end() + 200].split("\n")[0].strip()
                sigs.append(f"  {sig_line}")
            return f"{tag}\n{header}\n\n// Procedures:\n" + "\n".join(sigs)

        for app_path in app_files:
            try:
                with zipfile.ZipFile(app_path) as zf:
                    names = zf.namelist()
                    is_microsoft = app_path.stem.startswith("Microsoft_")

                    # Non-Microsoft apps: read .al source (contains implementation)
                    if not is_microsoft:
                        al_all = [n for n in names if n.endswith(".al")]

                        # Pass 1: file/object name match → procedure signatures
                        al_file_matches = [
                            n for n in al_all if name_lower in Path(n).stem.lower()
                        ]
                        for al_name in al_file_matches[:2]:
                            results.append(_read_al_source(zf, al_name, name_lower))
                            if len(results) >= _MAX_RESULTS:
                                break
                        if al_file_matches:
                            if len(results) >= _MAX_RESULTS:
                                break
                            continue  # object found — skip JSON

                        # Pass 2: procedure name match across all .al files
                        for al_name in al_all[:30]:
                            summary = _read_al_source(zf, al_name, name_lower)
                            if "// Procedures:" not in summary:  # has proc body hits
                                results.append(summary)
                                if len(results) >= _MAX_RESULTS:
                                    break
                        if results:
                            if len(results) >= _MAX_RESULTS:
                                break
                            continue

                    # JSON-based search (Microsoft apps, or non-Microsoft without .al source)
                    if "SymbolReference.json" not in names:
                        continue
                    syms = json.loads(
                        zf.read("SymbolReference.json").decode("utf-8-sig", errors="replace")
                    )
                    # Base objects: match by Name
                    for section in _BASE_SECTIONS:
                        for obj in syms.get(section, []):
                            if name_lower in obj.get("Name", "").lower():
                                results.append(_summarise_json_obj(obj, section, app_path.stem))
                                if len(results) >= _MAX_RESULTS:
                                    break
                        if len(results) >= _MAX_RESULTS:
                            break
                    # Extension objects: match by Name OR ExtendedObjectName
                    if len(results) < _MAX_RESULTS:
                        for section in _EXT_SECTIONS:
                            for obj in syms.get(section, []):
                                if (name_lower in obj.get("Name", "").lower()
                                        or name_lower in obj.get("ExtendedObjectName", "").lower()):
                                    results.append(_summarise_json_obj(obj, section, app_path.stem))
                                    if len(results) >= _MAX_RESULTS:
                                        break
                            if len(results) >= _MAX_RESULTS:
                                break
            except Exception as e:
                results.append(f"// Error reading {app_path.name}: {e}")
            if len(results) >= _MAX_RESULTS:
                break

        if not results:
            return (
                f"'{object_name}' not found in any .app package. "
                f"Packages available: {', '.join(p.stem for p in app_files)}"
            )
        return "\n\n---\n\n".join(results)

    return [rag_search, list_al_files, read_al_file, read_alpackage_symbols]
