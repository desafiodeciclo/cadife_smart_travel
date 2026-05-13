"""
Application Entry Point — Cadife Smart Travel API
==================================================
FastAPI application factory following Clean Architecture.
Registers middlewares, routers, and startup/shutdown lifecycle hooks.
"""

from contextlib import asynccontextmanager

import structlog
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
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
from app.jobs.conversation_summary_retry_job import run_conversation_summary_retry
from app.jobs.aya_alert_job import alert_aya_disabled_leads

# Routers
from app.routes import admin, agency_settings, agenda, auth, consultor_profile, documents, documentos, ia, leads, mala, offers, propostas, webhook, suitcase, diary, travels

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

_scheduler = AsyncIOScheduler(timezone="UTC")

# -------------------------------------------------------------------
# Lifespan
# -------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("startup_begin", env=settings.APP_ENV, debug=settings.DEBUG)

    # Infra Start
    await create_tables()
    init_firebase()

    # RAG Knowledge Base
    try:
        pipeline = get_ingestion_pipeline()
        indexing_result = await pipeline.ingest_all(force=False)
        logger.info("rag_knowledge_base_indexed", **indexing_result)
    except Exception as exc:
        logger.warning("rag_indexing_failed_on_startup", error=str(exc))

    # -------------------------------------------------------------------
    # Scheduled Jobs Configuration (Unified)
    # -------------------------------------------------------------------
    
    # 1. Lead Expiration (Daily)
    _scheduler.add_job(expire_stale_leads, trigger="cron", hour=2, minute=0, id="lead_expiration")

    # 2. Proposta Expiration (Interval)
    _scheduler.add_job(expire_stale_propostas_job, trigger="interval", minutes=5, id="proposta_expiration")

    # 3. Notification Worker (Queue Drain)
    _notification_worker = NotificationWorker()
    _scheduler.add_job(_notification_worker.run, trigger="interval", seconds=WORKER_INTERVAL_SECONDS, id="notification_worker")

    # 4. Travel Checkpoint Cron (Daily - feat branch)
    _scheduler.add_job(run_checkpoint_cron, trigger="cron", hour=3, minute=0, id="checkpoint_cron")

    # 5. Conversation Summary Retry (15m - feat branch)
    _scheduler.add_job(run_conversation_summary_retry, trigger="interval", minutes=15, id="conversation_summary_retry")

    # 6. AYA Alert (Hourly - developer branch)
    _scheduler.add_job(alert_aya_disabled_leads, trigger="interval", hours=1, id="aya_disabled_alert")

    _scheduler.start()
    
    logger.info(
        "scheduler_started",
        jobs=[j.id for j in _scheduler.get_jobs()]
    )

    yield
    _scheduler.shutdown(wait=False)

# -------------------------------------------------------------------
# FastAPI App Construction
# -------------------------------------------------------------------

app = FastAPI(
    title="Cadife Smart Travel API",
    version="1.0.0",
    lifespan=lifespan,
    # ... rest of metadata ...
)

# Exception Handlers & Middlewares
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("unhandled_exception", error=str(exc), path=request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Erro interno no servidor.", "error_code": "INTERNAL_SERVER_ERROR"}
    )

app.add_middleware(SlowAPIMiddleware)
app.add_middleware(RequestIdMiddleware)
app.add_middleware(TimeoutMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()],
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(AuditTrailMiddleware)

# Router Registration
app.include_router(webhook.router)
app.include_router(leads.router)
app.include_router(ia.router)
app.include_router(agenda.router)
app.include_router(propostas.router)
app.include_router(documentos.router)  # canonical PT
app.include_router(documents.router)  # deprecated EN alias (parity gap §3.11)
app.include_router(auth.router)
app.include_router(admin.router)
app.include_router(mala.router)  # canonical PT
app.include_router(suitcase.router)  # deprecated EN alias (parity gap §3.11)
app.include_router(offers.router)
app.include_router(diary.router)
app.include_router(travels.router)
app.include_router(agency_settings.router)  # PRD: settings + templates
app.include_router(consultor_profile.router)  # PRD: bio, foto, métricas, metas

@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": app.version, "env": settings.APP_ENV}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)