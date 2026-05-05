"""
Unit tests for ingestion_pipeline.py.

All external I/O (ChromaDB, OpenAI embeddings) is mocked.
"""
import json
import tempfile
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.ingestion_pipeline import IngestionCache, IngestionPipeline


# ---------------------------------------------------------------------------
# IngestionCache tests
# ---------------------------------------------------------------------------

class TestIngestionCache:
    def test_empty_on_missing_file(self, tmp_path):
        cache = IngestionCache(str(tmp_path / "cache.json"))
        assert cache.get("any.txt") is None

    def test_put_and_get(self, tmp_path):
        cache = IngestionCache(str(tmp_path / "cache.json"))
        cache.put("doc.txt", "sha256:abc", ["id1", "id2"])
        entry = cache.get("doc.txt")
        assert entry is not None
        assert entry["hash"] == "sha256:abc"
        assert entry["chunk_ids"] == ["id1", "id2"]
        assert entry["chunk_count"] == 2

    def test_persists_to_disk(self, tmp_path):
        path = str(tmp_path / "cache.json")
        cache = IngestionCache(path)
        cache.put("doc.txt", "sha256:abc", ["id1"])

        # Reload from disk
        cache2 = IngestionCache(path)
        assert cache2.get("doc.txt") is not None

    def test_remove_deletes_entry(self, tmp_path):
        cache = IngestionCache(str(tmp_path / "cache.json"))
        cache.put("doc.txt", "sha256:abc", ["id1"])
        cache.remove("doc.txt")
        assert cache.get("doc.txt") is None

    def test_summary_counts_correctly(self, tmp_path):
        cache = IngestionCache(str(tmp_path / "cache.json"))
        cache.put("a.txt", "sha256:aaa", ["id1", "id2"])
        cache.put("b.txt", "sha256:bbb", ["id3"])
        summary = cache.summary()
        assert summary["indexed_documents"] == 2
        assert summary["total_chunks"] == 3

    def test_corrupt_cache_file_resets_gracefully(self, tmp_path):
        path = tmp_path / "cache.json"
        path.write_text("{ not valid json }", encoding="utf-8")
        cache = IngestionCache(str(path))  # should not raise
        assert cache.summary()["indexed_documents"] == 0


# ---------------------------------------------------------------------------
# IngestionPipeline tests
# ---------------------------------------------------------------------------

def _make_pipeline(tmp_path: Path) -> IngestionPipeline:
    kb_dir = tmp_path / "knowledge_base"
    kb_dir.mkdir()
    chroma_dir = str(tmp_path / "chroma")
    cache_path = str(tmp_path / "cache.json")

    with patch("app.services.ingestion_pipeline.GoogleGenerativeAIEmbeddings"):
        pipeline = IngestionPipeline(
            knowledge_base_dir=str(kb_dir),
            chroma_persist_dir=chroma_dir,
            cache_path=cache_path,
            gemini_api_key="test-key",
        )
    return pipeline, kb_dir


@pytest.fixture
def pipeline_with_kb(tmp_path):
    pipeline, kb_dir = _make_pipeline(tmp_path)
    return pipeline, kb_dir


class TestIngestionPipeline:
    @pytest.mark.asyncio
    async def test_ingest_all_missing_dir_returns_error(self, tmp_path):
        with patch("app.services.ingestion_pipeline.GoogleGenerativeAIEmbeddings"):
            pipeline = IngestionPipeline(
                knowledge_base_dir=str(tmp_path / "nonexistent"),
                chroma_persist_dir=str(tmp_path / "chroma"),
                cache_path=str(tmp_path / "cache.json"),
                gemini_api_key="test-key",
            )
        result = await pipeline.ingest_all()
        assert result["status"] == "error"

    @pytest.mark.asyncio
    async def test_ingest_new_txt_file(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        (kb_dir / "nordeste.txt").write_text(
            "Natal é um dos melhores destinos do Nordeste.",
            encoding="utf-8",
        )

        mock_vs = MagicMock()
        mock_vs.add_documents.return_value = ["id1"]
        pipeline._vectorstore = mock_vs

        result = await pipeline.ingest_all()
        assert result["processed"] == 1
        assert result["skipped"] == 0
        mock_vs.add_documents.assert_called_once()

    @pytest.mark.asyncio
    async def test_skips_unchanged_document(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        content = "Natal é um destino do Nordeste."
        (kb_dir / "nordeste.txt").write_text(content, encoding="utf-8")

        mock_vs = MagicMock()
        mock_vs.add_documents.return_value = ["id1"]
        pipeline._vectorstore = mock_vs

        # First ingest
        await pipeline.ingest_all()
        mock_vs.add_documents.reset_mock()

        # Second ingest — same content
        result = await pipeline.ingest_all()
        assert result["skipped"] == 1
        assert result["processed"] == 0
        mock_vs.add_documents.assert_not_called()

    @pytest.mark.asyncio
    async def test_reindexes_changed_document(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        doc = kb_dir / "nordeste.txt"
        doc.write_text("Conteúdo original.", encoding="utf-8")

        mock_vs = MagicMock()
        mock_vs.add_documents.return_value = ["id1"]
        mock_collection = MagicMock()
        mock_vs._collection = mock_collection
        pipeline._vectorstore = mock_vs

        await pipeline.ingest_all()

        # Modify document
        doc.write_text("Conteúdo atualizado com novas informações.", encoding="utf-8")
        mock_vs.add_documents.reset_mock()

        result = await pipeline.ingest_all()
        assert result["processed"] == 1
        mock_collection.delete.assert_called_once()

    @pytest.mark.asyncio
    async def test_removes_deleted_document_from_cache(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        doc = kb_dir / "removido.txt"
        doc.write_text("Será removido.", encoding="utf-8")

        mock_vs = MagicMock()
        mock_vs.add_documents.return_value = ["id1"]
        mock_collection = MagicMock()
        mock_vs._collection = mock_collection
        pipeline._vectorstore = mock_vs

        await pipeline.ingest_all()
        assert pipeline._cache.get("removido.txt") is not None

        doc.unlink()
        await pipeline.ingest_all()
        assert pipeline._cache.get("removido.txt") is None

    @pytest.mark.asyncio
    async def test_force_reindexes_all(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        (kb_dir / "doc.txt").write_text("Conteúdo.", encoding="utf-8")

        mock_vs = MagicMock()
        mock_vs.add_documents.return_value = ["id1"]
        mock_collection = MagicMock()
        mock_vs._collection = mock_collection

        # Patch _get_vectorstore so the mock survives _invalidate_vectorstore()
        # calls inside _remove_document (which resets self._vectorstore = None).
        with patch.object(pipeline, "_get_vectorstore", return_value=mock_vs):
            await pipeline.ingest_all()
            mock_vs.add_documents.reset_mock()

            result = await pipeline.ingest_all(force=True)

        assert result["processed"] == 1
        mock_vs.add_documents.assert_called_once()

    def test_get_status_returns_summary(self, pipeline_with_kb):
        pipeline, _ = pipeline_with_kb
        status = pipeline.get_status()
        assert "indexed_documents" in status
        assert "total_chunks" in status

    # ------------------------------------------------------------------
    # Splitter configuration tests
    # ------------------------------------------------------------------

    def test_splitter_chunk_size_is_500(self):
        from app.services.ingestion_pipeline import _splitter
        assert _splitter._chunk_size == 500

    def test_splitter_overlap_is_50(self):
        from app.services.ingestion_pipeline import _splitter
        assert _splitter._chunk_overlap == 50

    def test_splitter_uses_token_length_function(self):
        from app.services.ingestion_pipeline import _token_length, _splitter
        assert _splitter._length_function is _token_length

    def test_token_length_counts_tokens_not_chars(self):
        from app.services.ingestion_pipeline import _token_length
        # "hello world" = 2 tokens but 11 characters
        assert _token_length("hello world") < 11

    def test_splitter_version_in_hash_differs_from_raw(self):
        import hashlib
        from app.services.ingestion_pipeline import _compute_hash
        content = "Natal é um destino do Nordeste."
        versioned_hash = _compute_hash(content)
        raw_hash = "sha256:" + hashlib.sha256(content.encode("utf-8")).hexdigest()
        assert versioned_hash != raw_hash

    def test_hash_is_deterministic(self):
        from app.services.ingestion_pipeline import _compute_hash
        content = "Natal é um destino do Nordeste."
        assert _compute_hash(content) == _compute_hash(content)

    @pytest.mark.asyncio
    async def test_unsupported_extension_ignored(self, pipeline_with_kb):
        pipeline, kb_dir = pipeline_with_kb
        (kb_dir / "ignore.csv").write_text("col1,col2", encoding="utf-8")

        mock_vs = MagicMock()
        pipeline._vectorstore = mock_vs

        result = await pipeline.ingest_all()
        assert result["processed"] == 0
        mock_vs.add_documents.assert_not_called()
