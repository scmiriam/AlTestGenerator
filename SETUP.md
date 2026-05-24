# Manual de instalación y configuración — AL Test Generator

## Requisitos previos

- **Python 3.10 o superior** — [python.org](https://www.python.org/downloads/)
- **Git** — para clonar el repositorio
- **Visual Studio Code** con la extensión **GitHub Copilot** (plan Pro o superior)
- **API key de Anthropic** — el agente usa Claude como LLM por defecto

---

## 1. Obtener el proyecto

```bash
git clone <url-del-repositorio>
cd TFGLaberit
```

O descomprime el ZIP del proyecto si se compartió así.

---

## 2. Crear entorno virtual e instalar dependencias

```bash
python -m venv .venv
```

**Windows:**
```bash
.venv\Scripts\activate
```

**macOS / Linux:**
```bash
source .venv/bin/activate
```

Instalar dependencias:
```bash
pip install -r requirements.txt
```

> El primer arranque descarga el modelo de embeddings `BAAI/bge-m3` (~570 MB) desde HuggingFace y lo cachea localmente. Solo ocurre una vez.

---

## 3. Configurar variables de entorno

Copia el archivo de ejemplo y edítalo:

```bash
cp .env.example .env
```

Abre `.env` y rellena al menos:

```env
ANTHROPIC_API_KEY=sk-ant-...

# Ruta absoluta a la raíz del proyecto AL de Business Central que quieres testear
PROJECT_ROOT=C:\ruta\a\tu\proyecto\BC
```

- `ANTHROPIC_API_KEY` es obligatoria (el agente usa Claude Sonnet por defecto).
- `PROJECT_ROOT` apunta a la carpeta del proyecto AL que contiene `app.json`. Si no se define, el agente usará el directorio de trabajo actual.

---

## 4. Construir la base de conocimiento (vectorstore)

La base de datos vectorial **no se incluye en el repositorio** y debe construirse una vez en cada máquina. Se hace desde VS Code a través del servidor MCP (ver sección siguiente), llamando a la herramienta `rebuild_vectorstore` en el chat de Copilot:

```
@al-test-generator rebuild_vectorstore
```

Esto indexa:
- `Data/book_al_testing.md` — libro de buenas prácticas AL
- `Data/TestExamples/` — tests de referencia curados

El resultado se guarda en `chroma_al_testing/` (local, no se sube a git).

---

## 5. Integrar el agente en el proyecto AL de Business Central

Para que GitHub Copilot sepa cómo invocar el agente y qué reglas seguir, el proyecto AL que se quiere testear necesita dos ficheros de configuración. La carpeta `project-template/` de este repositorio contiene las plantillas listas para copiar:

```
project-template/
├── .github/
│   └── copilot-instructions.md   ← instrucciones de comportamiento para Copilot
└── .vscode/
    └── mcp.json                  ← configuración del servidor MCP para VS Code
```

### 5.1 Copiar las plantillas al proyecto AL

Copia ambas carpetas (`.github/` y `.vscode/`) a la raíz de tu proyecto AL (donde está `app.json`):

```
MiProyectoAL/
├── app.json
├── .github/
│   └── copilot-instructions.md   ← copiado desde project-template/
├── .vscode/
│   └── mcp.json                  ← copiado desde project-template/
└── ...
```

> Si el proyecto ya tiene una carpeta `.vscode/`, simplemente añade el fichero `mcp.json` dentro; no reemplaces otros ficheros existentes como `launch.json` o `settings.json`.

### 5.2 Editar `mcp.json` con las rutas correctas

Abre el fichero `.vscode/mcp.json` recién copiado y sustituye las rutas de ejemplo por las rutas absolutas reales en tu máquina:

**Windows:**
```json
{
  "servers": {
    "al-test-generator": {
      "type": "stdio",
      "command": "C:\\ruta\\a\\TFGLaberit\\.venv\\Scripts\\python.exe",
      "args": ["C:\\ruta\\a\\TFGLaberit\\mcp_server.py"],
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

**macOS / Linux:**
```json
{
  "servers": {
    "al-test-generator": {
      "type": "stdio",
      "command": "/ruta/a/TFGLaberit/.venv/bin/python",
      "args": ["/ruta/a/TFGLaberit/mcp_server.py"],
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

> **Importante:** usa la ruta al ejecutable de Python **dentro del entorno virtual** (`.venv\Scripts\python.exe` en Windows, `.venv/bin/python` en macOS/Linux), no el Python del sistema. Así el servidor arranca con todas las dependencias instaladas.
>
> La variable `PROJECT_ROOT` con el valor `${workspaceFolder}` se resuelve automáticamente al directorio raíz del workspace de VS Code. No es necesario cambiarla.

El fichero `.github/copilot-instructions.md` **no requiere edición**: contiene las reglas de comportamiento de Copilot que son independientes del proyecto concreto.

### 5.3 Activar el servidor en VS Code

1. Abre VS Code en la carpeta del **proyecto AL** (`File > Open Folder...` → selecciona la carpeta que contiene `app.json`).
2. Abre el panel de chat de Copilot (`Ctrl+Alt+I` o icono de Copilot en la barra lateral).
3. En el selector de modo del chat, elige **Agent**.
4. Haz clic en el icono de herramientas (🔧) y comprueba que aparece `al-test-generator` en la lista de servidores MCP activos.

Si no aparece, abre la paleta de comandos (`Ctrl+Shift+P`) y ejecuta:
```
MCP: List Servers
```

---

## 6. Verificar que todo funciona

Con el servidor activo, prueba en el chat de Copilot en modo Agent:

```
@al-test-generator Genera un test para el procedimiento PostSalesOrder en SalesManagement
```

El agente debería responder con un codeunit AL de tests.

---

## Resumen de herramientas disponibles

| Herramienta | Cuándo usarla |
|---|---|
| `generate_al_test` | Generar un codeunit de tests a partir de una descripción |
| `generate_al_test_from_recording` | Generar tests desde una grabación YAML de BC |
| `fix_al_test` | Corregir un test que falla en runtime en Business Central |
| `search_al_knowledge` | Buscar en la base de conocimiento sin generar código |
| `refresh_examples` | Reindexar solo los ejemplos de `Data/TestExamples/` cuando se añadan ficheros |
| `rebuild_vectorstore` | Reconstruir toda la base de conocimiento desde cero |

---

## Solución de problemas frecuentes

**El servidor no arranca / no aparece en Copilot**
- Comprueba que la ruta al ejecutable de Python en `mcp.json` es correcta y apunta al entorno virtual.
- Abre un terminal, activa el entorno virtual y ejecuta `python mcp_server.py` manualmente para ver el error.

**Error: `No se encontró vectorstore`**
- El vectorstore no se ha construido todavía. Llama a `rebuild_vectorstore` desde el chat.

**Error: `Falta la variable de entorno ANTHROPIC_API_KEY`**
- El archivo `.env` no está en la raíz del proyecto o la clave no está rellena.

**El modelo de embeddings tarda mucho en cargar**
- Es normal la primera vez (~570 MB de descarga). Las siguientes veces se carga desde caché local en segundos.
- Si la máquina no tiene conexión a internet, descarga el modelo previamente y descomenta `TRANSFORMERS_OFFLINE=1` en `.env`.
