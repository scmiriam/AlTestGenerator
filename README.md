# AL Test Generator

Agente RAG híbrido para generar automáticamente codeunits de tests AL para Microsoft Dynamics 365 Business Central. Se integra con VS Code a través del protocolo MCP y GitHub Copilot.

## Estructura del proyecto

```
TFGLaberit/
├── src/                    # Módulos principales
│   ├── agent.py            # ALTestAgent — lógica RAG + tool calling
│   ├── embedder.py         # Embeddings (BGE-M3) + ChromaDB + retriever híbrido
│   ├── al_parser.py        # Parser de ficheros .al
│   ├── al_tools.py         # Tools del agente (leer ficheros, buscar símbolos...)
│   ├── al_compiler.py      # Compilación con alc.exe para autocorrección
│   ├── chunker.py          # Segmentación de documentos
│   ├── doc_parser.py       # Parser del libro Markdown
│   ├── llm_factory.py      # Instanciación de LLMs (Claude / OpenAI)
│   └── project_config.py   # Configuración del proyecto AL activo
├── Data/
│   ├── book_al_testing.md  # Libro de buenas prácticas AL (fuente del RAG)
│   └── TestExamples/       # Tests de referencia curados (indexados en el RAG)
├── NotebookDocumentPreprocess/
│   ├── Procesamiento PDF limpio.ipynb  # Notebook de extracción del libro desde PDF
│   └── Automated Testing (...).pdf     # Libro original en PDF
├── mcp_server.py           # Servidor MCP — punto de entrada principal
├── chroma_al_testing/      # Vectorstore persistido (generado localmente, no en git)
├── .env.example            # Plantilla de variables de entorno
├── requirements.txt        # Dependencias Python
└── SETUP.md                # Manual de instalación detallado
```

## Inicio rápido

Consulta [SETUP.md](SETUP.md) o el [Manual de usuario.pdf](Manual de usuario.pdf) para las instrucciones completas de instalación y configuración del servidor MCP en VS Code.

Resumen:

```bash
# Crear entorno virtual e instalar dependencias
python -m venv .venv

# Activar en Windows (PowerShell)
.venv\Scripts\Activate.ps1

# Activar en Windows (CMD)
.venv\Scripts\activate.bat

# Instalar requerimientos y preparar entorno
pip install -r requirements.txt
cp .env.example .env
```

Tras configurar el servidor MCP en VS Code, construir el vectorstore desde el chat de Copilot:

```bash
@al-test-generator rebuild_vectorstore
```

### Herramientas MCP disponibles

* **`generate_al_test`** Genera un codeunit de tests a partir de una descripción.
  
* **`generate_al_test_from_recording`** Genera tests desde una grabación YAML de Business Central.
  
* **`fix_al_test`** Corrige un test que falla en runtime en Business Central.
  
* **`search_al_knowledge`** Busca en la base de conocimiento sin generar código.
  
* **`refresh_examples`** Reindexar los ejemplos de `Data/TestExamples/`.
  
* **`rebuild_vectorstore`** Reconstruye toda la base de conocimiento desde cero.

## Requisitos

- Python 3.10+
- VS Code con GitHub Copilot (el plan gratuito es suficiente)
- API key de Anthropic (`ANTHROPIC_API_KEY`) o OpenAI (`OPENAI_API_KEY`)
- Modelo de embeddings `BAAI/bge-m3` (~570 MB, se descarga automáticamente en el primer arranque)
