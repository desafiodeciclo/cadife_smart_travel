import structlog
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.use_cases import process_whatsapp_message
from app.core.config import get_settings
from app.core.dependencies import get_db
from app.services import whatsapp_service

logger = structlog.get_logger()
router = APIRouter(prefix="/webhook", tags=["Webhook"])
settings = get_settings()


@router.get("/whatsapp")
async def verify_webhook(request: Request):
    params = request.query_params
    mode = params.get("hub.mode")
    token = params.get("hub.verify_token")
    challenge = params.get("hub.challenge")

    if mode == "subscribe" and token == settings.VERIFY_TOKEN:
        logger.info("webhook_verified")
        return int(challenge) if challenge else 0

    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")


@router.post("/whatsapp")
async def receive_whatsapp(
    request: Request,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
):
    body = await request.body()
    signature = request.headers.get("X-Hub-Signature-256", "")

    if settings.WHATSAPP_TOKEN and not whatsapp_service.verify_signature(body, signature):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid signature")

    payload = await request.json()
    background_tasks.add_task(process_whatsapp_message.execute, payload, db)
    return {"status": "received"}
