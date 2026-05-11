import uuid
from datetime import date
from decimal import Decimal
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import status
from sqlalchemy import select

from app.domain.entities.enums import OfferCategoria, OfferStatus
from app.models.offer import Offer
from app.presentation.schemas.offer_schema import OfferCreate, OfferUpdate
from app.services import offer_service


@pytest.mark.asyncio
async def test_create_offer(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    with patch("app.services.offer_service.S3StorageAdapter.upload_file", new_callable=AsyncMock) as mock_upload, \
         patch("app.services.offer_service.S3StorageAdapter.generate_presigned_url", new_callable=AsyncMock) as mock_url:
        mock_upload.return_value = True
        mock_url.return_value = "https://s3.example.com/offers/1.jpg"

        offer = await offer_service.create_offer(
            db_session,
            data=OfferCreate(
                titulo="Pacote Portugal",
                destino="Lisboa",
                descricao="10 dias incríveis",
                categoria=OfferCategoria.internacional,
                preco_base=Decimal("4999.99"),
                servicos_inclusos=["hotel", "café da manhã"],
                data_saida_sugerida=date(2026, 6, 15),
                duracao_dias=10,
            ),
            images=[],
            user_id=user_id,
        )

    assert offer.id is not None
    assert offer.titulo == "Pacote Portugal"
    assert offer.status == OfferStatus.rascunho
    assert offer.criado_por == user_id


@pytest.mark.asyncio
async def test_list_offers_with_filters(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    for i in range(3):
        offer = Offer(
            titulo=f"Oferta {i}",
            destino="Destino",
            categoria=OfferCategoria.nacional if i % 2 == 0 else OfferCategoria.internacional,
            preco_base=Decimal(str(1000 * (i + 1))),
            status=OfferStatus.publicada if i == 0 else OfferStatus.rascunho,
            criado_por=user_id,
        )
        db_session.add(offer)
    await db_session.commit()

    items, total = await offer_service.list_offers(
        db_session, status=OfferStatus.publicada, categoria=OfferCategoria.nacional
    )
    assert total == 1
    assert items[0].titulo == "Oferta 0"

    items, total = await offer_service.list_offers(
        db_session, preco_min=Decimal("1500"), preco_max=Decimal("2500")
    )
    assert total == 1
    assert items[0].titulo == "Oferta 1"

    # Test search by title / destination
    items, total = await offer_service.list_offers(db_session, search="Oferta 2")
    assert total == 1
    assert items[0].titulo == "Oferta 2"

    items, total = await offer_service.list_offers(db_session, search="Destino")
    assert total == 3


@pytest.mark.asyncio
async def test_get_offer_by_id(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        titulo="Oferta Teste",
        destino="Teste",
        categoria=OfferCategoria.aventura,
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    found = await offer_service.get_offer_by_id(db_session, offer.id)
    assert found is not None
    assert found.titulo == "Oferta Teste"

    not_found = await offer_service.get_offer_by_id(db_session, uuid.uuid4())
    assert not_found is None


@pytest.mark.asyncio
async def test_update_offer(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        titulo="Original",
        destino="Original",
        categoria=OfferCategoria.outros,
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    updated = await offer_service.update_offer(
        db_session, offer, OfferUpdate(titulo="Atualizado")
    )
    assert updated.titulo == "Atualizado"


@pytest.mark.asyncio
async def test_publish_offer(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        titulo="Pub",
        destino="Pub",
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    published = await offer_service.publish_offer(db_session, offer, publish=True)
    assert published.status == OfferStatus.publicada

    unpublished = await offer_service.publish_offer(db_session, published, publish=False)
    assert unpublished.status == OfferStatus.rascunho


@pytest.mark.asyncio
async def test_soft_delete_offer(db_session):
    user_id = uuid.UUID("deadeade-dead-dead-dead-deadeadeadea")
    offer = Offer(
        titulo="Del",
        destino="Del",
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    await offer_service.soft_delete_offer(db_session, offer)
    assert offer.is_deleted is True

    found = await offer_service.get_offer_by_id(db_session, offer.id)
    assert found is None


@pytest.mark.asyncio
async def test_create_lead_from_interest(db_session):
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

    offer = Offer(
        titulo="Interesse",
        destino="Paris",
        status=OfferStatus.publicada,
        criado_por=user_id,
    )
    db_session.add(offer)
    await db_session.commit()

    lead = await offer_service.create_lead_from_interest(
        db_session, offer, user_id, user_phone="+5511988888888", user_name="Test User"
    )
    assert lead.telefone == "+5511988888888"

    # Eager-load briefing to avoid lazy-load in async SQLite test
    from sqlalchemy.orm import selectinload
    from sqlalchemy import select
    from app.models.lead import Lead

    result = await db_session.execute(
        select(Lead).where(Lead.id == lead.id).options(selectinload(Lead.briefing))
    )
    lead = result.scalar_one()
    assert lead.briefing is not None
    assert lead.briefing.destino == "Paris"
