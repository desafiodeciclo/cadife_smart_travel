import uuid
from typing import Optional

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.enums import LeadScore, LeadStatus, TipoMensagem
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import Briefing, BriefingExtracted, calculate_completude
from app.models.interacao import Interacao
from app.models.lead import Lead

logger = structlog.get_logger()

SCORE_QUENTE_FIELDS = {"destino", "data_ida", "qtd_pessoas", "orcamento"}
SCORE_MORNO_FIELDS = {"destino"}


def _score_from_briefing(briefing: Briefing) -> LeadScore:
    data = {
        "destino": briefing.destino,
        "data_ida": briefing.data_ida,
        "qtd_pessoas": briefing.qtd_pessoas,
        "orcamento": briefing.orcamento,
    }
    filled_hot = sum(1 for f in SCORE_QUENTE_FIELDS if data.get(f) not in (None, ""))
    if filled_hot == len(SCORE_QUENTE_FIELDS):
        return LeadScore.quente
    if briefing.destino:
        return LeadScore.morno
    return LeadScore.frio


async def get_or_create_by_phone(db: AsyncSession, phone: str, name: Optional[str] = None) -> Lead:
    phone_hash = hmac_hash(phone)
    result = await db.execute(select(Lead).where(Lead.telefone_hash == phone_hash))
    lead = result.scalar_one_or_none()
    if lead:
        return lead

    lead = Lead(
        telefone=phone,
        telefone_hash=phone_hash,
        nome=name,
        status=LeadStatus.novo,
    )
    db.add(lead)
    briefing = Briefing(lead=lead)
    db.add(briefing)
    await db.commit()
    await db.refresh(lead)
    logger.info("lead_created", lead_id=str(lead.id), phone=phone)
    return lead


async def get_lead_by_id(db: AsyncSession, lead_id: uuid.UUID) -> Optional[Lead]:
    result = await db.execute(select(Lead).where(Lead.id == lead_id, Lead.is_archived == False))
    return result.scalar_one_or_none()


async def list_leads(
    db: AsyncSession,
    status: Optional[str] = None,
    score: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    consultor_id: Optional[uuid.UUID] = None,
) -> tuple[list[Lead], int]:
    query = select(Lead).where(Lead.is_archived == False)
    if status:
        query = query.where(Lead.status == status)
    if score:
        query = query.where(Lead.score == score)
    if consultor_id:
        query = query.where(Lead.consultor_id == consultor_id)
    if search:
        query = query.where(
            (Lead.nome.ilike(f"%{search}%")) | (Lead.telefone.ilike(f"%{search}%"))
        )

    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar_one()

    query = query.order_by(Lead.criado_em.desc()).offset((page - 1) * limit).limit(limit)
    result = await db.execute(query)
    return list(result.scalars().all()), total


async def update_lead_status(db: AsyncSession, lead: Lead, new_status: LeadStatus) -> Lead:
    lead.status = new_status
    await db.commit()
    await db.refresh(lead)
    return lead


async def soft_delete(db: AsyncSession, lead: Lead) -> None:
    lead.is_archived = True
    await db.commit()


async def update_briefing_from_extraction(
    db: AsyncSession, lead: Lead, extracted: BriefingExtracted
) -> Briefing:
    # Busca explícita para evitar lazy load em contexto async
    result = await db.execute(select(Briefing).where(Briefing.lead_id == lead.id))
    briefing = result.scalar_one_or_none()
    if briefing is None:
        briefing = Briefing(lead_id=lead.id)
        db.add(briefing)

    for field, value in extracted.model_dump(exclude={"completude_pct"}).items():
        if value not in (None, [], ""):
            setattr(briefing, field, value)

    briefing.completude_pct = calculate_completude(briefing.__dict__)
    lead.score = _score_from_briefing(briefing)

    if briefing.completude_pct >= 60 and lead.status == LeadStatus.em_atendimento:
        lead.status = LeadStatus.qualificado
        logger.info("lead_qualified", lead_id=str(lead.id), completude=briefing.completude_pct)

    await db.commit()
    await db.refresh(briefing)
    return briefing


async def save_interacao(
    db: AsyncSession,
    lead_id: uuid.UUID,
    msg_cliente: Optional[str],
    msg_ia: Optional[str],
    tipo: TipoMensagem = TipoMensagem.texto,
) -> Interacao:
    interacao = Interacao(
        lead_id=lead_id,
        mensagem_cliente=msg_cliente,
        mensagem_ia=msg_ia,
        tipo_mensagem=tipo,
    )
    db.add(interacao)
    await db.commit()
    return interacao


async def get_user_by_id(db: AsyncSession, user_id: str):
    from app.models.user import User
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()
