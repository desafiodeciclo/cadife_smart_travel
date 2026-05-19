"""
Modular Document Ingestion Pipeline — Cadife Tour RAG Knowledge Base.

Pipeline: DocumentLoader → TextSplitter → MetadataTagger → EmbeddingCache → VectorStore

Features:
  - Hash-based deduplication: skips re-embedding documents whose content is unchanged.
  - Multi-format support: .txt, .md, .pdf
  - Semantic metadata enrichment via MetadataTagger (Destino / Tema / Perfil tags)
  - Incremental updates: only changed/new documents are re-indexed
  - Triggerable on-demand via API endpoint (BackgroundTasks) or daily scheduler
  - Resilient cache: falha de escrita do cache NÃO quebra a ingestão
  - Processamento parcial: um arquivo com erro não para os demais
"""

import hashlib
import json
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import structlog
import tiktoken
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_postgres import PGVector
from langchain_openai import OpenAIEmbeddings

from app.core.config import get_settings
from app.services.metadata_tagger import extract_tags, tags_to_metadata, DocumentTags

logger = structlog.get_logger()

# ---------------------------------------------------------------------------
# Token-based length function (cl100k_base ≈ GPT-4/Gemini vocabulary)
# ---------------------------------------------------------------------------
_tiktoken_enc = tiktoken.get_encoding("cl100k_base")


def _token_length(text: str) -> int:
    return len(_tiktoken_enc.encode(text))


# ---------------------------------------------------------------------------
# Splitter version — bump this whenever chunk_size, overlap, or
# length_function changes so the hash-based cache detects the config drift
# and forces automatic re-indexing of all documents.
# ---------------------------------------------------------------------------
_SPLITTER_VERSION = "v2_chunk500_overlap50_tiktoken"

# ---------------------------------------------------------------------------
# Text splitter — 500 tokens / 50-token overlap (spec: 300–500 tokens)
# ---------------------------------------------------------------------------
_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    length_function=_token_length,
    separators=["\n\n", "\n", ". ", " ", ""],
)


# ---------------------------------------------------------------------------
# Cache schema
# {
#   "filename.txt": {
#     "hash": "sha256:abc...",
#     "chunk_ids": ["id1", "id2", ...],
#     "indexed_at": "2026-04-25T10:00:00Z",
#     "chunk_count": 12
#   }
# }
# ---------------------------------------------------------------------------


class IngestionCache:
    """
    Cache de ingestão baseado em hash — resiliente a falhas de I/O.

    Regra de Ouro: falha ao salvar o cache NUNCA quebra a ingestão.
    O arquivo de documentos sempre será processado; o cache é auxiliar.
    O diretório pai é criado automaticamente se não existir.
    """

    def __init__(self, cache_path: str) -> None:
        self._path = Path(cache_path)
        self._data: dict[str, dict] = {}
        self._writable: bool = True  # pessimistically overridden on first failure
        self._load()

    def _ensure_dir(self) -> bool:
        """Garante que o diretório pai existe. Retorna True se ok, False se falhou."""
        try:
            self._path.parent.mkdir(parents=True, exist_ok=True)
            return True
        except Exception as exc:
            logger.warning(
                "ingestion_cache_dir_create_failed",
                path=str(self._path.parent),
                error=str(exc),
            )
            return False

    def _load(self) -> None:
        try:
            exists = self._path.exists()
        except PermissionError as exc:
            self._writable = False
            logger.warning(
                "ingestion_cache_permission_denied_on_check",
                path=str(self._path),
                error=str(exc),
                action="cache_disabled_ingestion_continues",
            )
            return
        except Exception as exc:
            logger.warning(
                "ingestion_cache_exists_check_failed",
                path=str(self._path),
                error=str(exc),
            )
            return

        if not exists:
            logger.debug("ingestion_cache_not_found", path=str(self._path))
            return
        try:
            raw = self._path.read_text(encoding="utf-8")
            self._data = json.loads(raw)
            logger.info(
                "ingestion_cache_loaded",
                path=str(self._path),
                documents=len(self._data),
                total_chunks=sum(e.get("chunk_count", 0) for e in self._data.values()),
            )
        except json.JSONDecodeError as exc:
            logger.warning(
                "ingestion_cache_corrupted",
                path=str(self._path),
                error=str(exc),
                action="starting_fresh",
            )
            self._data = {}
        except PermissionError as exc:
            self._writable = False
            logger.warning(
                "ingestion_cache_permission_denied_on_read",
                path=str(self._path),
                error=str(exc),
                action="cache_disabled_ingestion_continues",
            )
        except Exception as exc:
            logger.warning(
                "ingestion_cache_load_failed",
                path=str(self._path),
                error=str(exc),
                action="starting_fresh",
            )
            self._data = {}

    def _save(self) -> None:
        """Persiste cache. Falha é silenciosa (warning) — não propaga exceção."""
        if not self._writable:
            return
        if not self._ensure_dir():
            self._writable = False
            logger.warning(
                "ingestion_cache_disabled",
                reason="directory_not_writable",
                path=str(self._path),
            )
            return
        try:
            # Escrita atômica via arquivo temporário para evitar corrupção
            tmp_path = self._path.with_suffix(".tmp")
            tmp_path.write_text(
                json.dumps(self._data, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            tmp_path.replace(self._path)
        except PermissionError as exc:
            self._writable = False
            logger.warning(
                "ingestion_cache_permission_denied",
                path=str(self._path),
                error=str(exc),
                action="cache_disabled_ingestion_continues",
            )
        except Exception as exc:
            logger.warning(
                "ingestion_cache_save_failed",
                path=str(self._path),
                error=str(exc),
                action="ingestion_continues_without_cache_update",
            )

    def get(self, filename: str) -> Optional[dict]:
        return self._data.get(filename)

    def put(self, filename: str, doc_hash: str, chunk_ids: list[str]) -> None:
        self._data[filename] = {
            "hash": doc_hash,
            "chunk_ids": chunk_ids,
            "indexed_at": datetime.now(timezone.utc).isoformat(),
            "chunk_count": len(chunk_ids),
        }
        self._save()

    def remove(self, filename: str) -> None:
        self._data.pop(filename, None)
        self._save()

    def all_entries(self) -> dict[str, dict]:
        return dict(self._data)

    def is_writable(self) -> bool:
        return self._writable

    def summary(self) -> dict:
        total_chunks = sum(e.get("chunk_count", 0) for e in self._data.values())
        return {
            "indexed_documents": len(self._data),
            "total_chunks": total_chunks,
            "cache_path": str(self._path),
            "cache_writable": self._writable,
            "documents": [
                {
                    "filename": k,
                    "hash": v["hash"][:16] + "...",
                    "chunk_count": v["chunk_count"],
                    "indexed_at": v["indexed_at"],
                }
                for k, v in self._data.items()
            ],
        }


# ---------------------------------------------------------------------------
# Document loaders
# ---------------------------------------------------------------------------


def _load_txt(filepath: Path) -> str:
    return filepath.read_text(encoding="utf-8")


def _load_md(filepath: Path) -> str:
    return filepath.read_text(encoding="utf-8")


def _load_pdf(filepath: Path) -> str:
    try:
        from pypdf import PdfReader  # optional dependency

        reader = PdfReader(str(filepath))
        pages_text = []
        for i, page in enumerate(reader.pages):
            try:
                text = page.extract_text() or ""
                if text.strip():
                    pages_text.append(text)
            except Exception as exc:
                logger.warning(
                    "pdf_page_extract_failed",
                    filepath=str(filepath),
                    page=i,
                    error=str(exc),
                )
        return "\n\n".join(pages_text)
    except ImportError:
        logger.warning("pypdf_not_installed", filepath=str(filepath))
        return ""
    except Exception as exc:
        logger.error("pdf_load_failed", filepath=str(filepath), error=str(exc))
        return ""


_LOADERS: dict[str, callable] = {
    ".txt": _load_txt,
    ".md": _load_md,
    ".pdf": _load_pdf,
}

SUPPORTED_EXTENSIONS = set(_LOADERS.keys())


def _compute_hash(content: str) -> str:
    versioned = f"{_SPLITTER_VERSION}:{content}"
    return "sha256:" + hashlib.sha256(versioned.encode("utf-8")).hexdigest()


def _read_file(filepath: Path) -> Optional[str]:
    loader = _LOADERS.get(filepath.suffix.lower())
    if loader is None:
        return None
    try:
        content = loader(filepath)
        # Garante que retorna string mesmo se loader retornar None
        if content is None:
            logger.warning("file_loader_returned_none", filepath=str(filepath))
            return None
        return content if isinstance(content, str) else str(content)
    except Exception as exc:
        logger.error(
            "file_read_error",
            filepath=str(filepath),
            error=str(exc),
            error_type=type(exc).__name__,
        )
        return None


def _safe_split(content: str, filename: str) -> list[str]:
    """Divide o conteúdo em chunks com tolerância a falhas."""
    if not content or not content.strip():
        logger.warning("file_empty_content", filename=filename)
        return []
    try:
        chunks = _splitter.split_text(content)
        # Garante que split_text nunca retorna None
        if chunks is None:
            logger.warning("splitter_returned_none", filename=filename)
            return []
        return [c for c in chunks if c and c.strip()]
    except Exception as exc:
        logger.error(
            "text_split_failed",
            filename=filename,
            error=str(exc),
            content_len=len(content),
        )
        return []


def _safe_extract_tags(chunk: str, filename: str) -> DocumentTags:
    """Extrai tags com fallback para DocumentTags vazio em caso de erro."""
    try:
        tags = extract_tags(chunk, filename)
        if tags is None:
            logger.warning("extract_tags_returned_none", filename=filename)
            return DocumentTags()
        return tags
    except Exception as exc:
        logger.warning(
            "extract_tags_failed",
            filename=filename,
            error=str(exc),
        )
        return DocumentTags()


# ---------------------------------------------------------------------------
# Core pipeline
# ---------------------------------------------------------------------------


class IngestionPipeline:
    """
    Manages incremental re-ingestion of the Cadife Tour knowledge base.

    Resiliência:
      - Falha em um arquivo não para os demais.
      - Falha no cache não para a ingestão.
      - Erros de embedding de chunk individual são logados e pulados.
      - Métricas detalhadas por arquivo e por execução.

    Thread-safety: not thread-safe; designed to run as a single background task.
    """

    def __init__(
        self,
        knowledge_base_dir: str,
        pgvector_connection: str,
        cache_path: str,
        openrouter_api_key: str = "",
        embedding_model: str = "google/gemini-embedding-2-preview",
    ) -> None:
        self._kb_dir = Path(knowledge_base_dir)
        self._pgvector_connection = pgvector_connection
        self._cache = IngestionCache(cache_path)
        if not openrouter_api_key:
            raise RuntimeError("Nenhuma OPENROUTER_API_KEY configurada para ingestão.")
        self._embeddings = OpenAIEmbeddings(
            model=embedding_model,
            openai_api_key=openrouter_api_key,
            openai_api_base="https://openrouter.ai/api/v1",
            check_embedding_ctx_length=False,
            model_kwargs={"encoding_format": "float"},
        )
        self._vectorstore: Optional[PGVector] = None

    # ------------------------------------------------------------------
    # Vectorstore accessor — lazy init
    # ------------------------------------------------------------------

    def _get_vectorstore(self) -> PGVector:
        if self._vectorstore is None:
            self._vectorstore = PGVector(
                embeddings=self._embeddings,
                collection_name="cadife_knowledge_base",
                connection=self._pgvector_connection,
                use_jsonb=True,
            )
        return self._vectorstore

    def _invalidate_vectorstore(self) -> None:
        """Force re-open after bulk deletions."""
        self._vectorstore = None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def ingest_all(self, force: bool = False) -> dict:
        """
        Run incremental ingestion over the entire knowledge base directory.

        Args:
            force: If True, re-indexes all documents even if unchanged.

        Returns:
            Summary dict with counts of processed/skipped/failed files.
        """
        run_start = time.monotonic()

        if not self._kb_dir.exists():
            logger.warning("knowledge_base_dir_missing", path=str(self._kb_dir))
            return {
                "status": "error",
                "detail": "knowledge_base_dir not found",
                "path": str(self._kb_dir),
            }

        results: dict = {
            "processed": 0,
            "skipped": 0,
            "failed": 0,
            "removed": 0,
            "total_chunks_indexed": 0,
            "total_chunks_removed": 0,
            "failed_files": [],
            "cache_writable": self._cache.is_writable(),
        }

        try:
            current_files = {
                f.name
                for f in self._kb_dir.iterdir()
                if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
            }
        except Exception as exc:
            logger.error(
                "knowledge_base_dir_scan_failed",
                path=str(self._kb_dir),
                error=str(exc),
            )
            return {"status": "error", "detail": f"directory scan failed: {exc}"}

        logger.info(
            "ingestion_started",
            kb_dir=str(self._kb_dir),
            files_found=len(current_files),
            force=force,
            cache_writable=self._cache.is_writable(),
        )

        # Remove chunks for files deleted from disk
        for cached_name in list(self._cache.all_entries().keys()):
            if cached_name not in current_files:
                removed_chunks = await self._remove_document(cached_name)
                results["removed"] += 1
                results["total_chunks_removed"] += removed_chunks

        # Ingest new / changed files
        for filename in sorted(current_files):
            filepath = self._kb_dir / filename
            file_start = time.monotonic()
            try:
                ok, chunks_count = await self._ingest_file(filepath, force=force)
            except Exception as exc:
                # Catch-all: erros inesperados não devem parar o loop
                logger.error(
                    "ingestion_file_unexpected_error",
                    filename=filename,
                    error=str(exc),
                    error_type=type(exc).__name__,
                )
                ok = False
                chunks_count = 0

            elapsed_ms = int((time.monotonic() - file_start) * 1000)

            if ok is True:
                results["processed"] += 1
                results["total_chunks_indexed"] += chunks_count
                logger.info(
                    "file_ingested",
                    filename=filename,
                    chunks=chunks_count,
                    elapsed_ms=elapsed_ms,
                )
            elif ok is False:
                results["failed"] += 1
                results["failed_files"].append(filename)
                logger.error(
                    "file_ingestion_failed",
                    filename=filename,
                    elapsed_ms=elapsed_ms,
                )
            else:
                results["skipped"] += 1
                logger.debug(
                    "file_skipped_cache_hit",
                    filename=filename,
                    elapsed_ms=elapsed_ms,
                )

        elapsed_total_s = round(time.monotonic() - run_start, 2)
        results["elapsed_seconds"] = elapsed_total_s

        if results["failed"] > 0 and results["processed"] == 0:
            status = "failed"
        elif results["failed"] > 0:
            status = "degraded"
        else:
            status = "ok"

        results["status"] = status

        logger.info(
            "ingestion_complete",
            status=status,
            processed=results["processed"],
            skipped=results["skipped"],
            failed=results["failed"],
            removed=results["removed"],
            total_chunks_indexed=results["total_chunks_indexed"],
            elapsed_seconds=elapsed_total_s,
            failed_files=results["failed_files"] if results["failed_files"] else None,
        )
        return results

    async def ingest_file(self, filepath: str | Path, force: bool = False) -> dict:
        """Ingest a single file by path."""
        path = Path(filepath)
        file_start = time.monotonic()
        try:
            ok, chunks_count = await self._ingest_file(path, force=force)
        except Exception as exc:
            logger.error(
                "ingest_file_unexpected_error",
                filepath=str(path),
                error=str(exc),
            )
            ok = False
            chunks_count = 0

        elapsed_ms = int((time.monotonic() - file_start) * 1000)
        status = "processed" if ok is True else ("failed" if ok is False else "skipped")
        return {"status": status, "file": path.name, "chunks": chunks_count, "elapsed_ms": elapsed_ms}

    def get_status(self) -> dict:
        """Return current ingestion cache summary."""
        return self._cache.summary()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _ingest_file(self, filepath: Path, force: bool) -> tuple[Optional[bool], int]:
        """
        Returns:
            (True, chunks)   — file was processed (new or changed)
            (None, 0)        — file skipped (unchanged, cache hit)
            (False, 0)       — error during processing
        """
        content = _read_file(filepath)
        if content is None:
            logger.error(
                "file_read_returned_none",
                filename=filepath.name,
                action="skipping",
            )
            return False, 0

        if not content.strip():
            logger.warning(
                "file_empty_after_read",
                filename=filepath.name,
                action="skipping",
            )
            return False, 0

        doc_hash = _compute_hash(content)
        filename = filepath.name
        cached = self._cache.get(filename)

        if not force and cached and cached.get("hash") == doc_hash:
            logger.debug("ingestion_cache_hit", filename=filename)
            return None, 0  # skip

        # Delete stale chunks if re-indexing
        if cached:
            await self._remove_document(filename)

        chunks = _safe_split(content, filename)
        if not chunks:
            logger.warning(
                "no_chunks_generated",
                filename=filename,
                content_length=len(content),
            )
            return False, 0

        logger.debug(
            "chunks_generated",
            filename=filename,
            chunk_count=len(chunks),
            avg_chunk_len=int(sum(len(c) for c in chunks) / len(chunks)),
        )

        documents: list[Document] = []
        for i, chunk in enumerate(chunks):
            if not chunk or not chunk.strip():
                continue
            tags = _safe_extract_tags(chunk, filename)
            metadata = tags_to_metadata(tags, filename, i, doc_hash)
            documents.append(Document(page_content=chunk, metadata=metadata))

        if not documents:
            logger.warning(
                "no_documents_after_filtering",
                filename=filename,
                raw_chunks=len(chunks),
            )
            return False, 0

        try:
            vs = self._get_vectorstore()
            ids = vs.add_documents(documents)
            # Garante que ids seja sempre uma lista iterável
            if ids is None:
                ids = []
            self._cache.put(filename, doc_hash, ids)
            logger.info(
                "document_indexed",
                filename=filename,
                chunks=len(documents),
                embedding_ids=len(ids),
                hash_prefix=doc_hash[:20],
                cache_updated=self._cache.is_writable(),
            )
            return True, len(documents)
        except Exception as exc:
            logger.error(
                "vectorstore_add_failed",
                filename=filename,
                document_count=len(documents),
                error=str(exc),
                error_type=type(exc).__name__,
            )
            return False, 0

    async def _remove_document(self, filename: str) -> int:
        """Remove chunks do vectorstore. Retorna número de chunks removidos."""
        cached = self._cache.get(filename)
        if not cached:
            return 0
        chunk_ids: list[str] = cached.get("chunk_ids") or []
        removed = 0
        if chunk_ids:
            try:
                vs = self._get_vectorstore()
                vs.delete(ids=chunk_ids)
                self._invalidate_vectorstore()
                removed = len(chunk_ids)
                logger.info(
                    "document_removed",
                    filename=filename,
                    chunks=removed,
                )
            except Exception as exc:
                logger.warning(
                    "document_remove_error",
                    filename=filename,
                    chunk_ids_count=len(chunk_ids),
                    error=str(exc),
                )
        self._cache.remove(filename)
        return removed


# ---------------------------------------------------------------------------
# Module-level singleton — shared with rag_service and routes
# ---------------------------------------------------------------------------

_pipeline: Optional[IngestionPipeline] = None


def get_ingestion_pipeline() -> IngestionPipeline:
    global _pipeline
    if _pipeline is None:
        settings = get_settings()
        _pipeline = IngestionPipeline(
            knowledge_base_dir=settings.KNOWLEDGE_BASE_DIR,
            pgvector_connection=settings.PGVECTOR_CONNECTION_STRING,
            cache_path=settings.INGESTION_CACHE_PATH,
            openrouter_api_key=settings.OPENROUTER_API_KEY,
            embedding_model=settings.OPENROUTER_EMBEDDING_MODEL,
        )
    return _pipeline
