import structlog
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request, status

from app.core.config import Settings, get_settings
from app.application.use_cases import process_whatsapp_message
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import whatsapp_service
from app.services.kafka_producer import produce as kafka_produce

logger = structlog.get_logger()
router = APIRouter(prefix="/webhook", tags=["Webhook"])


# ── Dependência: valida HMAC X-Hub-Signature-256 ─────────────────────────────


async def require_meta_signature(
    request: Request,
    settings: Settings = Depends(get_settings),
) -> bytes:
    body = await request.body()
    if not settings.META_APP_SECRET:
        logger.error("webhook_security_critical_failure", reason="META_APP_SECRET not set")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Configuração de segurança incompleta"
        )
    signature = request.headers.get("X-Hub-Signature-256", "")
    if not whatsapp_service.verify_signature(body, signature):
        logger.warning("webhook_invalid_signature", path=str(request.url))
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Invalid signature"
        )
    return body


# ── GET: verificação do Challenge Token (Meta App Dashboard) ─────────────────


@router.get(
    "/whatsapp",
    summary="Verificação do webhook WhatsApp (Meta Challenge)",
    description=(
        "Endpoint utilizado pelo painel da Meta App para verificar a URL do webhook. "
        "Deve retornar o valor do parâmetro `hub.challenge` quando o token de verificação coincidir."
    ),
    responses={
        403: {"description": "Token de verificação inválido", "model": HTTPErrorResponse},
    },
)
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


@router.post(
    "/whatsapp",
    summary="Recebimento de mensagens do WhatsApp",
    description=(
        "Recebe payloads de eventos de mensagens da Meta WhatsApp Cloud API. "
        "A assinatura HMAC (X-Hub-Signature-256) é validada antes do processamento. "
        "O processamento da IA ocorre de forma assíncrona via BackgroundTasks para garantir "
        "resposta HTTP 200 em ≤ 5 segundos, conforme exigência da Meta."
    ),
    responses={
        403: {"description": "Assinatura HMAC inválida", "model": HTTPErrorResponse},
    },
)
async def receive_whatsapp(
    request: Request,
    background_tasks: BackgroundTasks,
    _body: bytes = Depends(require_meta_signature),
    settings: Settings = Depends(get_settings),
):
    try:
        payload = await request.json()
        if settings.KAFKA_ENABLED:
            # Durabilidade via Kafka — consumer cria sua própria sessão DB
            # Usa extract_message_from_payload para centralizar a extração do phone (Fix 7.4)
            extracted = whatsapp_service.extract_message_from_payload(payload)
            phone = extracted["phone"] if extracted else "unknown"
            from datetime import datetime, timezone
            await kafka_produce(
                topic="whatsapp.messages.incoming",
                key=phone,
                value={
                    "payload": payload,
                    "received_at": datetime.now(timezone.utc).isoformat(),
                },
            )
        else:
            # execute_with_new_session cria sua própria AsyncSession — evita
            # passar a sessão do request para a BackgroundTask (Fix 7.1)
            background_tasks.add_task(
                process_whatsapp_message.execute_with_new_session, payload
            )
    except Exception as exc:
        logger.error("webhook_parse_error", error=str(exc))

    return {"status": "received"}
