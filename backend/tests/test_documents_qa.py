import uuid
import pytest
from unittest.mock import AsyncMock, patch
from fastapi import status

from app.domain.entities.enums import DocumentoCategoria, LeadStatus
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.user_model import UserModel
from app.models import Documento
from app.models.user import UserPerfil
from app.infrastructure.security.dependencies import get_current_user

from main import app as fastapi_app

# Valid magic-byte prefixes for test files
_FAKE_PDF = b"%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n>>\nendobj\n"
_FAKE_JPEG = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"


@pytest.fixture
async def sample_lead(db_session):
    """Fixture to create a sample lead and ensure mock user exists."""
    mock_user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    user_exists = await db_session.get(UserModel, mock_user_id)
    if not user_exists:
        mock_user = UserModel(
            id=mock_user_id,
            nome="Admin Test",
            email="admin@test.com",
            hashed_password="pw",
            perfil="admin",
            is_active=True
        )
        db_session.add(mock_user)

    lead = LeadModel(
        id=uuid.uuid4(),
        nome="Cliente QA Teste",
        telefone="+5511999999999",
        telefone_hash="hash_teste_qa",
        status=LeadStatus.novo
    )
    db_session.add(lead)
    await db_session.commit()
    await db_session.refresh(lead)
    return lead


@pytest.fixture
async def sample_document(db_session, sample_lead):
    """Fixture to create a sample document for testing."""
    doc = Documento(
        id=uuid.uuid4(),
        lead_id=sample_lead.id,
        nome="voucher_teste.pdf",
        s3_key="documents/test/voucher_teste.pdf",
        categoria=DocumentoCategoria.voucher.value,
        tamanho_bytes=2048,
        mimetype="application/pdf"
    )
    db_session.add(doc)
    await db_session.commit()
    await db_session.refresh(doc)
    return doc


@pytest.mark.asyncio
async def test_upload_document_success(async_client, sample_lead):
    """CT-04: Validate upload success and push notification trigger."""
    with patch("app.services.documento_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.documento_service.S3StorageAdapter.delete_file", new_callable=AsyncMock) as mock_delete, \
         patch("app.services.documento_service.send_push_notification", new_callable=AsyncMock) as mock_push:
        mock_upload.return_value = True
        mock_delete.return_value = True
        mock_push.return_value = True

        payload = {"categoria": "voucher"}
        files = {"file": ("passagem.pdf", _FAKE_PDF, "application/pdf")}

        response = await async_client.post(
            f"/leads/{str(sample_lead.id)}/documents",
            data=payload,
            files=files
        )

        assert response.status_code == status.HTTP_201_CREATED, response.text
        data = response.json()
        assert data["nome"] == "passagem.pdf"
        assert data["categoria"] == "voucher"

        mock_upload.assert_called_once()
        mock_push.assert_called_once()


@pytest.mark.asyncio
async def test_upload_invalid_type_error(async_client, sample_lead):
    """CT-01: System must block forbidden formats (e.g. .exe)."""
    files = {"file": ("virus.exe", b"executable content", "application/x-msdownload")}
    payload = {"categoria": "outros"}

    response = await async_client.post(
        f"/leads/{str(sample_lead.id)}/documents",
        data=payload,
        files=files
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST, response.text
    assert "Tipo de arquivo não permitido" in response.json()["detail"]


@pytest.mark.asyncio
async def test_upload_file_too_large_error(async_client, sample_lead):
    """CT-01: System must block files larger than 10MB."""
    large_content = b"%PDF" + b"0" * (11 * 1024 * 1024)
    files = {"file": ("too_heavy.pdf", large_content, "application/pdf")}
    payload = {"categoria": "outros"}

    response = await async_client.post(
        f"/leads/{str(sample_lead.id)}/documents",
        data=payload,
        files=files
    )
    assert response.status_code == status.HTTP_413_CONTENT_TOO_LARGE, response.text


@pytest.mark.asyncio
async def test_upload_magic_bytes_mismatch(async_client, sample_lead):
    """CT-01: System must block files with spoofed Content-Type (magic bytes mismatch)."""
    # Sends an .exe claiming to be a PDF
    files = {"file": ("spoofed.pdf", b"MZ\x90\x00\x03\x00\x00\x00", "application/pdf")}
    payload = {"categoria": "outros"}

    response = await async_client.post(
        f"/leads/{str(sample_lead.id)}/documents",
        data=payload,
        files=files
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST, response.text
    assert "Conteúdo do arquivo não corresponde" in response.json()["detail"]


@pytest.mark.asyncio
async def test_upload_filename_sanitization(async_client, sample_lead):
    """Filename with path traversal and special chars must be sanitized."""
    with patch("app.services.documento_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.documento_service.send_push_notification", new_callable=AsyncMock) as mock_push:
        mock_upload.return_value = True
        mock_push.return_value = True

        payload = {"categoria": "passagem"}
        files = {"file": ("../../etc/passwd\x00evil.png", _FAKE_PDF, "application/pdf")}

        response = await async_client.post(
            f"/leads/{str(sample_lead.id)}/documents",
            data=payload,
            files=files
        )

        assert response.status_code == status.HTTP_201_CREATED, response.text
        data = response.json()
        # Sanitized name should strip path and replace dangerous chars
        assert ".." not in data["nome"]
        assert "\x00" not in data["nome"]
        assert data["nome"].endswith(".png") or data["nome"].endswith("evil.png")


@pytest.mark.asyncio
async def test_list_documents_with_signed_urls(async_client, sample_lead, sample_document):
    """CT-02: Validate if listing returns signed URLs."""
    with patch("app.services.documento_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url:
        mock_url.return_value = "https://s3.amazonaws.com/test-bucket/doc.pdf?signed=true"

        response = await async_client.get(f"/leads/{str(sample_lead.id)}/documents")
        assert response.status_code == status.HTTP_200_OK, response.text
        data = response.json()
        assert len(data) >= 1
        assert "url_signed" in data[0]


@pytest.mark.asyncio
async def test_delete_document_rbac_client_denied(async_client, sample_lead, sample_document):
    """CT-03: Clients must not be allowed to delete documents (403)."""
    mock_client_user = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="Joao Cliente",
        email="joao@cliente.com",
        is_active=True
    )

    async def get_mock_client():
        return mock_client_user

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.delete(f"/leads/{str(sample_lead.id)}/documents/{str(sample_document.id)}")
        assert response.status_code == status.HTTP_403_FORBIDDEN, response.text
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_delete_document_rbac_consultant_success(async_client, sample_lead, sample_document):
    """CT-03: Consultants must be allowed to delete documents (204)."""
    mock_consultant = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.consultor,
        nome="Consultor VIP",
        email="consultor@agencia.com",
        is_active=True
    )

    async def get_mock_consultant():
        return mock_consultant

    fastapi_app.dependency_overrides[get_current_user] = get_mock_consultant

    try:
        response = await async_client.delete(f"/leads/{str(sample_lead.id)}/documents/{str(sample_document.id)}")
        assert response.status_code == status.HTTP_204_NO_CONTENT, response.text
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_list_documents_empty(async_client, sample_lead):
    """Test listing documents for a lead with no documents."""
    response = await async_client.get(f"/leads/{sample_lead.id}/documents")
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_upload_atomic_cleanup_failure(async_client, sample_lead, mocker):
    """
    Test that if DB persistence fails, the file is deleted from S3 (Atomic Rule).
    """
    from app.infrastructure.persistence.repositories.documento_repository import DocumentoRepository
    from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter

    # Mock S3 upload success
    mocker.patch.object(
        S3StorageAdapter, "upload_file",
        return_value=True
    )

    # Mock DB failure
    mocker.patch.object(
        DocumentoRepository, "create",
        side_effect=Exception("Database connection lost")
    )

    # Spy on S3 delete_file
    mock_delete = mocker.patch.object(S3StorageAdapter, "delete_file", return_value=None)

    file_content = _FAKE_PDF
    files = {"file": ("failed_doc.pdf", file_content, "application/pdf")}
    data = {"categoria": "voucher"}

    response = await async_client.post(
        f"/leads/{sample_lead.id}/documents",
        data=data,
        files=files
    )

    assert response.status_code == 500
    assert "Erro ao registrar metadados" in response.json()["detail"]

    # Verify that delete_file was called to clean up the "garbage" file
    assert mock_delete.called
    print("\n[ATOMICIDADE] Sucesso: O arquivo órfão foi removido do S3 após falha no DB.")
