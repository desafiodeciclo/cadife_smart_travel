import base64
import json
import uuid
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from app.presentation.schemas.leads import ManualLeadCreate

import structlog
from sqlalchemy import and_, func, or_, select, tuple_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from sqlalchemy.exc import IntegrityError, ProgrammingError
from sqlalchemy.dialects.postgresql import insert
from app.application.services.lead_state_machine import LeadStateMachine
from app.application.services.lead_scoring_service import (
    lead_scoring_service,
    ScoringContext,
)
from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus, TipoMensagem
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import Briefing, BriefingExtracted, calculate_completude
from app.models.interacao import Interacao
from app.models.lead import Lead
from app.models.lead_score_history import LeadScoreHistory
from app.models.user import User, UserPerfil
from app.services.whatsapp_service import SendResult

logger = structlog.get_logger()

SCORE_QUENTE_FIELDS = {"destino", "data_ida", "qtd_pessoas", "orcamento"}
ENGAJAMENTO_RAPIDO_MINUTOS = 30


def calculate_score_from_briefing(briefing: Briefing | None) -> LeadScore | None:
    """Compute lead temperature score from briefing data (spec.md §8.3)."""
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
    """Implementa a estratégia de Upsert (Update or Insert) com resiliência."""
    try:
        phone = lead_data.get("telefone")
        if not phone:
            raise ValueError("Telefone é obrigatório para upsert de lead")

        phone_hash = hmac_hash(phone)

        stmt = (
            insert(Lead)
            .values(
                telefone=phone,
                telefone_hash=phone_hash,
                nome=lead_data.get("nome"),
                status=lead_data.get("status", LeadStatus.novo),
                origem=lead_data.get("origem", LeadOrigem.whatsapp),
            )
            .on_conflict_do_update(
                index_elements=[Lead.telefone_hash],
                set_={"nome": lead_data.get("nome"), "atualizado_em": func.now()},
            )
            .returning(Lead)
        )

        result = await db.execute(stmt)
        lead = result.scalar_one()

        briefing_stmt = (
            insert(Briefing)
            .values(lead_id=lead.id, completude_pct=0)
            .on_conflict_do_nothing()
        )
        await db.execute(briefing_stmt)

        await db.commit()
        await db.refresh(lead)
        return lead

    except ProgrammingError as e:
        if 'relation "leads" does not exist' in str(e):
            logger.error("database_table_missing", table="leads", error=str(e))
            raise RuntimeError("Banco de dados não inicializado. Execute as migrações.")
        raise e
    except IntegrityError as e:
        await db.rollback()
        logger.warning("integrity_error_during_upsert", error=str(e))
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

        lead = Lead(telefone=phone, telefone_hash=phone_hash, nome=name, status=LeadStatus.novo)
        db.add(lead)
        await db.flush()

        briefing = Briefing(lead_id=lead.id)
        db.add(briefing)

        await db.commit()
        await db.refresh(lead)
        return lead
    except Exception as e:
        await db.rollback()
        logger.error("error_get_or_create_lead", phone=phone, error=str(e))
        raise e


async def create_manual_lead(db: AsyncSession, data: "ManualLeadCreate") -> Lead:
    from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
    from app.domain.entities.enums import OrcamentoPerfil

    repo = LeadRepository(db)
    phone_hash = hmac_hash(data.telefone)

    if not data.force_create:
        existing = await repo.find_active_by_phone(phone_hash)
        if existing:
            raise ValueError(f"DUPLICATE_LEAD:{existing.id}")

    lead = Lead(
        id=uuid.uuid4(),
        nome=data.nome,
        telefone=data.telefone,
        telefone_hash=phone_hash,
        origem=data.origem,
        status=LeadStatus.novo,
        consultor_id=data.consultor_id,
        criado_em=datetime.now(timezone.utc)
    )
    db.add(lead)
    await db.flush()

    orcamento_enum = None
    if data.orcamento_estimado:
        try:
            orcamento_enum = OrcamentoPerfil(data.orcamento_estimado.lower())
        except ValueError:
            pass

    briefing = Briefing(
        lead_id=lead.id,
        destino=data.destino_interesse,
        orcamento=orcamento_enum,
        qtd_pessoas=data.numero_passageiros,
        observacoes=f"Data aproximada: {data.datas_aproximadas}" if data.datas_aproximadas else None
    )

    lead.score = calculate_score_from_briefing(briefing)
    briefing.completude_pct = calculate_completude(briefing.__dict__)
    lead.briefing = briefing
    db.add(briefing)
    
    await db.commit()
    await db.refresh(lead)
    return lead


async def get_lead_by_id(db: AsyncSession, lead_id: uuid.UUID) -> Optional[Lead]:
    result = await db.execute(
        select(Lead)
        .where(Lead.id == lead_id, Lead.is_archived.is_(False))
        .options(
            selectinload(Lead.briefing),
            selectinload(Lead.consultor),
            selectinload(Lead.propostas),
            selectinload(Lead.interacoes),
        )
    )
    return result.scalar_one_or_none()


# --- PAGINAÇÃO E FILTROS ---

_ORDER_FIELDS = {
    "criado_em": Lead.criado_em,
    "atualizado_em": Lead.atualizado_em,
    "score": Lead.score,
    "status": Lead.status,
}

def _apply_lead_filters(query, status, score, search, consultor_id, data_inicio, data_fim):
    if status: query = query.where(Lead.status == status)
    if score: query = query.where(Lead.score == score)
    if consultor_id: query = query.where(Lead.consultor_id == consultor_id)
    if search:
        query = query.where(or_(Lead.nome.ilike(f"%{search}%"), Lead.telefone.ilike(f"%{search}%")))
    if data_inicio: query = query.where(Lead.criado_em >= data_inicio)
    if data_fim: query = query.where(Lead.criado_em <= data_fim)
    return query


def _encode_cursor(criado_em: datetime, lead_id: uuid.UUID) -> str:
    payload = json.dumps({"ts": criado_em.isoformat(), "id": str(lead_id)}, separators=(",", ":"))
    return base64.urlsafe_b64encode(payload.encode()).decode()


def _decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        payload = json.loads(base64.urlsafe_b64decode(cursor.encode()).decode())
        return datetime.fromisoformat(payload["ts"]), uuid.UUID(payload["id"])
    except Exception as exc:
        raise ValueError(f"Cursor inválido: {exc}")


async def list_leads_cursor(
    db: AsyncSession, limit: int = 20, cursor: Optional[str] = None, **filters
) -> tuple[list[Lead], Optional[str]]:
    query = select(Lead).where(Lead.is_archived.is_(False))
    query = _apply_lead_filters(query, **filters)
    
    col = _ORDER_FIELDS.get(filters.get("order_by"), Lead.criado_em)
    order_dir = filters.get("order_dir", "desc")

    if cursor:
        c_ts, c_id = _decode_cursor(cursor)
        if order_dir == "desc":
            query = query.where(or_(col < c_ts, and_(col == c_ts, Lead.id < c_id)))
        else:
            query = query.where(or_(col > c_ts, and_(col == c_ts, Lead.id > c_id)))

    order_expr = col.desc() if order_dir == "desc" else col.asc()
    id_order = Lead.id.desc() if order_dir == "desc" else Lead.id.asc()
    
    result = await db.execute(query.options(selectinload(Lead.briefing)).order_by(order_expr, id_order).limit(limit + 1))
    rows = list(result.scalars().all())
    
    has_more = len(rows) > limit
    items = rows[:limit]
    next_c = _encode_cursor(items[-1].criado_em, items[-1].id) if has_more and items else None
    return items, next_c


# --- NOTIFICAÇÕES E ESTADOS ---

async def _get_client_fcm_token(db: AsyncSession, lead: Lead) -> Optional[str]:
    """Busca o token FCM do cliente associado ao lead (via telefone_hash)."""
    if not lead.telefone_hash: return None
    result = await db.execute(
        select(User).where(
            User.perfil == UserPerfil.cliente.value,
            User.telefone.isnot(None),
            User.fcm_token.isnot(None),
        )
    )
    for user in result.scalars().all():
        if user.telefone and hmac_hash(user.telefone) == lead.telefone_hash:
            return user.fcm_token
    return None


async def update_lead_status(db: AsyncSession, lead: Lead, new_status: LeadStatus, triggered_by: str = "user_manual") -> Lead:
    old_status = lead.status
    if old_status == new_status: return lead
    
    lead.status = new_status
    await db.commit()
    await db.refresh(lead)

    logger.info("lead_status_transition", lead_id=str(lead.id), old=str(old_status), new=str(new_status))

    # Notificação Push via FCM
    client_token = await _get_client_fcm_token(db, lead)
    if client_token:
        from app.services.fcm_service import notify_travel_status_change
        await notify_travel_status_change(fcm_token=client_token, new_status=new_status, lead_nome=lead.nome)

    return lead


async def update_briefing_from_extraction(db: AsyncSession, lead: Lead, extracted: BriefingExtracted) -> Briefing:
    result = await db.execute(select(Briefing).where(Briefing.lead_id == lead.id))
    briefing = result.scalar_one_or_none() or Briefing(lead_id=lead.id)
    if not briefing.id: db.add(briefing)

    for field, value in extracted.model_dump().items():
        if value not in (None, [], ""): setattr(briefing, field, value)

    briefing.completude_pct = calculate_completude(briefing.__dict__)
    lead.score = calculate_score_from_briefing(briefing)

    if briefing.completude_pct >= 60 and lead.status == LeadStatus.em_atendimento:
        await update_lead_status(db, lead, LeadStatus.qualificado, triggered_by="ai_auto")

    lead.briefing = briefing
    
    # Score numérico e histórico
    interacoes_result = await db.execute(select(Interacao).where(Interacao.lead_id == lead.id).order_by(Interacao.timestamp.desc()).limit(2))
    engajamento = _is_engajamento_rapido(list(interacoes_result.scalars().all()))
    await _persist_score(db, lead, engajamento_rapido=engajamento, motivo="auto")

    await db.commit()
    await db.refresh(briefing)
    return briefing

async def mark_stale_leads_as_perdido(db: AsyncSession, inactivity_days: int) -> int:
    """
    Mark leads inactive for more than *inactivity_days* as PERDIDO.
    Leads already in PERDIDO, FECHADO, or archived are ignored.
    Returns the number of leads transitioned.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=inactivity_days)

    # Query: leads not PERDIDO/FECHADO, not archived,
    # with last interaction older than cutoff (or no interactions and created before cutoff)
    from sqlalchemy.orm import joinedload

    result = await db.execute(
        select(Lead)
        .options(joinedload(Lead.interacoes))
        .where(
            Lead.status.not_in([LeadStatus.perdido, LeadStatus.fechado]),
            Lead.is_archived.is_(False),
            or_(
                and_(
                    Lead.interacoes.any(),
                    ~Lead.interacoes.any(Interacao.timestamp >= cutoff),
                ),
                and_(
                    ~Lead.interacoes.any(),
                    Lead.criado_em < cutoff,
                ),
            ),
        )
    )
    stale_leads = result.unique().scalars().all()

    count = 0
    for lead in stale_leads:
        LeadStateMachine.validate_transition(lead.status, LeadStatus.perdido)
        lead.status = LeadStatus.perdido
        count += 1

    if count > 0:
        await db.commit()

    return count