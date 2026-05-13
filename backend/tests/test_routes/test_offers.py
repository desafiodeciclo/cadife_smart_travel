import uuid
from datetime import datetime, timezone
from decimal import Decimal

import pytest
from fastapi import status

from app.domain.entities.enums import OfferStatus
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.security.dependencies import get_current_user
from app.models.offer import Offer
from app.models.user import UserPerfil
from main import app as fastapi_app

_AGENCY_ID = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
_FUTURE_DEPART = datetime(2027, 6, 1, tzinfo=timezone.utc)
_FUTURE_RETURN = datetime(2027, 6, 11, tzinfo=timezone.utc)
_FUTURE_DEADLINE = datetime(2027, 5, 1, tzinfo=timezone.utc)

# Payload mínimo válido para POST /offers
_VALID_CREATE_PAYLOAD = {
    "title": "Nova Oferta",
    "description": "Praia paradisíaca com paisagens deslumbrantes e cultura rica",
    "destination": "Bahia",
    "departure_date": "2027-01-15T00:00:00Z",
    "return_date": "2027-01-22T00:00:00Z",
    "booking_deadline": "2026-12-15T00:00:00Z",
    "accommodations": ["hotel"],
    "included_services": ["café da manhã"],
    "travelers": 2,
    "available_spots": 10,
    "base_price": "1500.00",
    "highlights": ["praia linda"],
}


def _make_offer(**kwargs) -> Offer:
    defaults = dict(
        title="Pacote Teste",
        description="Carnaval 2027 em grande estilo na cidade maravilhosa",
        destination="Rio de Janeiro",
        agency_id=_AGENCY_ID,
        departure_date=datetime(2027, 2, 10, tzinfo=timezone.utc),
        return_date=datetime(2027, 2, 15, tzinfo=timezone.utc),
        booking_deadline=datetime(2027, 1, 10, tzinfo=timezone.utc),
        duration_days=5,
        available_spots=20,
        base_price=Decimal("2999.00"),
        final_price=Decimal("2999.00"),
        status=OfferStatus.published,
    )
    defaults.update(kwargs)
    return Offer(**defaults)


@pytest.fixture
async def sample_offer(db_session):
    offer = _make_offer(id=uuid.uuid4())
    db_session.add(offer)
    await db_session.commit()
    await db_session.refresh(offer)
    return offer


@pytest.fixture
async def draft_offer(db_session):
    """Oferta em rascunho — usada em testes de edição."""
    offer = _make_offer(id=uuid.uuid4(), status=OfferStatus.draft)
    db_session.add(offer)
    await db_session.commit()
    await db_session.refresh(offer)
    return offer


@pytest.mark.asyncio
async def test_create_offer_success(async_client):
    response = await async_client.post("/offers", json=_VALID_CREATE_PAYLOAD)
    assert response.status_code == status.HTTP_201_CREATED, response.text
    resp = response.json()
    assert resp["title"] == "Nova Oferta"
    assert resp["status"] == "draft"


@pytest.mark.asyncio
async def test_list_offers(async_client, sample_offer):
    response = await async_client.get("/offers")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["total"] >= 1
    assert any(item["id"] == str(sample_offer.id) for item in data["offers"])


@pytest.mark.asyncio
async def test_list_offers_filter_by_destination(async_client, sample_offer):
    response = await async_client.get("/offers?destination=Rio+de+Janeiro")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert any(item["destination"] == "Rio de Janeiro" for item in data["offers"])


@pytest.mark.asyncio
async def test_get_offer_detail(async_client, sample_offer):
    response = await async_client.get(f"/offers/{sample_offer.id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["id"] == str(sample_offer.id)
    assert data["destination"] == "Rio de Janeiro"


@pytest.mark.asyncio
async def test_update_offer(async_client, draft_offer):
    payload = {"title": "Oferta Atualizada"}
    response = await async_client.patch(f"/offers/{draft_offer.id}", json=payload)
    assert response.status_code == status.HTTP_200_OK, response.text
    assert response.json()["title"] == "Oferta Atualizada"


@pytest.mark.asyncio
async def test_publish_offer(async_client, sample_offer):
    # sample_offer começa como published → primeiro toggle → draft
    response = await async_client.patch(f"/offers/{sample_offer.id}/publish")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["new_status"] == "draft"

    # Segundo toggle → published
    response = await async_client.patch(f"/offers/{sample_offer.id}/publish")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["new_status"] == "published"


@pytest.mark.asyncio
async def test_delete_offer(async_client, sample_offer):
    response = await async_client.delete(f"/offers/{sample_offer.id}")
    assert response.status_code == status.HTTP_200_OK

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
        assert data["status"] == "success"
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_express_interest_unpublished(async_client, db_session):
    offer = _make_offer(id=uuid.uuid4(), status=OfferStatus.draft)
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
        assert "não disponível" in response.json()["detail"]
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_rbac_update_denied(async_client, draft_offer):
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
            f"/offers/{draft_offer.id}",
            json={"title": "Hacked"},
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_client_get_draft_offer_returns_404(async_client, db_session):
    """Cliente não pode ver detalhes de oferta em rascunho (retorna 404)."""
    draft = _make_offer(id=uuid.uuid4(), status=OfferStatus.draft)
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
        assert response.status_code == status.HTTP_404_NOT_FOUND
    finally:
        fastapi_app.dependency_overrides.pop(get_current_user, None)


@pytest.mark.asyncio
async def test_client_list_only_published(async_client, db_session):
    """Cliente em GET /offers só vê ofertas publicadas."""
    for st in [OfferStatus.published, OfferStatus.draft, OfferStatus.archived]:
        db_session.add(_make_offer(
            id=uuid.uuid4(),
            title=f"Oferta {st.value}",
            status=st,
        ))
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
        assert all(item["status"] == "published" for item in data["offers"])
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
        response = await async_client.patch(f"/offers/{sample_offer.id}/publish")
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
async def test_list_offers_search(async_client, db_session):
    """Busca por título ou destino via query param ?search=."""
    for title, destination in [("Pacote Portugal", "Lisboa"), ("Pacote Espanha", "Barcelona")]:
        db_session.add(_make_offer(
            id=uuid.uuid4(),
            title=title,
            destination=destination,
            status=OfferStatus.published,
        ))
    await db_session.commit()

    response = await async_client.get("/offers?search=Portugal")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert all("Portugal" in (item["title"] + item["destination"]) for item in data["offers"])

    response = await async_client.get("/offers?search=Barcelona")
    assert response.status_code == status.HTTP_200_OK
    assert all("Barcelona" in (item["title"] + item["destination"]) for item in response.json()["offers"])


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
