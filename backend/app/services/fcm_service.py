from typing import Optional
import structlog

logger = structlog.get_logger()

_firebase_initialized = False


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
        messaging.send(message)
        logger.info("fcm_notification_sent", title=title)
        return True
    except Exception as exc:
        logger.error("fcm_send_error", error=str(exc))
        return False


async def notify_new_lead(fcm_token: str, lead_nome: str, destino: Optional[str]) -> bool:
    body = f"Lead: {lead_nome or 'Novo contato'}"
    if destino:
        body += f" — Destino: {destino}"
    return await send_push_notification(
        fcm_token=fcm_token,
        title="Novo lead qualificado",
        body=body,
        data={"type": "new_lead"},
    )
