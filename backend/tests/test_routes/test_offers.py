import uuid
from datetime import date
from decimal import Decimal
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import status

from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.security.dependencies import get_current_user
from app.models.offer import Offer
from app.models.user import UserPerfil
from main import app as fastapi_app

_FAKE_JPEG = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"


@pytest.fixture
async def sample_offer(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        id=uuid.uuid4(),
        titulo="Pacote Teste",
        destino="Rio de Janeiro",
        descricao="Carnaval 2027",
        categoria=OfferCategoria.nacional,
        preco_base=Decimal("2999.00"),
        servicos_inclusos=["hotel", "passeio"],
        imagens=["https://s3.example.com/1.jpg"],
        data_saida_sugerida=date(2027, 2, 10),
        duracao_dias=5,
        status=OfferStatus.publicada,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()
    await db_session.refresh(offer)
    return offer


@pytest.mark.asyncio
async def test_create_offer_success(async_client):
    with patch("app.services.offer_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.offer_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url:
        mock_upload.return_value = True
        mock_url.return_value = "https://s3.example.com/offers/1.jpg"

        data = {
            "titulo": "Nova Oferta",
            "destino": "Bahia",
            "descricao": "Praia paradisíaca",
            "categoria": "nacional",
            "preco_base": "1500.00",
            "servicos_inclusos": "hotel,translado",
            "data_saida_sugerida": "2027-01-15",
            "duracao_dias": "7",
        }
        files = {"images": ("foto.jpg", _FAKE_JPEG, "image/jpeg")}

        response = await async_client.post(
            "/offers",
            data=data,
            files=files,
        )
        assert response.status_code == status.HTTP_201_CREATED, response.text
        resp = response.json()
        assert resp["titulo"] == "Nova Oferta"
        assert resp["status"] == "rascunho"


@pytest.mark.asyncio
async def test_list_offers(async_client, sample_offer):
    response = await async_client.get("/offers")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["total"] >= 1
    assert any(item["id"] == str(sample_offer.id) for item in data["items"])


@pytest.mark.asyncio
async def test_list_offers_filter_by_categoria(async_client, sample_offer):
    response = await async_client.get("/offers?categoria=nacional")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert all(item["categoria"] == "nacional" for item in data["items"])


@pytest.mark.asyncio
async def test_get_offer_detail(async_client, sample_offer):
    response = await async_client.get(f"/offers/{sample_offer.id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["id"] == str(sample_offer.id)
    assert data["destino"] == "Rio de Janeiro"


@pytest.mark.asyncio
async def test_update_offer(async_client, sample_offer):
    with patch("app.services.offer_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.offer_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url:
        mock_upload.return_value = True
        mock_url.return_value = "https://s3.example.com/offers/2.jpg"

        data = {"titulo": "Oferta Atualizada"}
        response = await async_client.patch(
            f"/offers/{sample_offer.id}",
            data=data,
        )
        assert response.status_code == status.HTTP_200_OK, response.text
        assert response.json()["titulo"] == "Oferta Atualizada"


@pytest.mark.asyncio
async def test_publish_offer(async_client, sample_offer):
    response = await async_client.patch(
        f"/offers/{sample_offer.id}/publish?publish=false"
    )
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "rascunho"

    response = await async_client.patch(
        f"/offers/{sample_offer.id}/publish?publish=true"
    )
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["status"] == "publicada"


@pytest.mark.asyncio
async def test_delete_offer(async_client, sample_offer):
    response = await async_client.delete(f"/offers/{sample_offer.id}")
    assert response.status_code == status.HTTP_204_NO_CONTENT

    response = await async_client.get(f"/offers/{sample_offer.id}")
    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_express_interest(async_client, sample_offer):
    mock_client = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="João Cliente",
        email="joao@cliente.com",
        telefone="+5511977777777",
        is_active=True,
    )

    async def get_mock_client():
        return mock_client

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.post(f"/offers/{sample_offer.id}/interest")
        assert response.status_code == status.HTTP_200_OK, response.text
        data = response.json()
        assert data["lead_id"] is not None
        assert data["offer_id"] == str(sample_offer.id)
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_express_interest_unpublished(async_client, db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        id=uuid.uuid4(),
        titulo="Rascunho",
        destino="Nenhum",
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    mock_client = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="João",
        email="joao@cliente.com",
        telefone="+5511966666666",
        is_active=True,
    )

    async def get_mock_client():
        return mock_client

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.post(f"/offers/{offer.id}/interest")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "não está publicada" in response.json()["detail"]
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_rbac_update_denied(async_client, sample_offer):
    mock_consultant = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.consultor,
        nome="Outro Consultor",
        email="outro@agencia.com",
        is_active=True,
    )

    async def get_mock_consultor():
        return mock_consultant

    fastapi_app.dependency_overrides[get_current_user] = get_mock_consultor

    try:
        response = await async_client.patch(
            f"/offers/{sample_offer.id}",
            data={"titulo": "Hacked"},
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


# ── Edge Cases — Missing Coverage ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_client_get_draft_offer_returns_403(async_client, db_session):
    """Cliente não pode ver detalhes de oferta em rascunho."""
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    draft = Offer(
        id=uuid.uuid4(),
        titulo="Rascunho Secreto",
        destino="Secreto",
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(draft)
    await db_session.commit()

    mock_client = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="Cliente",
        email="cliente@test.com",
        is_active=True,
    )

    async def get_mock_client():
        return mock_client

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.get(f"/offers/{draft.id}")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_client_list_only_published(async_client, db_session):
    """Cliente em GET /offers só vê ofertas publicadas."""
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    for st in [OfferStatus.publicada, OfferStatus.rascunho, OfferStatus.encerrada]:
        db_session.add(
            Offer(
                id=uuid.uuid4(),
                titulo=f"Oferta {st.value}",
                destino="Teste",
                status=st,
                criado_por=user_id,
            )
        )
    await db_session.commit()

    mock_client = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="Cliente",
        email="cliente@test.com",
        is_active=True,
    )

    async def get_mock_client():
        return mock_client

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.get("/offers")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert all(item["status"] == "publicada" for item in data["items"])
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_rbac_publish_denied(async_client, sample_offer):
    mock_consultant = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.consultor,
        nome="Outro Consultor",
        email="outro@agencia.com",
        is_active=True,
    )

    async def get_mock_consultor():
        return mock_consultant

    fastapi_app.dependency_overrides[get_current_user] = get_mock_consultor

    try:
        response = await async_client.patch(
            f"/offers/{sample_offer.id}/publish?publish=false"
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_rbac_delete_denied(async_client, sample_offer):
    mock_consultant = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.consultor,
        nome="Outro Consultor",
        email="outro@agencia.com",
        is_active=True,
    )

    async def get_mock_consultor():
        return mock_consultant

    fastapi_app.dependency_overrides[get_current_user] = get_mock_consultor

    try:
        response = await async_client.delete(f"/offers/{sample_offer.id}")
        assert response.status_code == status.HTTP_403_FORBIDDEN
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_upload_magic_bytes_spoof(async_client):
    """Arquivo com Content-Type JPEG mas magic bytes de EXE deve ser bloqueado."""
    files = {"images": ("spoofed.jpg", b"MZ\x90\x00\x03\x00\x00\x00", "image/jpeg")}
    data = {
        "titulo": "Oferta Spoof",
        "destino": "Teste",
    }
    response = await async_client.post("/offers", data=data, files=files)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "não corresponde" in response.json()["detail"]


@pytest.mark.asyncio
async def test_upload_too_many_images(async_client):
    """Máximo de 5 imagens por oferta."""
    files = [("images", (f"foto{i}.jpg", _FAKE_JPEG, "image/jpeg")) for i in range(6)]
    data = {"titulo": "Oferta Excesso", "destino": "Teste"}
    response = await async_client.post("/offers", data=data, files=files)
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert "Máximo de 5" in response.json()["detail"]


@pytest.mark.asyncio
async def test_upload_image_too_large(async_client):
    """Imagem acima de 5MB deve ser bloqueada."""
    large_jpeg = b"\xff\xd8\xff" + b"0" * (6 * 1024 * 1024)
    files = {"images": ("huge.jpg", large_jpeg, "image/jpeg")}
    data = {"titulo": "Oferta Grande", "destino": "Teste"}
    response = await async_client.post("/offers", data=data, files=files)
    assert response.status_code == status.HTTP_413_REQUEST_ENTITY_TOO_LARGE


@pytest.mark.asyncio
async def test_list_offers_search(async_client, db_session):
    """Busca por título ou destino via query param ?search=."""
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    db_session.add(
        Offer(
            id=uuid.uuid4(),
            titulo="Pacote Portugal",
            destino="Lisboa",
            status=OfferStatus.publicada,
            criado_por=user_id,
        )
    )
    db_session.add(
        Offer(
            id=uuid.uuid4(),
            titulo="Pacote Espanha",
            destino="Barcelona",
            status=OfferStatus.publicada,
            criado_por=user_id,
        )
    )
    await db_session.commit()

    response = await async_client.get("/offers?search=Portugal")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert all("Portugal" in (item["titulo"] + item["destino"]) for item in data["items"])

    response = await async_client.get("/offers?search=Barcelona")
    assert response.status_code == status.HTTP_200_OK
    assert all("Barcelona" in (item["titulo"] + item["destino"]) for item in response.json()["items"])


@pytest.mark.asyncio
async def test_express_interest_no_phone(async_client, sample_offer):
    """Cliente sem telefone cadastrado recebe 400."""
    mock_client = UserModel(
        id=uuid.uuid4(),
        perfil=UserPerfil.cliente,
        nome="Sem Telefone",
        email="sem@telefone.com",
        telefone=None,
        is_active=True,
    )

    async def get_mock_client():
        return mock_client

    fastapi_app.dependency_overrides[get_current_user] = get_mock_client

    try:
        response = await async_client.post(f"/offers/{sample_offer.id}/interest")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "telefone" in response.json()["detail"].lower()
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)
