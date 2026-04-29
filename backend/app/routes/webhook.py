import structlog
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.application.use_cases import process_whatsapp_message
from app.core.dependencies import get_db
from app.services import whatsapp_service

logger = structlog.get_logger()
router = APIRouter(prefix="/webhook", tags=["Webhook"])


# ── Dependência: valida HMAC X-Hub-Signature-256 ─────────────────────────────

async def require_meta_signature(
    request: Request,
    settings: Settings = Depends(get_settings),
) -> bytes:
    body = await request.body()
    if not settings.META_APP_SECRET:
        logger.warning("webhook_signature_skip", reason="META_APP_SECRET not set")
        return body
    signature = request.headers.get("X-Hub-Signature-256", "")
    if not whatsapp_service.verify_signature(body, signature):
        logger.warning("webhook_invalid_signature", path=str(request.url))
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid signature")
    return body


# ── GET: verificação do Challenge Token (Meta App Dashboard) ─────────────────

@router.get("/whatsapp")
async def verify_webhook(
    request: Request,
    settings: Settings = Depends(get_settings),
):
    params = request.query_params
    mode = params.get("hub.mode")
    token = params.get("hub.verify_token")
    challenge = params.get("hub.challenge")

    if mode == "subscribe" and token == settings.VERIFY_TOKEN:
        logger.info("webhook_verified")
        return int(challenge) if challenge else 0

    logger.warning("webhook_verify_failed", mode=mode)
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")


# ── POST: recebe mensagens — 200 garantido, validação HMAC via Depends ────────

@router.post("/whatsapp")
async def receive_whatsapp(
    request: Request,
    background_tasks: BackgroundTasks,
    _body: bytes = Depends(require_meta_signature),
    db: AsyncSession = Depends(get_db),
):
    try:
        payload = await request.json()
        background_tasks.add_task(process_whatsapp_message.execute, payload, db)
    except Exception as exc:
        logger.error("webhook_parse_error", error=str(exc))

    return {"status": "received"}
