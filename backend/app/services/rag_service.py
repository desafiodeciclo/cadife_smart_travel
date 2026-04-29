"""
RAG Service — ChromaDB vectorstore access with semantic metadata filtering.

get_vectorstore()              — lazy-init vectorstore (for direct use)
get_rag_document_count()       — total indexed chunks
retrieve_context()             — unfiltered similarity search (fallback)
retrieve_with_metadata_filter()— hard-constraint filtered retrieval
"""
import os
from typing import Optional

import structlog
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import Chroma
from langchain_chroma import Chroma
from langchain_openai import OpenAIEmbeddings
from pydantic import SecretStr

from app.core.config import get_settings
from app.services.metadata_tagger import build_chroma_filter

logger = structlog.get_logger()
settings = get_settings()

_vectorstore: Optional[Chroma] = None


def get_vectorstore() -> Chroma:
    """
    Return (or lazily create) the shared ChromaDB vectorstore.

    On first call:
      - If persist_dir exists and has data → opens existing collection.
      - Otherwise → creates empty collection; ingestion_pipeline will populate it.
    """
    global _vectorstore
    if _vectorstore is None:
        embeddings = OpenAIEmbeddings(
            model="text-embedding-3-small",
            api_key=SecretStr(settings.OPENAI_API_KEY),
        )
        persist_dir = settings.CHROMA_PERSIST_DIR
        _vectorstore = Chroma(
            persist_directory=persist_dir,
            embedding_function=embeddings,
        )
        count = _try_count(_vectorstore)
        logger.info("vectorstore_ready", path=persist_dir, chunks=count)
    return _vectorstore


def invalidate_vectorstore() -> None:
    """Force re-open on next access (call after bulk ingestion changes)."""
    global _vectorstore
    _vectorstore = None


def get_rag_document_count() -> int:
    try:
        return _try_count(get_vectorstore())
    except Exception:
        return 0


def retrieve_context(query: str, k: int = 3) -> str:
    """Unfiltered similarity search — returns joined page_content strings."""
    try:
        docs = get_vectorstore().similarity_search(query, k=k)
        return _join(docs)
    except Exception as exc:
        logger.warning("rag_retrieval_failed", error=str(exc))
        return ""


def retrieve_with_metadata_filter(
    query: str,
    *,
    k: int = 4,
    destino: Optional[str] = None,
    tema: Optional[str] = None,
    perfil: Optional[str] = None,
) -> str:
    """
    Filtered similarity search using hard-constraint metadata tags.

    When a tag dimension is supplied (e.g. destino="Nordeste"), ChromaDB
    restricts candidates to chunks tagged with that value OR chunks with no
    tag on that dimension (="" — general knowledge content).

    Falls back to unfiltered search if the filtered result set is empty,
    preventing silent information gaps.
    """
    chroma_filter = build_chroma_filter(destino=destino, tema=tema, perfil=perfil)

    try:
        vs = get_vectorstore()
        if chroma_filter:
            docs = vs.similarity_search(query, k=k, filter=chroma_filter)
            logger.debug(
                "rag_filtered_retrieval",
                query_preview=query[:60],
                destino=destino,
                tema=tema,
                perfil=perfil,
                results=len(docs),
            )
            # Fallback: if filter yields nothing, widen to unfiltered
            if not docs:
                logger.info("rag_filter_empty_fallback", filter=chroma_filter)
                docs = vs.similarity_search(query, k=k)
        else:
            docs = vs.similarity_search(query, k=k)

        return _join(docs)
    except Exception as exc:
        logger.warning("rag_filtered_retrieval_failed", error=str(exc))
        return ""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _join(docs: list[Document]) -> str:
    return "\n\n".join(d.page_content for d in docs)


def _try_count(vs: Chroma) -> int:
    try:
        return vs._collection.count()
    except Exception:
        return 0
