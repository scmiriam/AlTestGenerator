"""
embedder.py — Embeddings (BGE-M3) + ChromaDB + retriever híbrido (MMR + BM25).
"""
import shutil
from pathlib import Path
from collections import Counter

from langchain_core.documents import Document
from langchain_community.vectorstores import Chroma
from langchain_community.retrievers import BM25Retriever
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_classic.retrievers.ensemble import EnsembleRetriever
from tqdm import tqdm

# ── Configuración ─────────────────────────────────────────────────────

EMBEDDING_MODEL   = "BAAI/bge-m3"             # producción  (~570 MB)
NOTEBOOK_MODEL    = "BAAI/bge-small-en-v1.5"  # demo / test (~130 MB)
COLLECTION_NAME   = "al_testing_book"
DEFAULT_PERSIST   = "./chroma_al_testing"
INGEST_BATCH_SIZE = 64


# ── Carga del modelo ──────────────────────────────────────────────────

def load_embeddings(device: str = "cpu",
                    model_name: str = EMBEDDING_MODEL) -> HuggingFaceEmbeddings:
    """
    Carga el modelo de embedding desde HuggingFace (se cachea localmente).

    Args:
        device:     'cpu' o 'cuda'.
        model_name: Nombre del modelo HuggingFace.
    """
    print(f"[embedder] Cargando modelo {model_name} en {device}...")
    return HuggingFaceEmbeddings(
        model_name    = model_name,
        model_kwargs  = {"device": device},
        encode_kwargs = {
            "normalize_embeddings": True,  # obligatorio para BGE
            "batch_size": 32,
        },
    )


# ── Ingesta ───────────────────────────────────────────────────────────

def ingest_documents(docs: list, embeddings,
                     persist_dir: str = DEFAULT_PERSIST,
                     overwrite: bool = False) -> Chroma:
    """
    Ingesta Documents en ChromaDB.
    Si persist_dir ya existe y overwrite=False, lanza FileExistsError para
    evitar duplicar vectores.
    """
    persist_path = Path(persist_dir)

    if persist_path.exists() and any(persist_path.iterdir()):
        if not overwrite:
            raise FileExistsError(
                f"'{persist_dir}' ya contiene datos. "
                "Usa overwrite=True para sobreescribir o load_vectorstore() para reutilizarlo."
            )
        print(f"[embedder] overwrite=True — borrando colección existente en '{persist_dir}'...")
        shutil.rmtree(persist_dir)

    print(f"[embedder] Ingestando {len(docs)} chunks en '{persist_dir}'...")

    vectorstore = None
    batches = [docs[i:i + INGEST_BATCH_SIZE] for i in range(0, len(docs), INGEST_BATCH_SIZE)]

    for batch in tqdm(batches, desc="Embedding batches"):
        if vectorstore is None:
            vectorstore = Chroma.from_documents(
                documents         = batch,
                embedding         = embeddings,
                persist_directory = persist_dir,
                collection_name   = COLLECTION_NAME,
            )
        else:
            vectorstore.add_documents(batch)

    print(f"[embedder] Ingesta completada. {len(docs)} chunks almacenados.")
    return vectorstore


# ── Carga de vectorstore existente ────────────────────────────────────

def load_vectorstore(embeddings,
                     persist_dir: str = DEFAULT_PERSIST) -> Chroma:
    """Carga un vectorstore ya persistido en disco sin re-embeber nada."""
    if not Path(persist_dir).exists():
        raise FileNotFoundError(
            f"No se encontró vectorstore en '{persist_dir}'. "
            "Ejecuta primero ingest_documents()."
        )
    print(f"[embedder] Cargando vectorstore desde '{persist_dir}'...")
    return Chroma(
        persist_directory = persist_dir,
        embedding_function= embeddings,
        collection_name   = COLLECTION_NAME,
    )


def load_all_docs(vectorstore: Chroma) -> list:
    """Recupera todos los Documents almacenados en el vectorstore."""
    raw = vectorstore.get(include=["documents", "metadatas"])
    return [
        Document(page_content=t, metadata=m)
        for t, m in zip(raw["documents"], raw["metadatas"])
    ]


# ── Retriever híbrido (MMR + BM25) ────────────────────────────────────

def build_hybrid_retriever(vectorstore, all_docs: list, k: int = 6,
                           vector_weight: float = 0.6,
                           content_type_filter=None) -> EnsembleRetriever:
    """
    Combina búsqueda vectorial MMR con BM25 para mayor robustez.

    Args:
        vectorstore:         Chroma ya cargado.
        all_docs:            Todos los Documents (para BM25).
        k:                   Número de resultados a devolver.
        vector_weight:       Peso del retriever vectorial (BM25 = 1 - vector_weight).
        content_type_filter: Si se especifica, filtra por tipo antes de buscar.
    """
    search_kwargs = {
        "k":           k,
        "fetch_k":     k * 4,
        "lambda_mult": 0.7,
    }
    if content_type_filter:
        search_kwargs["filter"] = {"content_type": content_type_filter}

    vector_retriever = vectorstore.as_retriever(
        search_type   = "mmr",
        search_kwargs = search_kwargs,
    )

    bm25_docs = (
        [d for d in all_docs if d.metadata.get("content_type") == content_type_filter]
        if content_type_filter
        else all_docs
    )
    bm25_retriever   = BM25Retriever.from_documents(bm25_docs)
    bm25_retriever.k = k

    return EnsembleRetriever(
        retrievers = [vector_retriever, bm25_retriever],
        weights    = [vector_weight, 1 - vector_weight],
    )


def get_retriever_for_query(vectorstore, all_docs: list, k: int = 6) -> EnsembleRetriever:
    """
    Retriever híbrido sin filtro de tipo: mezcla test_example, company_example y app_code.
    """
    return build_hybrid_retriever(
        vectorstore         = vectorstore,
        all_docs            = all_docs,
        k                   = k,
        content_type_filter = None,
    )


# ── Estadísticas rápidas ──────────────────────────────────────────────

def print_vectorstore_stats(all_docs: list) -> None:
    print(f"Total chunks: {len(all_docs)}")
    counts = Counter(d.metadata.get("content_type", "?") for d in all_docs)
    print("\nDistribución por content_type:")
    for t, c in sorted(counts.items()):
        print(f"  {t:20s}: {c}")
