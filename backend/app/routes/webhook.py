import structlog
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.dependencies import get_db
from app.models.interacao import TipoMensagem
from app.models.lead import LeadStatus
from app.services import ai_service, fcm_service, lead_service, whatsapp_service

logger = structlog.get_logger()
router = APIRouter(prefix="/webhook", tags=["Webhook"])
settings = get_settings()


async def _process_incoming(payload: dict, db: AsyncSession) -> None:
    msg = whatsapp_service.extract_message_from_payload(payload)
    if not msg:
        return

    phone = msg["phone"]
    text = msg.get("text")
    msg_type = msg.get("type", "text")

    logger.info("message_received", phone=phone, type=msg_type)

    lead = await lead_service.get_or_create_by_phone(db, phone, msg.get("name"))

    if lead.status == LeadStatus.novo:
        await lead_service.update_lead_status(db, lead, LeadStatus.em_atendimento)

    if msg_type != "text" or not text:
        reply = "Recebi sua mensagem! No momento aceito apenas textos. Um consultor irá te atender em breve."
    else:
        reply = await ai_service.process_message(phone, text)

        extracted = await ai_service.extract_briefing([{"role": "user", "content": text}])
        briefing = await lead_service.update_briefing_from_extraction(db, lead, extracted)

        if briefing.completude_pct >= 60 and lead.status == LeadStatus.qualificado:
            # Notificar agência via FCM
            from app.models.user import User
            from sqlalchemy import select
            result = await db.execute(
                select(User).where(User.perfil == "agencia", User.fcm_token.isnot(None))
            )
            consultores = result.scalars().all()
            for consultor in consultores:
                await fcm_service.notify_new_lead(
                    consultor.fcm_token,
                    lead.nome or phone,
                    briefing.destino,
                )

    tipo = TipoMensagem.texto if msg_type == "text" else TipoMensagem(msg_type) if msg_type in TipoMensagem.__members__ else TipoMensagem.texto
    await lead_service.save_interacao(db, lead.id, text, reply if msg_type == "text" else None, tipo)
    await whatsapp_service.send_message(phone, reply)


@router.get("/whatsapp")
async def verify_webhook(request: Request):
    params = request.query_params
    mode = params.get("hub.mode")
    token = params.get("hub.verify_token")
    challenge = params.get("hub.challenge")

    if mode == "subscribe" and token == settings.VERIFY_TOKEN:
        logger.info("webhook_verified")
        return int(challenge)

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
    background_tasks.add_task(_process_incoming, payload, db)
    return {"status": "received"}
