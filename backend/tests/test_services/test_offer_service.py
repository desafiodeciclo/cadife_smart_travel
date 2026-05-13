import uuid
from datetime import datetime, timezone
from decimal import Decimal

import pytest
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.domain.entities.enums import OfferStatus
from app.models.lead import Lead
from app.models.offer import Offer
from app.presentation.schemas.offer_schema import OfferCreateRequest, OfferUpdateRequest
from app.services import offer_service

_AGENCY_ID = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
_FUTURE_DEPART = datetime(2027, 6, 1, tzinfo=timezone.utc)
_FUTURE_RETURN = datetime(2027, 6, 11, tzinfo=timezone.utc)
_FUTURE_DEADLINE = datetime(2027, 5, 1, tzinfo=timezone.utc)


def _make_offer(**kwargs) -> Offer:
    """Helper: cria Offer com todos os campos obrigatórios preenchidos."""
    defaults = dict(
        title="Oferta Padrão",
        description="Descrição padrão para testes de oferta no sistema Cadife",
        destination="Destino",
        agency_id=_AGENCY_ID,
        departure_date=_FUTURE_DEPART,
        return_date=_FUTURE_RETURN,
        booking_deadline=_FUTURE_DEADLINE,
        duration_days=10,
        available_spots=10,
        base_price=Decimal("1000.00"),
        final_price=Decimal("1000.00"),
        status=OfferStatus.draft,
    )
    defaults.update(kwargs)
    return Offer(**defaults)


@pytest.mark.asyncio
async def test_create_offer(db_session):
    offer = await offer_service.create_offer(
        db_session,
        data=OfferCreateRequest(
            title="Pacote Portugal",
            description="10 dias incríveis em Lisboa, com passeios e curadoria completa",
            destination="Lisboa",
            departure_date=datetime(2027, 6, 15, tzinfo=timezone.utc),
            return_date=datetime(2027, 6, 25, tzinfo=timezone.utc),
            booking_deadline=datetime(2027, 5, 1, tzinfo=timezone.utc),
            accommodations=["hotel 4 estrelas"],
            included_services=["café da manhã"],
            travelers=2,
            available_spots=10,
            base_price=Decimal("4999.99"),
            highlights=["vista incrível para o Tejo"],
        ),
        agency_id=_AGENCY_ID,
    )

    assert offer.id is not None
    assert offer.title == "Pacote Portugal"
    assert offer.status == OfferStatus.draft
    assert offer.agency_id == _AGENCY_ID


@pytest.mark.asyncio
async def test_list_offers_with_filters(db_session):
    for i in range(3):
        db_session.add(_make_offer(
            title=f"Oferta {i}",
            base_price=Decimal(str(1000 * (i + 1))),
            final_price=Decimal(str(1000 * (i + 1))),
            status=OfferStatus.published if i == 0 else OfferStatus.draft,
        ))
    await db_session.commit()

    # Filtra por status via agency_id (contorna filtro de publicadas)
    items, total = await offer_service.list_offers(
        db_session, agency_id=_AGENCY_ID, status_filter=OfferStatus.published
    )
    assert total == 1
    assert items[0].title == "Oferta 0"

    # Filtra por faixa de preço
    items, total = await offer_service.list_offers(
        db_session, agency_id=_AGENCY_ID, min_price=1500.0, max_price=2500.0
    )
    assert total == 1
    assert items[0].title == "Oferta 1"

    # Filtra por título via busca textual
    items, total = await offer_service.list_offers(
        db_session, agency_id=_AGENCY_ID, search="Oferta 2"
    )
    assert total == 1
    assert items[0].title == "Oferta 2"

    # Busca por destino retorna todas
    items, total = await offer_service.list_offers(
        db_session, agency_id=_AGENCY_ID, search="Destino"
    )
    assert total == 3


@pytest.mark.asyncio
async def test_get_offer_by_id(db_session):
    offer = _make_offer(title="Oferta Teste")
    db_session.add(offer)
    await db_session.commit()

    found = await offer_service.get_offer_by_id(db_session, offer.id)
    assert found is not None
    assert found.title == "Oferta Teste"

    not_found = await offer_service.get_offer_by_id(db_session, uuid.uuid4())
    assert not_found is None


@pytest.mark.asyncio
async def test_update_offer(db_session):
    offer = _make_offer(title="Original", destination="Original")
    db_session.add(offer)
    await db_session.commit()

    updated = await offer_service.update_offer(
        db_session,
        offer,
        OfferUpdateRequest(title="Atualizado"),
        agency_id=_AGENCY_ID,
    )
    assert updated.title == "Atualizado"


@pytest.mark.asyncio
async def test_toggle_publish(db_session):
    offer = _make_offer(title="Pub", destination="Pub")
    db_session.add(offer)
    await db_session.commit()

    # draft → published
    published = await offer_service.toggle_publish(db_session, offer, agency_id=_AGENCY_ID)
    assert published.status == OfferStatus.published

    # published → draft
    unpublished = await offer_service.toggle_publish(db_session, published, agency_id=_AGENCY_ID)
    assert unpublished.status == OfferStatus.draft


@pytest.mark.asyncio
async def test_soft_delete_offer(db_session):
    offer = _make_offer(title="Del")
    db_session.add(offer)
    await db_session.commit()

    await offer_service.soft_delete_offer(db_session, offer, agency_id=_AGENCY_ID)
    assert offer.is_deleted is True

    found = await offer_service.get_offer_by_id(db_session, offer.id)
    assert found is None


@pytest.mark.asyncio
async def test_express_interest(db_session):
    from app.infrastructure.persistence.models.user_model import UserModel

    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    user = await db_session.get(UserModel, user_id)
    if not user:
        user = UserModel(
            id=user_id,
            nome="Test User",
            email="test@test.com",
            hashed_password="pw",
            perfil="cliente",
            telefone="+5511988888888",
            is_active=True,
        )
        db_session.add(user)
        await db_session.commit()

    offer = _make_offer(
        title="Interesse",
        destination="Paris",
        status=OfferStatus.published,
        available_spots=5,
    )
    db_session.add(offer)
    await db_session.commit()

    result = await offer_service.express_interest(
        db_session,
        offer=offer,
        user_id=user_id,
        user_name="Test User",
        user_email="test@test.com",
        user_phone="+5511988888888",
    )
    assert result["status"] == "success"
    assert result["lead_id"] is not None

    # Verifica que o lead foi criado com briefing apontando para o destino da oferta
    res = await db_session.execute(
        select(Lead)
        .where(Lead.id == uuid.UUID(result["lead_id"]))
        .options(selectinload(Lead.briefing))
    )
    lead = res.scalar_one()
    assert lead.briefing is not None
    assert lead.briefing.destino == "Paris"
