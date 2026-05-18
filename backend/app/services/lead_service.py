import base64
import json
import uuid
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from app.presentation.schemas.leads import ManualLeadCreate

import structlog
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from sqlalchemy.exc import IntegrityError, ProgrammingError
from sqlalchemy.dialects.postgresql import insert
from app.application.services.lead_state_machine import LeadStateMachine
from app.application.services.lead_scoring_service import lead_scoring_service
from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus, TipoMensagem
from app.infrastructure.security.pii_encryption import hmac_hash
from app.domain.services.briefing_calculator import calculate_completude
from app.models.briefing import Briefing
from app.presentation.schemas.briefing_schema import BriefingExtracted
from app.models.interacao import Interacao
from app.models.lead import Lead
from app.models.lead_score_history import LeadScoreHistory
from app.domain.entities.enums import UserPerfil
from app.models.user import User
from app.services.whatsapp_service import SendResult

logger = structlog.get_logger()

SCORE_QUENTE_FIELDS = {"destino", "data_ida", "qtd_pessoas", "orcamento"}
ENGAJAMENTO_RAPIDO_MINUTOS = 30


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

        # Garante que o briefing exista
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


async def get_or_create_by_phone(
    db: AsyncSession, phone: str, name: Optional[str] = None
) -> Lead:
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
        await db.flush()

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


async def create_manual_lead(db: AsyncSession, data: "ManualLeadCreate") -> Lead:
    """
    Cria um lead manualmente via app da agência.
    Valida duplicidade, gera hashes de PII e calcula o score inicial.
    """
    from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
    from app.domain.entities.enums import OrcamentoPerfil

    repo = LeadRepository(db)
    phone_hash = hmac_hash(data.telefone)

    if not data.force_create:
        existing = await repo.find_active_by_phone(phone_hash)
        if existing:
            logger.warning("manual_lead_duplicate_attempt", phone=data.telefone, lead_id=str(existing.id))
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
            logger.debug("invalid_budget_string_mapping", value=data.orcamento_estimado)

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

    try:
        await db.commit()
        await db.refresh(lead)
        from app.services import metrics_service
        if lead.consultor_id:
            await metrics_service.invalidate_metrics_cache(lead.consultor_id)
        
        logger.info("manual_lead_created", lead_id=str(lead.id), phone=data.telefone, score=lead.score)
        return lead
    except Exception as e:
        await db.rollback()
        logger.error("error_creating_manual_lead", error=str(e))
        raise e


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


async def get_lead_metrics(db: AsyncSession) -> dict[str, int]:
    """Return aggregated lead counts by status for dashboard metrics."""
    total_ativos_stmt = (
        select(func.count()).select_from(Lead).where(Lead.is_archived.is_(False))
    )
    total_ativos = (await db.execute(total_ativos_stmt)).scalar_one()

    metrics: dict[str, int] = {"total_ativos": total_ativos}
    for st in LeadStatus:
        stmt = (
            select(func.count())
            .select_from(Lead)
            .where(Lead.is_archived.is_(False), Lead.status == st)
        )
        metrics[st.value] = (await db.execute(stmt)).scalar_one()
    return metrics


_ORDER_FIELDS = {
    "criado_em": Lead.criado_em,
    "atualizado_em": Lead.atualizado_em,
    "score": Lead.score,
    "status": Lead.status,
}


def _apply_lead_filters(
    query,
    status: Optional[str],
    score: Optional[str],
    search: Optional[str],
    consultor_id: Optional[uuid.UUID],
    data_inicio: Optional[datetime],
    data_fim: Optional[datetime],
):
    """Aplica filtros comuns a uma query de leads já com .where(is_archived=False)."""
    if status:
        query = query.where(Lead.status == status)
    if score:
        query = query.where(Lead.score == score)
    if consultor_id:
        query = query.where(Lead.consultor_id == consultor_id)
    if search:
        query = query.where(
            or_(Lead.nome.ilike(f"%{search}%"), Lead.telefone.ilike(f"%{search}%"))
        )
    if data_inicio:
        query = query.where(Lead.criado_em >= data_inicio)
    if data_fim:
        query = query.where(Lead.criado_em <= data_fim)
    return query


async def list_leads(
    db: AsyncSession,
    status: Optional[str] = None,
    score: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20,
    consultor_id: Optional[uuid.UUID] = None,
    data_inicio: Optional[datetime] = None,
    data_fim: Optional[datetime] = None,
    order_by: str = "criado_em",
    order_dir: str = "desc",
) -> tuple[list[Lead], int]:
    """Offset-based paginated list — backward-compatible default for GET /leads."""
    query = select(Lead).where(Lead.is_archived.is_(False))
    query = _apply_lead_filters(
        query, status, score, search, consultor_id, data_inicio, data_fim
    )

    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar_one()

    col = _ORDER_FIELDS.get(order_by, Lead.criado_em)
    order_expr = col.desc() if order_dir == "desc" else col.asc()
    query = (
        query.options(selectinload(Lead.briefing))
        .order_by(order_expr, Lead.id.desc())
        .offset((page - 1) * limit)
        .limit(limit)
    )
    result = await db.execute(query)
    return list(result.scalars().all()), total


def _encode_cursor(criado_em: datetime, lead_id: uuid.UUID) -> str:
    payload = json.dumps(
        {"ts": criado_em.isoformat(), "id": str(lead_id)}, separators=(",", ":")
    )
    return base64.urlsafe_b64encode(payload.encode()).decode()


def _decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    try:
        payload = json.loads(base64.urlsafe_b64decode(cursor.encode()).decode())
        ts = datetime.fromisoformat(payload["ts"])
        lead_id = uuid.UUID(payload["id"])
        return ts, lead_id
    except Exception as exc:
        raise ValueError(f"Cursor inválido: {exc}") from exc


async def list_leads_cursor(
    db: AsyncSession,
    limit: int = 20,
    cursor: Optional[str] = None,
    status: Optional[str] = None,
    score: Optional[str] = None,
    search: Optional[str] = None,
    consultor_id: Optional[uuid.UUID] = None,
    data_inicio: Optional[datetime] = None,
    data_fim: Optional[datetime] = None,
    order_by: str = "criado_em",
    order_dir: str = "desc",
) -> tuple[list[Lead], Optional[str]]:
    """Cursor-based paginated list for GET /leads?cursor=...

    Returns (items, next_cursor). next_cursor is None when no more pages exist.
    The cursor encodes (criado_em, id) of the last returned item so the query
    uses a keyset rather than OFFSET, avoiding page-drift on inserts.
    """
    query = select(Lead).where(Lead.is_archived.is_(False))
    query = _apply_lead_filters(
        query, status, score, search, consultor_id, data_inicio, data_fim
    )

    col = _ORDER_FIELDS.get(order_by, Lead.criado_em)

    if cursor:
        cursor_ts, cursor_id = _decode_cursor(cursor)
        if order_dir == "desc":
            query = query.where(
                or_(
                    col < cursor_ts,
                    and_(col == cursor_ts, Lead.id < cursor_id),
                )
            )
        else:
            query = query.where(
                or_(
                    col > cursor_ts,
                    and_(col == cursor_ts, Lead.id > cursor_id),
                )
            )

    order_expr = col.desc() if order_dir == "desc" else col.asc()
    id_order = Lead.id.desc() if order_dir == "desc" else Lead.id.asc()
    query = (
        query.options(selectinload(Lead.briefing))
        .order_by(order_expr, id_order)
        .limit(limit + 1)
    )

    result = await db.execute(query)
    rows = list(result.scalars().all())

    has_more = len(rows) > limit
    items = rows[:limit]

    next_cursor: Optional[str] = None
    if has_more and items:
        last = items[-1]
        next_cursor = _encode_cursor(last.criado_em, last.id)

    return items, next_cursor


async def _get_client_fcm_token(db: AsyncSession, lead: Lead) -> Optional[str]:
    """Finds the FCM token of the client User matching this lead's phone hash."""
    if not lead.telefone_hash:
        return None
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


async def update_lead_status(
    db: AsyncSession,
    lead: Lead,
    new_status: LeadStatus,
    triggered_by: str = "user_manual",
) -> Lead:
    old_status = lead.status
    if old_status == new_status:
        return lead

    lead.status = new_status
    await db.commit()
    await db.refresh(lead)

    from app.services import metrics_service
    if lead.consultor_id:
        await metrics_service.invalidate_metrics_cache(lead.consultor_id)

    logger.info(
        "lead_status_transition",
        lead_id=str(lead.id),
        old_status=(
            old_status.value if hasattr(old_status, "value") else str(old_status)
        ),
        new_status=(
            new_status.value if hasattr(new_status, "value") else str(new_status)
        ),
        triggered_by=triggered_by,
    )

    client_token = await _get_client_fcm_token(db, lead)
    if client_token:
        from app.services.fcm_service import notify_travel_status_change

        await notify_travel_status_change(
            fcm_token=client_token,
            new_status=new_status,
            lead_nome=lead.nome,
        )

    return lead


async def soft_delete(db: AsyncSession, lead: Lead) -> None:
    lead.is_archived = True
    lead.deletado_em = datetime.now(timezone.utc)
    await db.commit()


async def _persist_score(
    db: AsyncSession,
    lead: Lead,
    engajamento_rapido: bool = False,
    motivo: str = "auto",
) -> None:
    """Calcula score via LeadScoringService, persiste em leads e insere histórico."""
    ctx = lead_scoring_service.context_from_lead(
        lead, engajamento_rapido=engajamento_rapido, motivo=motivo
    )
    result = lead_scoring_service.calculate(ctx)

    lead.score = LeadScore(result.score_label)
    lead.score_numerico = result.score_numerico
    lead.score_calculado_em = datetime.now(timezone.utc)

    history_entry = LeadScoreHistory(
        id=uuid.uuid4(),
        lead_id=lead.id,
        score_numerico=result.score_numerico,
        score_label=result.score_label,
        motivo=result.motivo,
        criterios_json=result.criterios_json,
    )
    db.add(history_entry)

    logger.info(
        "lead_score_calculated",
        lead_id=str(lead.id),
        score_numerico=result.score_numerico,
        score_label=result.score_label,
        motivo=motivo,
    )


def _is_engajamento_rapido(interacoes: list) -> bool:
    """True se a penúltima interação e a última têm gap < 30 min (cliente respondeu rápido)."""
    timestamps = [
        getattr(i, "timestamp", None)
        for i in interacoes
        if getattr(i, "timestamp", None) is not None
    ]
    if len(timestamps) < 2:
        return False
    timestamps_sorted = sorted(timestamps)
    delta = timestamps_sorted[-1] - timestamps_sorted[-2]
    return delta.total_seconds() < ENGAJAMENTO_RAPIDO_MINUTOS * 60


async def update_briefing_from_extraction(
    db: AsyncSession, lead: Lead, extracted: BriefingExtracted
) -> Briefing:
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
        await update_lead_status(
            db, lead, LeadStatus.qualificado, triggered_by="ai_auto"
        )
        logger.info(
            "lead_qualified", lead_id=str(lead.id), completude=briefing.completude_pct
        )

    interacoes_result = await db.execute(
        select(Interacao).where(Interacao.lead_id == lead.id).order_by(Interacao.timestamp.desc()).limit(2)
    )
    recent = list(interacoes_result.scalars().all())
    engajamento = _is_engajamento_rapido(recent)
    await _persist_score(db, lead, engajamento_rapido=engajamento, motivo="auto")

    await db.commit()
    await db.refresh(briefing)
    await db.refresh(lead)

    all_fields = ["destino", "data_ida", "data_volta", "qtd_pessoas", "perfil",
                  "tipo_viagem", "preferencias", "orcamento", "tem_passaporte"]
    filled = sum(1 for f in all_fields if getattr(briefing, f, None) not in (None, [], ""))
    if briefing.completude_pct > 40 and filled >= 5:
        from app.services.checkpoint_service import activate_checkpoint, SISTEMA
        from app.domain.entities.enums import TravelCheckpoint
        await activate_checkpoint(db, lead.id, TravelCheckpoint.briefing_coletado, SISTEMA)

    return briefing


async def save_interacao(
    db: AsyncSession,
    lead_id: uuid.UUID,
    msg_cliente: Optional[str],
    msg_ia: Optional[str],
    tipo: TipoMensagem = TipoMensagem.texto,
    whatsapp_message_id: Optional[str] = None,
) -> Interacao:
    if whatsapp_message_id:
        existing = await db.execute(
            select(Interacao).where(Interacao.whatsapp_message_id == whatsapp_message_id)
        )
        duplicate = existing.scalar_one_or_none()
        if duplicate:
            logger.warning("webhook_replay_detected", message_id=whatsapp_message_id, lead_id=str(lead_id))
            return duplicate

    interacao = Interacao(
        lead_id=lead_id,
        mensagem_cliente=msg_cliente,
        mensagem_ia=msg_ia,
        tipo_mensagem=tipo,
        whatsapp_message_id=whatsapp_message_id,
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
        {
            "mensagem_cliente": r.mensagem_cliente,
            "mensagem_ia": r.mensagem_ia,
            "timestamp": r.timestamp,
        }
        for r in reversed(rows)
    ]


async def get_user_by_id(db: AsyncSession, user_id: str):
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    return result.scalar_one_or_none()


async def mark_stale_leads_as_perdido(
    db: AsyncSession, inactivity_days: int = 30
) -> int:
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

    latest_interacao_subq = (
        select(
            Interacao.lead_id.label("lead_id"),
            func.max(Interacao.timestamp).label("last_interaction"),
        )
        .group_by(Interacao.lead_id)
        .subquery()
    )

    stmt = (
        select(Lead)
        .where(Lead.is_archived.is_(False))
        .where(Lead.status.notin_([LeadStatus.perdido.value, LeadStatus.fechado.value]))
        .outerjoin(latest_interacao_subq, Lead.id == latest_interacao_subq.c.lead_id)
        .where(
            func.coalesce(latest_interacao_subq.c.last_interaction, Lead.criado_em)
            < cutoff
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
