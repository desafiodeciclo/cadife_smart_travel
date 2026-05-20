import pytest
import uuid
from unittest.mock import AsyncMock, patch, MagicMock
from fastapi import status
from io import BytesIO
from PIL import Image
from datetime import datetime

from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel
from app.infrastructure.security.pii_encryption import hmac_hash


@pytest.fixture
async def test_lead(db_session):
    """Fixture to create a test lead linked to the mock test user."""
    mock_user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    
    # Ensure the mock user exists in the database for FK constraints
    user_exists = await db_session.get(UserModel, mock_user_id)
    if not user_exists:
        mock_user = UserModel(
            id=mock_user_id,
            nome="Test User",
            email="test@example.com",
            hashed_password="hashed_password_here",
            telefone="+5511999999999",
            perfil="admin",
            is_active=True,
        )
        db_session.add(mock_user)
        await db_session.flush()

    lead = LeadModel(
        id=uuid.uuid4(),
        nome="Viagem de Teste",
        telefone="+5511999999999",
        telefone_hash=hmac_hash("+5511999999999"),
        status="novo"
    )
    db_session.add(lead)
    await db_session.flush()
    await db_session.refresh(lead)
    return lead


@pytest.mark.asyncio
async def test_diary_full_cycle(async_client, test_lead, override_get_current_user):
    """
    Test the full cycle of a diary entry: Create, List, and Delete.
    S3 is mocked to avoid external dependency.
    """
    with patch("app.services.diary_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.diary_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url, \
         patch("app.services.diary_service.S3StorageAdapter.delete_file", new_callable=AsyncMock) as mock_delete:
        
        mock_upload.return_value = True
        mock_url.return_value = "https://s3.local/test-bucket/signed.jpg?token=abc"
        mock_delete.return_value = True

        # 1. CREATE ENTRY
        print("\n[TEST] Criando entrada no diário...")
        img_io = BytesIO()
        image = Image.new('RGB', (100, 100), color='blue')
        image.save(img_io, format='JPEG')
        img_io.seek(0)

        payload = {
            "nota": "Memória de teste com integração!",
            "data_entrada": datetime.now().isoformat()
        }
        files = {"file": ("test.jpg", img_io, "image/jpeg")}

        response = await async_client.post(
            f"/leads/{test_lead.id}/diary/entries",
            data=payload,
            files=files
        )

        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["nota"] == payload["nota"]
        assert data["foto_url"] == "https://s3.local/test-bucket/signed.jpg?token=abc"
        assert data["thumb_url"] == "https://s3.local/test-bucket/signed.jpg?token=abc"
        entry_id = data["id"]
        print(f"✅ Entrada criada com ID: {entry_id}")

        # 2. LIST ENTRIES
        print("[TEST] Listando entradas da viagem...")
        list_res = await async_client.get(f"/leads/{test_lead.id}/diary/entries")
        assert list_res.status_code == status.HTTP_200_OK
        list_data = list_res.json()
        assert list_data["total"] >= 1
        assert any(e["id"] == entry_id for e in list_data["entries"])
        print(f"✅ Listagem confirmada. Total: {list_data['total']}")

        # 3. LIST USER TIMELINE
        print("[TEST] Listando timeline global do usuário...")
        timeline_res = await async_client.get("/users/me/diary")
        assert timeline_res.status_code == status.HTTP_200_OK
        assert timeline_res.json()["total"] >= 1
        print("✅ Timeline global confirmada.")

        # 4. DELETE ENTRY
        print("[TEST] Deletando entrada...")
        del_res = await async_client.delete(f"/leads/{test_lead.id}/diary/entries/{entry_id}")
        assert del_res.status_code == status.HTTP_204_NO_CONTENT
        print("✅ Deleção confirmada.")

        # 5. VERIFY DELETION
        final_list = await async_client.get(f"/leads/{test_lead.id}/diary/entries")
        assert not any(e["id"] == entry_id for e in final_list.json()["entries"])
        print("✅ Verificação final: Entrada não existe mais.")


@pytest.mark.asyncio
async def test_diary_privacy_violation(async_client, test_lead, db_session):
    """
    Test that a user cannot delete an entry that doesn't belong to them.
    """
    other_user_id = uuid.uuid4()
    entry_id = uuid.uuid4()
    
    # Ensure other user exists
    other_user = UserModel(
        id=other_user_id,
        nome="Outro Usuário",
        email="outro@example.com",
        hashed_password="pw",
        telefone="+5511888888888",
        perfil="cliente",
        is_active=True,
    )
    db_session.add(other_user)
    await db_session.flush()

    # Inject an entry that belongs to OTHER user
    entry = TravelDiaryEntryModel(
        id=entry_id,
        lead_id=test_lead.id,
        user_id=other_user_id,
        foto_url="path/to/other.jpg",
        thumb_url="path/to/other_thumb.jpg",
        nota="Nota privada",
        data_entrada=datetime.now()
    )
    db_session.add(entry)
    await db_session.commit()

    print(f"\n[TEST] Tentando deletar entrada do usuário {other_user_id} sendo o Test User...")
    
    # Attempt to delete using the TestUser (provided by override_get_current_user)
    response = await async_client.delete(f"/leads/{test_lead.id}/diary/entries/{entry_id}")
    
    # MUST return 403 Forbidden
    assert response.status_code == status.HTTP_403_FORBIDDEN
    print(f"✅ Bloqueio de privacidade confirmado: {response.status_code}")


@pytest.mark.asyncio
async def test_diary_heic_upload(async_client, test_lead):
    """
    Test uploading a HEIC file (iPhone format).
    Since generating a real HEIC in test environment is complex, we mock
    Image.open to simulate HEIC processing and verify the service accepts it.
    """
    print("\n[TEST] Testando upload de arquivo HEIC (iPhone)...")
    
    with patch("app.services.diary_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.diary_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url, \
         patch("app.services.diary_service.Image.open") as mock_image_open:
        
        mock_upload.return_value = True
        mock_url.return_value = "https://s3.local/test-bucket/signed.jpg?token=abc"
        
        # Simulate a HEIC image that gets converted to RGB
        mock_img = MagicMock()
        mock_img.mode = "RGBA"
        mock_img.format = "HEIF"
        mock_img.thumbnail.return_value = None
        mock_converted = MagicMock()
        mock_converted.save.return_value = None
        mock_img.convert.return_value = mock_converted
        mock_image_open.return_value = mock_img

        img_io = BytesIO()
        Image.new('RGB', (100, 100)).save(img_io, format='JPEG')
        img_io.seek(0)

        files = {"file": ("iphone_photo.heic", img_io, "image/heic")}
        payload = {"nota": "Foto do meu iPhone!", "data_entrada": datetime.now().isoformat()}

        response = await async_client.post(
            f"/leads/{test_lead.id}/diary/entries",
            data=payload,
            files=files
        )

        assert response.status_code == status.HTTP_201_CREATED
        print("✅ Upload de HEIC processado com sucesso (via mock).")
        
        # Verify that Image.open was called (HEIC processing path)
        mock_image_open.assert_called_once()


@pytest.mark.asyncio
async def test_diary_timeline_s3_presigned_failure_returns_200(async_client, test_lead, db_session):
    """
    Regression test: when S3/MinIO fails to generate presigned URLs,
    the API must still return 200 with the raw S3 keys, never 500.
    """
    from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel

    entry_id = uuid.uuid4()
    raw_foto_key = f"diary/{test_lead.id}/{entry_id}_original.jpg"
    raw_thumb_key = f"diary/{test_lead.id}/{entry_id}_thumb.jpg"

    # Inject a diary entry directly into the DB
    entry = TravelDiaryEntryModel(
        id=entry_id,
        lead_id=test_lead.id,
        user_id=uuid.UUID("deadeade-dead-dead-dead-deadeadeadea"),
        foto_url=raw_foto_key,
        thumb_url=raw_thumb_key,
        nota="Regressão: S3 indisponível",
        data_entrada=datetime.now()
    )
    db_session.add(entry)
    await db_session.commit()

    print("\n[TEST] Simulando falha no S3 (generate_presigned_url retorna None)...")

    with patch("app.services.diary_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url:
        mock_url.return_value = None

        response = await async_client.get("/users/me/diary")

        # MUST NOT return 500; should return 200 with raw keys preserved
        assert response.status_code == status.HTTP_200_OK, f"Esperado 200, obtido {response.status_code}"
        data = response.json()
        assert data["total"] >= 1
        first_entry = data["entries"][0]
        assert first_entry["foto_url"] == raw_foto_key
        assert first_entry["thumb_url"] == raw_thumb_key
        print("✅ Timeline retornou 200 mesmo com S3 indisponível.")
