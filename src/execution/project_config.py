"""
project_config.py — Describe la estructura de un proyecto AL de Business Central.
Pensado para integración futura con VS Code: el IDE exporta PROJECT_ROOT como
variable de entorno para apuntar al workspace activo.
"""
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass
class ProjectConfig:
    project_root: Path
    src_dirs: list
    test_dirs: list
    name: str = "BC Project"

    @classmethod
    def default(cls):
        """Infiere la estructura desde el directorio actual si no se especifica PROJECT_ROOT."""
        root_env = os.getenv("PROJECT_ROOT")
        if root_env:
            return cls.from_path(root_env)
        
        # Fallback: intentar encontrar la carpeta del proyecto en el CWD
        cwd = Path.cwd()
        return cls.from_path(cwd)

    @classmethod
    def from_path(cls, path):
        """Infiere la estructura del proyecto a partir de su raíz."""
        root = Path(path).resolve()
        src_dirs, test_dirs = [], []
        for candidate in sorted(root.rglob("*")):
            if not candidate.is_dir():
                continue
            depth = len(candidate.relative_to(root).parts)
            if depth > 3:
                continue
            name = candidate.name.lower()
            if name == "src":
                src_dirs.append(candidate)
            elif name in ("test", "tests"):
                test_dirs.append(candidate)
        return cls(project_root=root, src_dirs=src_dirs, test_dirs=test_dirs, name=root.name)

    @classmethod
    def from_env(cls):
        """Lee PROJECT_ROOT del entorno. Si no está definida, usa el default."""
        root = os.getenv("PROJECT_ROOT")
        return cls.from_path(root) if root else cls.default()

    def all_al_files(self) -> list:
        """Devuelve todos los ficheros .al del proyecto (src + tests)."""
        files = []
        for d in self.src_dirs + self.test_dirs:
            files.extend(sorted(Path(d).rglob("*.al")))
        return files

    def find_file(self, name: str):
        """Busca un fichero .al por nombre (insensible a mayúsculas, sin extensión)."""
        name_lower = name.lower().removesuffix(".al")
        for f in self.all_al_files():
            if f.stem.lower() == name_lower:
                return f
        return None

    def is_test_file(self, path: Path) -> bool:
        """True si el fichero pertenece a alguno de los directorios de tests."""
        for test_dir in self.test_dirs:
            try:
                Path(path).relative_to(test_dir)
                return True
            except ValueError:
                continue
        return False

    def get_id_ranges(self) -> list:
        """Devuelve los idRanges definidos en app.json, o lista vacía si no existe."""
        import json
        app_json = self.project_root / "app.json"
        if app_json.exists():
            data = json.loads(app_json.read_text(encoding="utf-8"))
            return data.get("idRanges", [])
        return []
