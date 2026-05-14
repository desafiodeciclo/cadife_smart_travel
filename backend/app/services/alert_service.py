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
                    "fields": [{"value": message, "short": False}],
                    "footer": "Cadife Observability",
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
    async def notify_hallucination(
        phone: str, hallucinations: list[str], response_snippet: str
    ):
        masked_phone = f"+55...{phone[-4:]}" if len(phone) >= 4 else "***"
        logger.warning(
            "ALERT_HALLUCINATION",
            phone=masked_phone,
            hallucinations=hallucinations,
            response_snippet=response_snippet,
            target_email="frank@cadife.com",
        )
        await AlertService.send_slack_alert(
            f"Alucinação detectada para {masked_phone}: {hallucinations}. Resposta: {response_snippet[:50]}...",
            level="warning",
        )

    @staticmethod
    async def notify_kafka_lag(topic: str, lag: int, threshold: int = 100):
        logger.warning("ALERT_KAFKA_LAG", topic=topic, lag=lag, threshold=threshold)
        await AlertService.send_slack_alert(
            f"Kafka consumer lag alto no tópico `{topic}`: {lag} mensagens pendentes (limite: {threshold})",
            level="warning",
        )

    @staticmethod
    async def notify_webhook_error_rate(error_count: int, total: int, window_seconds: int = 60):
        rate_pct = round(error_count / total * 100, 1) if total > 0 else 0
        logger.warning(
            "ALERT_WEBHOOK_ERROR_RATE",
            error_count=error_count,
            total=total,
            rate_pct=rate_pct,
            window_seconds=window_seconds,
        )
        await AlertService.send_slack_alert(
            f"Taxa de erro no webhook alta: {rate_pct}% ({error_count}/{total}) nos últimos {window_seconds}s",
            level="warning",
        )

    @staticmethod
    async def notify_critical_error(error_name: str, details: str):
        logger.error("ALERT_CRITICAL_ERROR", error_name=error_name, details=details)
        await AlertService.send_slack_alert(
            f"ERRO CRÍTICO: {error_name}\nDetalhes: {details}"
        )
