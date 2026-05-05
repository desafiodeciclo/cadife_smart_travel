import httpx
import structlog
from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()

class AlertService:
    """Service to send alerts to external systems (Slack, Email, etc)."""
    
    @staticmethod
    async def send_slack_alert(message: str, level: str = "error"):
        webhook_url = getattr(settings, "SLACK_WEBHOOK_URL", None)
        if not webhook_url:
            logger.debug("slack_webhook_not_configured", message=message)
            return

        color = "#ff0000" if level == "error" else "#ffcc00"
        payload = {
            "attachments": [
                {
                    "fallback": message,
                    "color": color,
                    "text": f"*{level.upper()} ALERT*",
                    "fields": [
                        {
                            "value": message,
                            "short": False
                        }
                    ],
                    "footer": "Cadife Observability"
                }
            ]
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(webhook_url, json=payload)
                response.raise_for_status()
                logger.info("slack_alert_sent")
        except Exception as exc:
            logger.error("slack_alert_failed", error=str(exc))

    @staticmethod
    async def notify_hallucination(phone: str, hallucinations: list[str], response_snippet: str):
        # In a real scenario, this would send an email. 
        # For now, we log it with a specific tag that can be caught by log-based alerts.
        logger.warning(
            "ALERT_HALLUCINATION",
            phone=phone,
            hallucinations=hallucinations,
            response_snippet=response_snippet,
            target_email="frank@cadife.com"
        )
        # We could also send a slack alert
        await AlertService.send_slack_alert(
            f"Alucinação detectada para o telefone {phone}: {hallucinations}. Resposta: {response_snippet[:50]}...",
            level="warning"
        )

    @staticmethod
    async def notify_critical_error(error_name: str, details: str):
        logger.error("ALERT_CRITICAL_ERROR", error_name=error_name, details=details)
        await AlertService.send_slack_alert(f"ERRO CRÍTICO: {error_name}\nDetalhes: {details}")
