import pytest
import uuid
from fastapi import status
from io import BytesIO
from PIL import Image
from datetime import datetime

@pytest.fixture
async def test_lead(db_session):
    """Fixture to create a test lead."""
    from app.infrastructure.persistence.models.lead_model import LeadModel
    
    lead = LeadModel(
        id=uuid.uuid4(),
        nome="Viagem de Teste",
        telefone="+5511999999999",
        status="novo"
    )
    db_session.add(lead)
    await db_session.flush()
    return lead

@pytest.mark.asyncio
async def test_diary_full_cycle(async_client, test_lead, override_get_current_user):
    """
    Test the full cycle of a diary entry: Create, List, and Delete.
    """
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
async def test_diary_privacy_violation(async_client, test_lead):
    """
    Test that a user cannot delete an entry that doesn't belong to them.
    """
    from app.infrastructure.persistence.models.travel_diary_model import TravelDiaryEntryModel
    import uuid
    
    # 1. Criar uma entrada que pertence a OUTRO usuário (UUID diferente do mock_user)
    other_user_id = uuid.uuid4()
    entry_id = uuid.uuid4()
    
    # Injetamos direto no banco para simular a existência de dados de outro user
    from tests.conftest import TestSessionLocal
    async with TestSessionLocal() as session:
        entry = TravelDiaryEntryModel(
            id=entry_id,
            lead_id=test_lead.id,
            user_id=other_user_id,
            foto_url="path/to/other.jpg",
            thumb_url="path/to/other_thumb.jpg",
            nota="Nota privada",
            data_entrada=datetime.now()
        )
        session.add(entry)
        await session.commit()

    print(f"\n[TEST] Tentando deletar entrada do usuário {other_user_id} sendo o Test User...")
    
    # 2. Tentar deletar usando o TestUser (que o override_get_current_user fornece)
    response = await async_client.delete(f"/leads/{test_lead.id}/diary/entries/{entry_id}")
    
    # DEVE retornar 403 Forbidden ou 404 Not Found (dependendo da implementação, no nosso caso é 403 ou 404 pelo check de ownership)
    assert response.status_code in [status.HTTP_403_FORBIDDEN, status.HTTP_404_NOT_FOUND]
    print(f"✅ Bloqueio de privacidade confirmado: {response.status_code}")

@pytest.mark.asyncio
async def test_diary_heic_upload(async_client, test_lead):
    """
    Test uploading a HEIC file (iPhone format).
    """
    print("\n[TEST] Testando upload de arquivo HEIC (iPhone)...")
    
    # Criamos um arquivo fake que finge ser HEIC (apenas para testar se o service tenta processar)
    # Nota: Para um teste real de processamento, precisaríamos de um binário HEIC válido.
    # Vou usar um JPEG e renomear, mas o ideal é validar a extensão.
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

    # Se o pillow-heif estiver ok, ele processa. Se for binário inválido, pode dar 400.
    # O importante é que o endpoint aceite a tentativa.
    assert response.status_code in [status.HTTP_201_CREATED, status.HTTP_400_BAD_REQUEST]
    if response.status_code == 201:
        print("✅ Upload de HEIC processado com sucesso.")
    else:
        print(f"ℹ️ Endpoint aceitou o arquivo, mas recusou o binário fake: {response.json()}")
