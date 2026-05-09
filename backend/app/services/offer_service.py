import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional

import structlog
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadStatus, OfferStatus
from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter
from app.infrastructure.config.settings import get_settings
from app.models.lead import Lead
from app.models.offer import Offer
from app.presentation.schemas.offer_schema import OfferCreate, OfferUpdate
from app.services import lead_service
from app.services.documento_service import _validate_magic_bytes

logger = structlog.get_logger()
settings = get_settings()

_MAX_IMAGES = 5
_MAX_IMAGE_SIZE_MB = 5
_ALLOWED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}


def _validate_image(file: UploadFile, content: bytes) -> None:
    if file.content_type not in _ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo de imagem não permitido: {file.content_type}",
        )
    if not _validate_magic_bytes(content, file.content_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Conteúdo da imagem não corresponde ao tipo declarado.",
        )


async def _upload_images_to_s3(
    offer_id: uuid.UUID,
    images: list[UploadFile],
) -> list[str]:
    storage = S3StorageAdapter()
    urls: list[str] = []
    uploaded_keys: list[str] = []

    for idx, file in enumerate(images):
        content = await file.read()
        _validate_image(file, content)
        if len(content) > _MAX_IMAGE_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
                detail=f"Imagem {file.filename} excede {_MAX_IMAGE_SIZE_MB}MB",
            )

        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        object_key = f"offers/{offer_id}/{idx}_{uuid.uuid4().hex}.{ext}"

        success = await storage.upload_file(
            file_content=content,
            object_key=object_key,
            content_type=file.content_type or "image/jpeg",
        )
        if not success:
            # Compensação: apaga uploads parciais em caso de falha
            for key in uploaded_keys:
                await storage.delete_file(key)
                logger.warning("s3_partial_rollback", object_key=key, offer_id=str(offer_id))
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Falha no upload de imagem",
            )

        uploaded_keys.append(object_key)

        # Prefer presigned URL if available, otherwise build a direct URL
        presigned = await storage.generate_presigned_url(object_key, expires_in=86400 * 7)
        urls.append(presigned or f"{settings.S3_ENDPOINT_URL or ''}/{settings.S3_BUCKET_NAME}/{object_key}")

    return urls


async def create_offer(
    db: AsyncSession,
    data: OfferCreate,
    images: list[UploadFile],
    user_id: uuid.UUID,
) -> Offer:
    if len(images) > _MAX_IMAGES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Máximo de {_MAX_IMAGES} imagens permitidas",
        )

    offer = Offer(
        titulo=data.titulo,
        destino=data.destino,
        descricao=data.descricao,
        categoria=data.categoria,
        preco_base=data.preco_base,
        servicos_inclusos=data.servicos_inclusos or [],
        data_saida_sugerida=data.data_saida_sugerida,
        duracao_dias=data.duracao_dias,
        status=OfferStatus.rascunho,
        criado_por=user_id,
    )
    db.add(offer)
    await db.flush()

    if images:
        offer.imagens = await _upload_images_to_s3(offer.id, images)

    await db.commit()
    await db.refresh(offer)
    logger.info("offer_created", offer_id=str(offer.id), user_id=str(user_id))
    return offer


async def list_offers(
    db: AsyncSession,
    status: Optional[OfferStatus] = None,
    categoria: Optional[OfferCategoria] = None,
    preco_min: Optional[Decimal] = None,
    preco_max: Optional[Decimal] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
) -> tuple[list[Offer], int]:
    query = select(Offer).where(Offer.is_deleted.is_(False))

    if status:
        query = query.where(Offer.status == status)
    if categoria:
        query = query.where(Offer.categoria == categoria)
    if preco_min is not None:
        query = query.where(Offer.preco_base >= preco_min)
    if preco_max is not None:
        query = query.where(Offer.preco_base <= preco_max)
    if search:
        query = query.where(
            (Offer.titulo.ilike(f"%{search}%")) | (Offer.destino.ilike(f"%{search}%"))
        )

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar_one()

    query = (
        query.order_by(Offer.criado_em.desc())
        .offset((page - 1) * limit)
        .limit(limit)
    )
    result = await db.execute(query)
    return list(result.scalars().all()), total


async def get_offer_by_id(db: AsyncSession, offer_id: uuid.UUID) -> Optional[Offer]:
    result = await db.execute(
        select(Offer).where(Offer.id == offer_id, Offer.is_deleted.is_(False))
    )
    return result.scalar_one_or_none()


def _extract_s3_key_from_url(url: str) -> Optional[str]:
    """Extract S3 object key from a presigned or direct S3 URL."""
    bucket = settings.S3_BUCKET_NAME
    if f"/{bucket}/" in url:
        return url.split(f"/{bucket}/", 1)[1]
    return None


async def _delete_images_from_s3(urls: list[str]) -> None:
    storage = S3StorageAdapter()
    for url in urls:
        key = _extract_s3_key_from_url(url)
        if key:
            await storage.delete_file(key)
            logger.info("s3_image_deleted", object_key=key)


async def update_offer(
    db: AsyncSession,
    offer: Offer,
    data: OfferUpdate,
    images: Optional[list[UploadFile]] = None,
) -> Offer:
    if images:
        if len(images) > _MAX_IMAGES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Máximo de {_MAX_IMAGES} imagens permitidas",
            )
        # Cleanup old images before uploading replacements
        old_images = offer.imagens or []
        if old_images:
            await _delete_images_from_s3(old_images)
        offer.imagens = await _upload_images_to_s3(offer.id, images)

    update_data = data.model_dump(exclude_none=True)
    for field, value in update_data.items():
        if field == "imagens":
            # URL list replacement (no file upload) — cleanup old S3 objects
            old_images = offer.imagens or []
            if old_images and value != old_images:
                await _delete_images_from_s3(old_images)
            offer.imagens = value or []
        elif hasattr(offer, field):
            setattr(offer, field, value)

    offer.atualizado_em = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(offer)
    logger.info("offer_updated", offer_id=str(offer.id))
    return offer


async def publish_offer(
    db: AsyncSession,
    offer: Offer,
    publish: bool,
) -> Offer:
    offer.status = OfferStatus.publicada if publish else OfferStatus.rascunho
    offer.atualizado_em = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(offer)
    logger.info(
        "offer_publish_toggled",
        offer_id=str(offer.id),
        status=offer.status.value,
    )
    return offer


async def soft_delete_offer(db: AsyncSession, offer: Offer) -> None:
    offer.is_deleted = True
    offer.atualizado_em = datetime.now(timezone.utc)
    await db.commit()
    logger.info("offer_soft_deleted", offer_id=str(offer.id))


async def create_lead_from_interest(
    db: AsyncSession,
    offer: Offer,
    user_id: uuid.UUID,
    user_phone: Optional[str],
    user_name: Optional[str],
) -> Lead:
    if not user_phone:
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Usuário não possui telefone cadastrado para criar lead",
        )

    lead = await lead_service.get_or_create_by_phone(db, user_phone, user_name)

    # Eager-load briefing to avoid lazy-load in async context
    from sqlalchemy.orm import selectinload

    result = await db.execute(
        select(Lead).where(Lead.id == lead.id).options(selectinload(Lead.briefing))
    )
    lead = result.scalar_one()

    # If lead is new or generic, enrich with offer context
    if lead.status in (LeadStatus.novo, LeadStatus.em_atendimento):
        lead.status = LeadStatus.em_atendimento
        # Update briefing with offer destination if available
        if lead.briefing and not lead.briefing.destino:
            lead.briefing.destino = offer.destino
        await db.commit()
        await db.refresh(lead)

    logger.info(
        "lead_created_from_offer_interest",
        lead_id=str(lead.id),
        offer_id=str(offer.id),
        user_id=str(user_id),
    )
    return lead
