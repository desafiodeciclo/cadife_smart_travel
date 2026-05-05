import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from sqlalchemy.exc import IntegrityError, ProgrammingError
from sqlalchemy.dialects.postgresql import insert
from app.application.services.lead_state_machine import LeadStateMachine
from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus, TipoMensagem
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import Briefing, BriefingExtracted, calculate_completude
from app.models.interacao import Interacao
from app.models.lead import Lead
from app.services.whatsapp_service import SendResult

logger = structlog.get_logger()

SCORE_QUENTE_FIELDS = {"destino", "data_ida", "qtd_pessoas", "orcamento"}


def calculate_score_from_briefing(briefing: Briefing | None) -> LeadScore | None:
    """
    Compute lead temperature score from briefing data (spec.md §8.3).

    Rules:
      - QUENTE: destino + data_ida + qtd_pessoas + orcamento all defined
      - MORNO:  destino defined but at least one hot field missing
      - FRIO:   destino not defined (insufficient data)

    Returns None when no briefing is present.
    """
    if briefing is None:
        return None

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


async def upsert_lead_with_resilience(db: AsyncSession, lead_data: dict) -> Lead:
    """
    Implementa a estratégia de Upsert (Update or Insert) com resiliência.
    Trata erros de integridade e tabelas inexistentes (fail-safe).
    """
    try:
        phone = lead_data.get("telefone")
        if not phone:
            raise ValueError("Telefone é obrigatório para upsert de lead")
            
        phone_hash = hmac_hash(phone)
        
        # Tenta inserir ou atualizar no conflito do telefone_hash
        stmt = insert(Lead).values(
            telefone=phone,
            telefone_hash=phone_hash,
            nome=lead_data.get("nome"),
            status=lead_data.get("status", LeadStatus.novo),
            origem=lead_data.get("origem", LeadOrigem.whatsapp)
        ).on_conflict_do_update(
            index_elements=[Lead.telefone_hash],
            set_={
                "nome": lead_data.get("nome"),
                "atualizado_em": func.now()
            }
        ).returning(Lead)
        
        result = await db.execute(stmt)
        lead = result.scalar_one()
        
        # Garante que o briefing exista
        briefing_stmt = insert(Briefing).values(
            lead_id=lead.id,
            completude_pct=0
        ).on_conflict_do_nothing()
        await db.execute(briefing_stmt)
        
        await db.commit()
        await db.refresh(lead)
        return lead
        
    except ProgrammingError as e:
        if "relation \"leads\" does not exist" in str(e):
            logger.error("database_table_missing", table="leads", error=str(e))
            # Fallback ou raise informativo
            raise RuntimeError("Banco de dados não inicializado. Execute as migrações.")
        raise e
    except IntegrityError as e:
        await db.rollback()
        logger.warning("integrity_error_during_upsert", error=str(e))
        # Se falhar o upsert atômico, tenta o fallback manual (get or update)
        return await get_or_create_by_phone(db, phone, lead_data.get("nome"))
    except Exception as e:
        await db.rollback()
        logger.error("unexpected_error_in_upsert", error=str(e))
        raise e


async def get_or_create_by_phone(db: AsyncSession, phone: str, name: Optional[str] = None) -> Lead:
    try:
        phone_hash = hmac_hash(phone)
        result = await db.execute(select(Lead).where(Lead.telefone_hash == phone_hash))
        lead = result.scalar_one_or_none()
        if lead:
            if name and not lead.nome:
                lead.nome = name
                await db.commit()
            return lead

        lead = Lead(
            telefone=phone,
            telefone_hash=phone_hash,
            nome=name,
            status=LeadStatus.novo,
        )
        db.add(lead)
        await db.flush() # Para pegar o ID do lead sem commit total ainda
        
        briefing = Briefing(lead_id=lead.id)
        db.add(briefing)
        
        await db.commit()
        await db.refresh(lead)
        logger.info("lead_created", lead_id=str(lead.id), phone=phone)
        return lead
    except Exception as e:
        await db.rollback()
        logger.error("error_get_or_create_lead", phone=phone, error=str(e))
        raise e


async def get_lead_by_id(db: AsyncSession, lead_id: uuid.UUID) -> Optional[Lead]:
    result = await db.execute(select(Lead).where(Lead.id == lead_id, Lead.is_archived.is_(False)))
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
    query = select(Lead).where(Lead.is_archived.is_(False))
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


async def update_lead_status(
    db: AsyncSession, 
    lead: Lead, 
    new_status: LeadStatus,
    triggered_by: str = "user_manual"
) -> Lead:
    old_status = lead.status
    if old_status == new_status:
        return lead
        
    lead.status = new_status
    await db.commit()
    await db.refresh(lead)
    
    logger.info(
        "lead_status_transition",
        lead_id=str(lead.id),
        old_status=old_status.value if hasattr(old_status, 'value') else str(old_status),
        new_status=new_status.value if hasattr(new_status, 'value') else str(new_status),
        triggered_by=triggered_by
    )
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

    for field, value in extracted.model_dump().items():
        if value not in (None, [], ""):
            setattr(briefing, field, value)

    briefing.completude_pct = calculate_completude(briefing.__dict__)
    lead.score = calculate_score_from_briefing(briefing)

    if briefing.completude_pct >= 60 and lead.status == LeadStatus.em_atendimento:
        await update_lead_status(db, lead, LeadStatus.qualificado, triggered_by="ai_auto")
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


async def update_interacao_send_result(
    db: AsyncSession,
    interacao: Interacao,
    result: SendResult,
) -> None:
    """Persist outbound WhatsApp send outcome — spec §9.1 / §12.1."""
    interacao.enviado_em = datetime.now(timezone.utc) if result.success else None
    interacao.status_envio = "sent" if result.success else "failed"
    interacao.erro_envio = result.error if not result.success else None
    await db.commit()


async def get_recent_interacoes(
    db: AsyncSession,
    lead_id: uuid.UUID,
    limit: int = 20,
) -> list[dict]:
    """Return the most recent interactions for a lead as plain dicts (oldest-first).

    Used to hydrate conversation memory after a server restart.
    """
    stmt = (
        select(Interacao)
        .where(Interacao.lead_id == lead_id)
        .order_by(Interacao.timestamp.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    rows = list(result.scalars().all())
    return [
        {"mensagem_cliente": r.mensagem_cliente, "mensagem_ia": r.mensagem_ia}
        for r in reversed(rows)
    ]


async def get_user_by_id(db: AsyncSession, user_id: str):
    from app.models.user import User
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()


async def mark_stale_leads_as_perdido(db: AsyncSession, inactivity_days: int = 30) -> int:
    """
    Transition leads without client response for `inactivity_days` to PERDIDO.

    A lead is considered stale when:
      - not archived, not already perdido or fechado
      - its most recent interaction (or creation date if no interactions) is
        older than `inactivity_days` days.

    Returns:
        Number of leads transitioned.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=inactivity_days)

    # Subquery: latest interaction timestamp per lead
    latest_interacao_subq = (
        select(
            Interacao.lead_id.label("lead_id"),
            func.max(Interacao.timestamp).label("last_interaction"),
        )
        .group_by(Interacao.lead_id)
        .subquery()
    )

    # Lead qualifies if:
    #   - not archived
    #   - status NOT IN (perdido, fechado)
    #   - COALESCE(last_interaction, criado_em) < cutoff
    stmt = (
        select(Lead)
        .where(Lead.is_archived.is_(False))
        .where(Lead.status.notin_([LeadStatus.perdido.value, LeadStatus.fechado.value]))
        .outerjoin(latest_interacao_subq, Lead.id == latest_interacao_subq.c.lead_id)
        .where(
            func.coalesce(latest_interacao_subq.c.last_interaction, Lead.criado_em) < cutoff
        )
    )

    result = await db.execute(stmt)
    stale_leads = list(result.scalars().all())

    count = 0
    for lead in stale_leads:
        previous_status = lead.status
        LeadStateMachine.validate_transition(previous_status, LeadStatus.perdido)
        lead.status = LeadStatus.perdido
        count += 1
        logger.info(
            "lead_status_changed",
            lead_id=str(lead.id),
            previous_status=previous_status.value,
            new_status=LeadStatus.perdido.value,
            reason=f"no_response_for_{inactivity_days}_days",
            actor="sistema/rotina_automatica",
        )

    if count:
        await db.commit()
    return count
