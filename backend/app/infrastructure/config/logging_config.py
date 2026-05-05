import logging
import sys
import structlog
from app.infrastructure.config.settings import get_settings

def mask_pii(logger, method_name, event_dict):
    """Mask common PII fields in the event dictionary."""
    pii_fields = ["email", "phone", "telefone", "password", "senha", "cpf", "rg"]
    for field in pii_fields:
        if field in event_dict:
            event_dict[field] = "[REDACTED]"
    return event_dict

def configure_logging():
    settings = get_settings()
    
    # Processadores compartilhados para structlog e logging padrão
    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        mask_pii,
    ]

    if settings.APP_ENV == "production":
        # Em produção, usamos JSON para fácil ingestão em sistemas de log (GCP, ELK, etc)
        processors = shared_processors + [
            structlog.processors.dict_tracebacks,
            structlog.processors.JSONRenderer(),
        ]
    else:
        # Em desenvolvimento, usamos logs coloridos e legíveis
        processors = shared_processors + [
            structlog.dev.ConsoleRenderer(),
        ]

    structlog.configure(
        processors=processors,
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Redirecionar logging padrão para structlog
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=logging.INFO if settings.APP_ENV == "production" else logging.DEBUG,
    )
