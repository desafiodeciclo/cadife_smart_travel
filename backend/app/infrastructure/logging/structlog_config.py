"""
Structlog Configuration — Centralized Logging Setup
===================================================
Configures structlog for structured JSON logs compatible with ELK/Loki/Grafana.
"""
import structlog
import logging
from structlog.stdlib import add_log_level
from structlog.processors import TimeStamper, JSONRenderer, StackInfoRenderer, format_exc_info
from structlog.contextvars import merge_contextvars
from app.infrastructure.config.settings import get_settings


def init_logging():
    """Initialize structlog with environment-aware settings."""
    settings = get_settings()
    
    # Set log level based on environment (DEBUG=True for dev/test)
    log_level = "DEBUG" if settings.DEBUG else "INFO"
    
    structlog.configure(
        processors=[
            merge_contextvars,          # Merge context vars (trace_id, user_id, etc.)
            add_log_level,              # Add log level (INFO, ERROR, etc.)
            TimeStamper(fmt="iso"),     # Add ISO 8601 timestamp
            StackInfoRenderer(),        # Render stack traces if present
            format_exc_info,            # Format exception info
            JSONRenderer(),             # Output logs as JSON
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    # Set root log level
    logging.basicConfig(level=getattr(logging, log_level))
    
    # Test log to confirm configuration
    logger = structlog.get_logger("startup")
    logger.info(
        "Structlog initialized",
        app_env=settings.APP_ENV,
        log_level=log_level,
        service="cadife-smart-travel-backend"
    )
