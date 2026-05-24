"""
al_compiler.py — Compilación de AL con alc.exe y extracción de errores.

Escribe el código generado en un fichero temporal dentro del proyecto,
lanza alc.exe y devuelve los errores de compilación para el bucle de
autocorrección del agente.
"""
import glob
import logging
import re
import subprocess
from pathlib import Path

log = logging.getLogger(__name__)

_TEMP_FILENAME = "_agent_generated_test.al"
_COMPILE_TIMEOUT = 45  # segundos


def _find_alc() -> Path | None:
    """Busca alc.exe en las extensiones de VS Code instaladas."""
    pattern = str(Path.home() / ".vscode/extensions/ms-dynamics-smb.al-*/bin/win32/alc.exe")
    matches = sorted(glob.glob(pattern), reverse=True)  # más reciente primero
    if matches:
        return Path(matches[0])
    return None


ALC_PATH = _find_alc()


def _find_test_dir(project_root: Path) -> Path:
    """Devuelve el directorio de tests del proyecto, creando src/Tests solo si no existe ninguno."""
    for candidate in ["src/Tests", "src/tests", "Tests", "tests"]:
        d = project_root / candidate
        if d.is_dir():
            return d
    fallback = project_root / "src" / "Tests"
    fallback.mkdir(parents=True, exist_ok=True)
    return fallback


def _parse_errors(output: str) -> list[str]:
    """
    Extrae líneas de error y warning del output de alc.exe.

    Formato alc.exe: path\file.al(line,col): error AL0001: message
    Simplifica la ruta a solo el nombre de fichero para reducir tokens.
    """
    errors = []
    for line in output.splitlines():
        if ": error AL" in line or ": warning AL" in line:
            simplified = re.sub(r'^.*?([^/\\]+\.al\(\d+,\d+\))', r'\1', line)
            errors.append(simplified)
    return errors


def compile_al(project_root: Path, generated_code: str) -> list[str]:
    """
    Escribe generated_code en un fichero temporal, compila el proyecto con
    alc.exe y devuelve la lista de errores de compilación.

    Args:
        project_root:   Raíz del proyecto AL (donde está app.json).
        generated_code: Código AL generado por el agente.

    Returns:
        Lista de strings con errores/warnings. Vacía si compila limpio.
        Devuelve [] también si alc.exe no está disponible (fallo silencioso).
    """
    if ALC_PATH is None:
        log.warning("alc.exe no encontrado — saltando compilación.")
        return []

    test_dir  = _find_test_dir(project_root)
    temp_file = test_dir / _TEMP_FILENAME

    try:
        temp_file.write_text(generated_code, encoding="utf-8")
        log.info(f"Compilando proyecto en {project_root}...")

        packages_dir = project_root / ".alpackages"
        cmd = [
            str(ALC_PATH),
            f"/project:{project_root}",
            f"/packagecachepath:{packages_dir}",
            "/nocreatepdf",
        ]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=_COMPILE_TIMEOUT,
        )
        output = result.stdout + result.stderr
        errors = _parse_errors(output)

        if errors:
            log.info(f"Compilación: {len(errors)} error(es) encontrados.")
        else:
            log.info("Compilación limpia.")

        return errors

    except subprocess.TimeoutExpired:
        log.warning("alc.exe timeout — saltando compilación.")
        return []
    except OSError as e:
        log.warning(f"Error al ejecutar alc.exe: {e}")
        return []
    finally:
        if temp_file.exists():
            temp_file.unlink()
