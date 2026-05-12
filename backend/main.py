"""
Application Entry Point — Cadife Smart Travel API
==================================================
FastAPI application factory following Clean Architecture.
Registers middlewares, routers, and startup/shutdown lifecycle hooks.
"""

from contextlib import asynccontextmanager

import structlog
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

# Core / Infra
from app.infrastructure.config.settings import get_settings
from app.infrastructure.config.logging_config import configure_logging
from app.infrastructure.persistence.database import create_tables

# Import all models to register them in SQLAlchemy metadata before create_tables
import app.infrastructure.persistence.models  # noqa: F401
from app.infrastructure.adapters.firebase import init_firebase
from app.infrastructure.security.rate_limiter import limiter
from app.services.ingestion_pipeline import get_ingestion_pipeline

# Scheduled Jobs
from app.jobs.lead_expiration_job import expire_stale_leads
from app.jobs.proposta_expiration_job import expire_stale_propostas_job
from app.jobs.notification_worker import NotificationWorker, WORKER_INTERVAL_SECONDS
from app.jobs.checkpoint_cron_job import run_checkpoint_cron

# Routers
from app.routes import admin, agenda, auth, documents, ia, leads, offers, propostas, webhook, suitcase, diary

# Middlewares
from app.presentation.middlewares.request_id import RequestIdMiddleware
from app.presentation.middlewares.timeout import TimeoutMiddleware
from app.presentation.middlewares.audit_trail import AuditTrailMiddleware
from app.presentation.middlewares.security_headers import SecurityHeadersMiddleware
from app.presentation.schemas.common_errors import HTTPErrorResponse, HTTPValidationErrorResponse

# -------------------------------------------------------------------
# Config
# -------------------------------------------------------------------

settings = get_settings()
configure_logging()
logger = structlog.get_logger()

# Scheduler instance — configured at module level, started/stopped in lifespan
_scheduler = AsyncIOScheduler(timezone="UTC")


# -------------------------------------------------------------------
# Lifespan
# -------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(
        "startup_begin",
        env=settings.APP_ENV,
        debug=settings.DEBUG,
    )

    # Database
    await create_tables()
    logger.info("database_ready")

    # Firebase
    init_firebase()
    logger.info("firebase_ready")

    # RAG Knowledge Base — incremental re-index on startup (skips unchanged files)
    try:
        pipeline = get_ingestion_pipeline()
        indexing_result = await pipeline.ingest_all(force=False)
        logger.info("rag_knowledge_base_indexed", **indexing_result)
    except Exception as exc:
        logger.warning("rag_indexing_failed_on_startup", error=str(exc))

    # -------------------------------------------------------------------
    # Scheduled Jobs Configuration
    # -------------------------------------------------------------------
    
    # 1. Lead Expiration: Runs daily at 02:00 UTC
    _scheduler.add_job(
        expire_stale_leads,
        trigger="cron",
        hour=2,
        minute=0,
        id="lead_expiration",
        replace_existing=True,
    )

    # 2. Proposta Expiration: Runs every 5 minutes (SLA window check)
    _scheduler.add_job(
        expire_stale_propostas_job,
        trigger="interval",
        minutes=5,
        id="proposta_expiration",
        replace_existing=True,
    )

    # 3. Notification Worker: Drains push queue every 15s
    _notification_worker = NotificationWorker()
    _scheduler.add_job(
        _notification_worker.run,
        trigger="interval",
        seconds=WORKER_INTERVAL_SECONDS,
        id="notification_worker",
        replace_existing=True,
    )

    # 4. Travel Checkpoint Cron: Runs daily at 03:00 UTC
    _scheduler.add_job(
        run_checkpoint_cron,
        trigger="cron",
        hour=3,
        minute=0,
        id="checkpoint_cron",
        replace_existing=True,
    )

    _scheduler.start()
    logger.info(
        "scheduler_started",
        jobs=["lead_expiration", "proposta_expiration", "notification_worker", "checkpoint_cron"]
    )

    logger.info("startup_complete", version="1.0.0")

    yield

    _scheduler.shutdown(wait=False)
    logger.info("shutdown_complete")


# -------------------------------------------------------------------
# FastAPI App
# -------------------------------------------------------------------

app = FastAPI(
    title="Cadife Smart Travel API",
    description=(
        "Backend inteligente para turismo via WhatsApp + Flutter. "
        "Orquestra webhooks da Meta, processamento de IA (RAG + LangChain), "
        "gestão de leads, propostas e agendamentos. "
        "Documentação completa disponível em /docs (Swagger UI) e /redoc (ReDoc)."
    ),
    version="1.0.0",
    contact={
        "name": "Cadife Tour - Time de Desenvolvimento",
        "url": "https://cadifetour.com.br",
        "email": "dev@cadifetour.com.br",
    },
    license_info={
        "name": "Confidencial — Uso Interno do Time de Desenvolvimento",
    },
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação", "model": HTTPValidationErrorResponse},
    },
)

# -------------------------------------------------------------------
# Rate Limiter
# -------------------------------------------------------------------

app.state.limiter = limiter
app.add_exception_handler(
    RateLimitExceeded,
    _rate_limit_exceeded_handler,
)

# -------------------------------------------------------------------
# Middlewares
# -------------------------------------------------------------------
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(RequestIdMiddleware)
app.add_middleware(TimeoutMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(AuditTrailMiddleware)

# -------------------------------------------------------------------
# Routers
# -------------------------------------------------------------------

app.include_router(webhook.router)
app.include_router(leads.router)
app.include_router(ia.router)
app.include_router(agenda.router)
app.include_router(propostas.router)
app.include_router(documents.router)
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(suitcase.router)
app.include_router(offers.router)
app.include_router(diary.router)

# -------------------------------------------------------------------
# Health Check
# -------------------------------------------------------------------

@app.get(
    "/health",
    tags=["Health"],
    summary="Health Check",
    description="Endpoint de verificação de saúde da aplicação. Retorna status, versão e ambiente.",
)
async def health():
    return {
        "status": "ok",
        "service": "cadife-smart-travel",
        "version": app.version,
        "env": settings.APP_ENV,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info",
    )
