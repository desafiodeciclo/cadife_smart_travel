"""
RAG Service — ChromaDB vectorstore access with semantic metadata filtering
and hybrid search (vector + keyword) via Reciprocal Rank Fusion (RRF).

get_vectorstore()              — lazy-init vectorstore (for direct use)
get_rag_document_count()       — total indexed chunks
retrieve_context()             — hybrid search with guardrails (default)
retrieve_with_metadata_filter()— hybrid search + metadata filter + guardrails
retrieve_hybrid()              — core hybrid retrieval with RRF reranking
"""

import re
from typing import Optional

import structlog
from langchain_core.documents import Document
from langchain_postgres import PGVector
from langchain_openai import OpenAIEmbeddings

from app.core.config import get_settings
from app.services.metadata_tagger import build_chroma_filter
from app.services.context_guardrails import apply_guardrails

logger = structlog.get_logger()
settings = get_settings()

_vectorstore: Optional[PGVector] = None


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

_RRF_K = 60  # Reciprocal Rank Fusion constant (empirically validated)
_KEYWORD_WEIGHT = 0.5  # Weight of keyword signal relative to vector signal
_VECTOR_CANDIDATES_MULTIPLIER = 3  # How many candidates to fetch for reranking


def _get_embeddings() -> OpenAIEmbeddings:
    if not settings.OPENROUTER_API_KEY:
        raise RuntimeError(
            "Nenhuma OPENROUTER_API_KEY configurada. Defina OPENROUTER_API_KEY no .env"
        )
    return OpenAIEmbeddings(
        model=settings.OPENROUTER_EMBEDDING_MODEL,
        openai_api_key=settings.OPENROUTER_API_KEY,
        openai_api_base="https://openrouter.ai/api/v1",
        check_embedding_ctx_length=False,
        model_kwargs={"encoding_format": "float"},
    )


def get_vectorstore() -> PGVector:
    global _vectorstore
    if _vectorstore is None:
        embeddings = _get_embeddings()
        _vectorstore = PGVector(
            embeddings=embeddings,
            collection_name="cadife_knowledge_base",
            connection=settings.PGVECTOR_CONNECTION_STRING,
            use_jsonb=True,
        )
        logger.info("vectorstore_ready", backend="pgvector")
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


# ---------------------------------------------------------------------------
# Hybrid Search — Vector + Keyword with RRF
# ---------------------------------------------------------------------------


def _tokenize(text: str) -> set[str]:
    """Simple tokenizer: lowercase, remove punctuation, split on whitespace."""
    text = re.sub(r"[^\w\s]", " ", text.lower())
    tokens = {t for t in text.split() if len(t) > 2}
    return tokens


def _keyword_score(query: str, doc_text: str) -> float:
    """
    Compute a normalized keyword overlap score between query and document.

    Returns:
        Float in [0, 1] — 1.0 means all query tokens appear in doc.
    """
    query_tokens = _tokenize(query)
    if not query_tokens:
        return 0.0
    doc_tokens = _tokenize(doc_text)
    overlap = query_tokens & doc_tokens
    return len(overlap) / len(query_tokens)


def _reciprocal_rank_fusion(
    vector_ranked: list[Document],
    keyword_ranked: list[Document],
    keyword_weight: float = _KEYWORD_WEIGHT,
    k: int = _RRF_K,
) -> list[Document]:
    """
    Combine two ranked lists via Reciprocal Rank Fusion.

    For each document present in either list:
        rrf_score = 1/(k + rank_vector) + keyword_weight/(k + rank_keyword)

    Documents present in only one list still contribute via that single signal.

    Args:
        vector_ranked: Docs ordered by vector similarity (best first).
        keyword_ranked: Docs ordered by keyword score (best first).
        keyword_weight: Scalar weight for the keyword signal.
        k: RRF damping constant.

    Returns:
        Docs reranked by descending RRF score.
    """
    # Defensive: callers must never pass None, but guard anyway
    vector_ranked = vector_ranked or []
    keyword_ranked = keyword_ranked or []

    # Build rank lookups
    vector_ranks = {id(d): idx + 1 for idx, d in enumerate(vector_ranked)}
    keyword_ranks = {id(d): idx + 1 for idx, d in enumerate(keyword_ranked)}

    all_docs = {id(d): d for d in (vector_ranked + keyword_ranked)}

    scored = []
    for doc_id, doc in all_docs.items():
        rank_v = vector_ranks.get(doc_id, len(vector_ranked) + 1)
        rank_k = keyword_ranks.get(doc_id, len(keyword_ranked) + 1)
        score = (1.0 / (k + rank_v)) + (keyword_weight / (k + rank_k))
        scored.append((score, doc))

    scored.sort(key=lambda x: x[0], reverse=True)
    return [doc for _, doc in scored]


def retrieve_hybrid(
    query: str,
    k: int = 3,
    filter: Optional[dict] = None,
) -> list[Document]:
    """
    Hybrid retrieval: vector similarity + keyword scoring, reranked via RRF.

    Steps:
      1. Fetch N = k * MULTIPLIER candidates via vector similarity.
      2. Compute keyword scores for each candidate against the query.
      3. Create keyword ranking from those scores.
      4. Fuse vector and keyword rankings via RRF.
      5. Return top-k documents.

    Args:
        query: User query string.
        k: Number of final documents to return.
        filter: Optional ChromaDB metadata filter dict.

    Returns:
        Reranked list of Documents (length <= k).
    """
    if not query or not query.strip():
        return []

    try:
        vs = get_vectorstore()
        candidate_k = max(k * _VECTOR_CANDIDATES_MULTIPLIER, 10)

        # 1. Vector candidates
        vector_docs = vs.similarity_search(query, k=candidate_k, filter=filter) or []
        if not vector_docs:
            return []

        # 2. Keyword scores on candidates
        keyword_scores = [
            (_keyword_score(query, doc.page_content), doc) for doc in vector_docs
        ]
        keyword_scores.sort(key=lambda x: x[0], reverse=True)
        keyword_ranked = [doc for _, doc in keyword_scores if _ > 0] or []

        # If no keyword matches, fall back to pure vector ranking
        if not keyword_ranked:
            logger.debug("hybrid_no_keyword_matches", fallback="vector_only")
            return vector_docs[:k]

        # 3. RRF fusion
        fused = _reciprocal_rank_fusion(
            vector_ranked=vector_docs,
            keyword_ranked=keyword_ranked,
        )

        logger.debug(
            "hybrid_retrieval",
            query_preview=query[:60],
            candidates=len(vector_docs),
            keyword_matches=len(keyword_ranked),
            final=min(k, len(fused)),
        )
        return fused[:k]

    except Exception as exc:
        logger.warning("hybrid_retrieval_failed", error=str(exc))
        return []


# ---------------------------------------------------------------------------
# Public API — Guardrailed retrieval wrappers
# ---------------------------------------------------------------------------


def retrieve_context(query: str, k: int = 3) -> str:
    """
    Unfiltered hybrid search with guardrails.

    Returns joined page_content of safe documents only.
    """
    try:
        docs = retrieve_hybrid(query, k=k)
        safe_docs = apply_guardrails(docs, strategy="mask")
        return _join(safe_docs)
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
    Filtered hybrid search using hard-constraint metadata tags + guardrails.

    When a tag dimension is supplied (e.g. destino="Nordeste"), ChromaDB
    restricts candidates to chunks tagged with that value OR chunks with no
    tag on that dimension (="" — general knowledge content).

    Falls back to unfiltered hybrid search if the filtered result set is empty,
    preventing silent information gaps.
    """
    chroma_filter = build_chroma_filter(destino=destino, tema=tema, perfil=perfil)

    try:
        if chroma_filter:
            docs = retrieve_hybrid(query, k=k, filter=chroma_filter)
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
                docs = retrieve_hybrid(query, k=k)
        else:
            docs = retrieve_hybrid(query, k=k)

        safe_docs = apply_guardrails(docs, strategy="mask")
        return _join(safe_docs)
    except Exception as exc:
        logger.warning("rag_filtered_retrieval_failed", error=str(exc))
        return ""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _join(docs: list[Document]) -> str:
    return "\n\n".join(d.page_content for d in docs)


def _try_count(_: PGVector) -> int:
    return 0  # PGVector não expõe API pública de contagem; chunks são logados na ingestão
