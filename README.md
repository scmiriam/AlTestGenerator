# AL Test Generator — Deployment Guide

This project is a hybrid RAG (Retrieval-Augmented Generation) agent designed to automate the creation of AL test codeunits for Microsoft Dynamics 365 Business Central.

## Project Structure

- `src/`: Core Python modules (Agent, Parser, Embedder, etc.).
- `Notebooks/`: Jupyter notebooks for experimentation and demo.
    - `AL_Test_Generator_Master.ipynb`: The main entry point for the project.
- `Data/`: Project data, including the testing knowledge base (`libro_al_testing.md`).
- `requirements.txt`: Python dependencies.
- `.env`: Environment variables (API Keys).

## Setup Instructions

### 1. Install Dependencies

Ensure you have Python 3.10+ installed. Run:

```bash
pip install -r requirements.txt
```

*Note: For Windows users, you might need to install Poppler and Tesseract OCR manually if you plan to process PDFs directly.*

### 2. Configure Environment

1. Copy `.env.example` to `.env` (done during setup).
2. Edit `.env` and provide your API keys:
   - `OPENAI_API_KEY` or `ANTHROPIC_API_KEY`.
3. (Optional) Set `PROJECT_ROOT` to point to your Business Central project folder. Otherwise, it will default to the current working directory.

### 3. Running in Jupyter

1. Start the Jupyter server:
   ```bash
   jupyter lab
   ```
2. Navigate to `Notebooks/AL_Test_Generator_Master.ipynb`.
3. Run the cells in order. The setup cell will automatically detect the project root and load your environment variables.

## Important Notes

- **Knowledge Base**: The main testing book should be located at `Data/libro_al_testing.md`.
- **Vectorstore**: By default, the vectorstore is persisted in `./chroma_al_testing`. You can change this in `src/embedder.py` or via environment variables.
- **Imports**: The notebooks use relative path injection (`sys.path.append('..')`) to import the `src` module. Always keep the notebooks in a subfolder or adjust the path setup accordingly.
# TFG
