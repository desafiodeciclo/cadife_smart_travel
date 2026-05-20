"""
Unit tests for DiaryService — regression: None from generate_presigned_url
must not overwrite raw S3 keys, avoiding Pydantic ValidationError → 500.
"""

import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import UploadFile

from app.services.diary_service import DiaryService


@pytest.fixture
def mock_repo():
    return MagicMock()


@pytest.fixture
def mock_lead_repo():
    return MagicMock()


@pytest.fixture
def mock_storage():
    storage = MagicMock()
    storage.upload_file = AsyncMock(return_value=True)
    storage.delete_file = AsyncMock(return_value=True)
    return storage


@pytest.fixture
def diary_service(mock_repo, mock_lead_repo, mock_storage):
    return DiaryService(mock_repo, mock_lead_repo, mock_storage)


class FakeEntry:
    def __init__(self, foto_url, thumb_url):
        self.id = uuid.uuid4()
        self.lead_id = uuid.uuid4()
        self.user_id = uuid.uuid4()
        self.foto_url = foto_url
        self.thumb_url = thumb_url
        self.nota = "Nota de teste"
        self.criado_em = datetime.now()


@pytest.mark.asyncio
async def test_list_user_timeline_presigned_none_keeps_raw_keys(diary_service, mock_repo, mock_storage):
    """Regression: S3 failure (None) must not overwrite foto_url/thumb_url."""
    raw_foto = "diary/lead-1/entry-1_original.jpg"
    raw_thumb = "diary/lead-1/entry-1_thumb.jpg"
    entry = FakeEntry(raw_foto, raw_thumb)

    mock_repo.list_by_user = AsyncMock(return_value=([entry], 1))
    mock_storage.generate_presigned_url = AsyncMock(return_value=None)

    entries, total = await diary_service.list_user_timeline(user_id=entry.user_id)

    assert total == 1
    assert entries[0].foto_url == raw_foto
    assert entries[0].thumb_url == raw_thumb


@pytest.mark.asyncio
async def test_list_entries_presigned_none_keeps_raw_keys(diary_service, mock_repo, mock_storage):
    raw_foto = "diary/lead-1/entry-1_original.jpg"
    raw_thumb = "diary/lead-1/entry-1_thumb.jpg"
    entry = FakeEntry(raw_foto, raw_thumb)

    mock_repo.list_by_lead = AsyncMock(return_value=([entry], 1))
    mock_storage.generate_presigned_url = AsyncMock(return_value=None)

    entries, total = await diary_service.list_entries(
        lead_id=entry.lead_id, user_id=entry.user_id
    )

    assert total == 1
    assert entries[0].foto_url == raw_foto
    assert entries[0].thumb_url == raw_thumb


@pytest.mark.asyncio
async def test_create_entry_presigned_none_keeps_raw_keys(diary_service, mock_repo, mock_lead_repo, mock_storage):
    raw_foto = "diary/lead-1/entry-1_original.jpg"
    raw_thumb = "diary/lead-1/entry-1_thumb.jpg"
    entry = FakeEntry(raw_foto, raw_thumb)

    from app.infrastructure.security.pii_encryption import hmac_hash
    user_phone = "+5511999999999"
    mock_lead_repo.get_by_id = AsyncMock(return_value=MagicMock(telefone_hash=hmac_hash(user_phone)))
    mock_repo.create = AsyncMock(return_value=entry)
    mock_repo.commit = AsyncMock()
    mock_storage.generate_presigned_url = AsyncMock(return_value=None)

    fake_file = MagicMock(spec=UploadFile)
    fake_file.read = AsyncMock(return_value=b"fake-image-bytes")
    fake_file.content_type = "image/jpeg"

    # Patch settings inside the module to avoid large file rejection
    import app.services.diary_service as svc
    original_max = svc.settings.DIARY_MAX_SIZE_MB
    svc.settings.DIARY_MAX_SIZE_MB = 100

    # Mock thumbnail generation to avoid needing a real image
    diary_service._generate_thumbnail = AsyncMock(return_value=b"thumb-bytes")

    try:
        result = await diary_service.create_entry(
            user_id=entry.user_id,
            user_phone=user_phone,
            lead_id=entry.lead_id,
            photo=fake_file,
        )
    finally:
        svc.settings.DIARY_MAX_SIZE_MB = original_max

    assert result.foto_url == raw_foto
    assert result.thumb_url == raw_thumb


@pytest.mark.asyncio
async def test_delete_entry_uses_raw_s3_keys(diary_service, mock_repo, mock_storage):
    """delete_entry must pass raw S3 keys to storage.delete_file, not presigned URLs."""
    raw_foto = "diary/lead-1/entry-1_original.jpg"
    raw_thumb = "diary/lead-1/entry-1_thumb.jpg"
    entry = FakeEntry(raw_foto, raw_thumb)
    entry.user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")

    mock_repo.get_by_id = AsyncMock(return_value=entry)
    mock_repo.delete = AsyncMock()
    mock_repo.commit = AsyncMock()

    await diary_service.delete_entry(entry_id=entry.id, user_id=entry.user_id)

    calls = mock_storage.delete_file.call_args_list
    keys_deleted = [call.kwargs.get("object_key") or call.args[0] for call in calls]
    assert raw_foto in keys_deleted
    assert raw_thumb in keys_deleted
