"""
Modular Document Ingestion Pipeline — Cadife Tour RAG Knowledge Base.

Pipeline: DocumentLoader → TextSplitter → MetadataTagger → EmbeddingCache → VectorStore

Features:
  - Hash-based deduplication: skips re-embedding documents whose content is unchanged.
  - Multi-format support: .txt, .md, .pdf
  - Semantic metadata enrichment via MetadataTagger (Destino / Tema / Perfil tags)
  - Incremental updates: only changed/new documents are re-indexed
  - Triggerable on-demand via API endpoint (BackgroundTasks) or daily scheduler
"""
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import structlog
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_chroma import Chroma
from langchain_google_genai import GoogleGenerativeAIEmbeddings

from pydantic import SecretStr

from app.core.config import get_settings
from app.services.metadata_tagger import extract_tags, tags_to_metadata

logger = structlog.get_logger()

# ---------------------------------------------------------------------------
# Text splitter — matches .claude/rules/ai_langchain.md spec
# ---------------------------------------------------------------------------
_splitter = RecursiveCharacterTextSplitter(
    chunk_size=400,
    chunk_overlap=50,
    length_function=len,
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
    def __init__(self, cache_path: str) -> None:
        self._path = Path(cache_path)
        self._data: dict[str, dict] = {}
        self._load()

    def _load(self) -> None:
        if self._path.exists():
            try:
                self._data = json.loads(self._path.read_text(encoding="utf-8"))
            except Exception:
                self._data = {}

    def _save(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(
            json.dumps(self._data, indent=2, ensure_ascii=False),
            encoding="utf-8",
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

    def summary(self) -> dict:
        total_chunks = sum(e.get("chunk_count", 0) for e in self._data.values())
        return {
            "indexed_documents": len(self._data),
            "total_chunks": total_chunks,
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
        return "\n\n".join(page.extract_text() or "" for page in reader.pages)
    except ImportError:
        logger.warning("pypdf_not_installed", filepath=str(filepath))
        return ""


_LOADERS: dict[str, callable] = {
    ".txt": _load_txt,
    ".md": _load_md,
    ".pdf": _load_pdf,
}

SUPPORTED_EXTENSIONS = set(_LOADERS.keys())


def _compute_hash(content: str) -> str:
    return "sha256:" + hashlib.sha256(content.encode("utf-8")).hexdigest()


def _read_file(filepath: Path) -> Optional[str]:
    loader = _LOADERS.get(filepath.suffix.lower())
    if loader is None:
        return None
    try:
        return loader(filepath)
    except Exception as exc:
        logger.error("file_read_error", filepath=str(filepath), error=str(exc))
        return None


# ---------------------------------------------------------------------------
# Core pipeline
# ---------------------------------------------------------------------------

class IngestionPipeline:
    """
    Manages incremental re-ingestion of the Cadife Tour knowledge base.

    Thread-safety: not thread-safe; designed to run as a single background task.
    """

    def __init__(
        self,
        knowledge_base_dir: str,
        chroma_persist_dir: str,
        cache_path: str,
        gemini_api_key: str = "",
    ) -> None:
        self._kb_dir = Path(knowledge_base_dir)
        self._persist_dir = chroma_persist_dir
        self._cache = IngestionCache(cache_path)
        # Gemini embeddings exclusivo
        if gemini_api_key:
            self._embeddings = GoogleGenerativeAIEmbeddings(
                model="models/gemini-embedding-001",
                google_api_key=SecretStr(gemini_api_key),
            )
        else:
            raise RuntimeError("Nenhuma GEMINI_API_KEY configurada para ingestão.")
        self._vectorstore: Optional[Chroma] = None

    # ------------------------------------------------------------------
    # Vectorstore accessor — lazy init
    # ------------------------------------------------------------------

    def _get_vectorstore(self) -> Chroma:
        if self._vectorstore is None:
            self._vectorstore = Chroma(
                persist_directory=self._persist_dir,
                embedding_function=self._embeddings,
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
        if not self._kb_dir.exists():
            logger.warning("knowledge_base_dir_missing", path=str(self._kb_dir))
            return {"status": "error", "detail": "knowledge_base_dir not found"}

        results = {"processed": 0, "skipped": 0, "failed": 0, "removed": 0}

        current_files = {
            f.name
            for f in self._kb_dir.iterdir()
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
        }

        # Remove chunks for files deleted from disk
        for cached_name in list(self._cache.all_entries().keys()):
            if cached_name not in current_files:
                await self._remove_document(cached_name)
                results["removed"] += 1

        # Ingest new / changed files
        for filename in sorted(current_files):
            filepath = self._kb_dir / filename
            ok = await self._ingest_file(filepath, force=force)
            if ok is True:
                results["processed"] += 1
            elif ok is False:
                results["failed"] += 1
            else:
                results["skipped"] += 1

        logger.info("ingestion_complete", **results)
        return {"status": "ok", **results}

    async def ingest_file(self, filepath: str | Path, force: bool = False) -> dict:
        """Ingest a single file by path."""
        path = Path(filepath)
        ok = await self._ingest_file(path, force=force)
        status = "processed" if ok is True else ("failed" if ok is False else "skipped")
        return {"status": status, "file": path.name}

    def get_status(self) -> dict:
        """Return current ingestion cache summary."""
        return self._cache.summary()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    async def _ingest_file(self, filepath: Path, force: bool) -> Optional[bool]:
        """
        Returns:
            True  — file was processed (new or changed)
            None  — file skipped (unchanged, cache hit)
            False — error during processing
        """
        content = _read_file(filepath)
        if content is None:
            return False

        doc_hash = _compute_hash(content)
        filename = filepath.name
        cached = self._cache.get(filename)

        if not force and cached and cached.get("hash") == doc_hash:
            logger.debug("ingestion_cache_hit", filename=filename)
            return None  # skip

        # Delete stale chunks if re-indexing
        if cached:
            await self._remove_document(filename)

        chunks = _splitter.split_text(content)
        if not chunks:
            logger.warning("empty_chunks", filename=filename)
            return False

        documents: list[Document] = []
        for i, chunk in enumerate(chunks):
            tags = extract_tags(chunk, filename)
            metadata = tags_to_metadata(tags, filename, i, doc_hash)
            documents.append(Document(page_content=chunk, metadata=metadata))

        try:
            vs = self._get_vectorstore()
            ids = vs.add_documents(documents)
            self._cache.put(filename, doc_hash, ids)
            logger.info(
                "document_indexed",
                filename=filename,
                chunks=len(documents),
                hash=doc_hash[:20],
            )
            return True
        except Exception as exc:
            logger.error("ingestion_error", filename=filename, error=str(exc))
            return False

    async def _remove_document(self, filename: str) -> None:
        cached = self._cache.get(filename)
        if not cached:
            return
        chunk_ids: list[str] = cached.get("chunk_ids", [])
        if chunk_ids:
            try:
                vs = self._get_vectorstore()
                vs._collection.delete(ids=chunk_ids)
                self._invalidate_vectorstore()
                logger.info("document_removed", filename=filename, chunks=len(chunk_ids))
            except Exception as exc:
                logger.warning("document_remove_error", filename=filename, error=str(exc))
        self._cache.remove(filename)


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
            chroma_persist_dir=settings.CHROMA_PERSIST_DIR,
            cache_path=settings.INGESTION_CACHE_PATH,
            gemini_api_key=settings.GEMINI_API_KEY,
        )
    return _pipeline
