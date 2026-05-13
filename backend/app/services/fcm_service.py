import asyncio
from typing import Optional

import structlog

from app.domain.entities.enums import LeadStatus

logger = structlog.get_logger()

_firebase_initialized = False

_STATUS_MESSAGES: dict[LeadStatus, tuple[str, str]] = {
    LeadStatus.qualificado: (
        "Novidade sobre sua viagem",
        "Suas informações foram recebidas! Um consultor entrará em contato em breve.",
    ),
    LeadStatus.agendado: (
        "Atendimento agendado",
        "Seu atendimento foi agendado. Em breve você receberá mais detalhes.",
    ),
    LeadStatus.proposta: (
        "Proposta disponível",
        "Você tem uma nova proposta de viagem disponível!",
    ),
    LeadStatus.fechado: (
        "Viagem confirmada",
        "Parabéns! Sua viagem foi confirmada.",
    ),
}


def _init_firebase() -> bool:
    global _firebase_initialized
    if _firebase_initialized:
        return True
    try:
        import firebase_admin
        from firebase_admin import credentials
        from app.core.config import get_settings

        s = get_settings()
        cred = credentials.Certificate(s.FIREBASE_CREDENTIALS)
        firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        return True
    except Exception as exc:
        logger.warning("firebase_init_failed", error=str(exc))
        return False


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> bool:
    if not _init_firebase():
        return False
    try:
        from firebase_admin import messaging

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data=data or {},
            token=fcm_token,
        )
        await asyncio.to_thread(messaging.send, message)
        logger.info("fcm_notification_sent", title=title)
        return True
    except Exception as exc:
        logger.error("fcm_send_error", error=str(exc))
        return False


async def notify_new_lead(
    fcm_token: str, lead_nome: str, destino: Optional[str]
) -> bool:
    body = f"Lead: {lead_nome or 'Novo contato'}"
    if destino:
        body += f" — Destino: {destino}"
    return await send_push_notification(
        fcm_token=fcm_token,
        title="Novo lead qualificado",
        body=body,
        data={"type": "new_lead"},
    )


async def notify_travel_status_change(
    fcm_token: str,
    new_status: LeadStatus,
    lead_nome: Optional[str] = None,
) -> bool:
    """Notifies the client when their travel/lead status changes."""
    entry = _STATUS_MESSAGES.get(new_status)
    if not entry:
        return False
    title, body = entry
    if lead_nome:
        title = f"Olá, {lead_nome}! {title}"
    return await send_push_notification(
        fcm_token=fcm_token,
        title=title,
        body=body,
        data={"type": "travel_status_change", "new_status": new_status.value},
    )


async def send_notification(
    user_id: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
) -> bool:
    """
    Wrapper for send_push_notification that takes a user_id.
    Note: Token lookup for user_id is currently skipped to avoid direct DB dependency in this service.
    This is mainly to fix the ImportError in offer_service.py.
    """
    logger.warning("fcm_send_by_user_id_not_implemented", user_id=user_id)
    return False
