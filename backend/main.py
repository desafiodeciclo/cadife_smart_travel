"""
Application Entry Point — Cadife Smart Travel API
==================================================
FastAPI application factory following Clean Architecture.
Registers middlewares, routers, and startup/shutdown lifecycle hooks.
"""

import re
from contextlib import asynccontextmanager

import sys
from unittest.mock import MagicMock
sys.modules["aioboto3"] = MagicMock()

import structlog
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI, Depends, status, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from sqlalchemy.exc import MissingGreenlet
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
from app.routes import all_routers

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

OPENAPI_TAGS = [
    {"name": "Health", "description": "Healthcheck e status do serviço."},
    {"name": "Webhook", "description": "Endpoints de webhook da Meta WhatsApp Cloud API."},
    {"name": "Auth", "description": "Login, refresh token e gerenciamento de sessão JWT."},
    {"name": "Leads", "description": "CRUD e pipeline de leads (NOVO → FECHADO/PERDIDO)."},
    {"name": "IA", "description": "Chamadas da camada de IA (briefing, RAG, classificação)."},
    {"name": "Agenda", "description": "Agendamento de curadorias e integração Google Calendar."},
    {"name": "Propostas", "description": "Gestão de propostas comerciais e expiração SLA."},
    {"name": "Documentos", "description": "Upload e gestão de documentos do cliente."},
    {"name": "Mala", "description": "Mala de viagem do cliente (checklist offline-first)."},
    {"name": "Offers", "description": "Ofertas e promoções enviadas ao cliente."},
    {"name": "Diary", "description": "Diário de viagem do cliente (fotos, anotações)."},
    {"name": "Travels", "description": "Viagens ativas e itinerários consolidados."},
    {"name": "Itinerario", "description": "Itinerário detalhado dia-a-dia."},
    {"name": "Admin", "description": "Endpoints administrativos restritos."},
    {"name": "AgencySettings", "description": "Configurações da agência (Cadife Tour)."},
    {"name": "ConsultorProfile", "description": "Perfil do consultor humano."},
]

app = FastAPI(
    title="Cadife Smart Travel API",
    version="2.0.0",
    description=(
        "API do **Cadife Smart Travel** — plataforma de atendimento turístico inteligente "
        "para a Cadife Tour.\n\n"
        "Inclui:\n"
        "- Webhook Meta WhatsApp (AYA bot de pré-atendimento)\n"
        "- Camada de IA com LangChain + RAG (Gemini via OpenRouter)\n"
        "- CRM da agência (leads, propostas, agenda, documentos)\n"
        "- Portal do cliente (viagens, mala, diário, ofertas)\n\n"
        "**Autenticação:** JWT Bearer em todos os endpoints, exceto `/health`, "
        "`/webhook/whatsapp` e `/auth/login`."
    ),
    contact={
        "name": "Cadife Tour — Time de Engenharia",
        "email": "engenharia@cadifetour.com.br",
    },
    license_info={"name": "Proprietary"},
    openapi_tags=OPENAPI_TAGS,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    swagger_ui_parameters={
        "persistAuthorization": True,
        "displayRequestDuration": True,
        "filter": True,
        "tryItOutEnabled": True,
        "docExpansion": "none",
    },
    lifespan=lifespan,
)

# Exception Handlers & Middlewares
app.state.limiter = limiter
app.add_exception_handler(
    RateLimitExceeded,
    _rate_limit_exceeded_handler,
)


@app.exception_handler(MissingGreenlet)
async def missing_greenlet_handler(request: Request, exc: MissingGreenlet) -> JSONResponse:
    """
    Catch SQLAlchemy MissingGreenlet at the HTTP boundary so the error is
    always logged with full context and returns a clean 500 instead of an
    unhandled exception trace.  This exception means an ORM lazy-load was
    attempted outside of an async greenlet — a session/lifecycle bug.
    """
    logger.error(
        "missing_greenlet_detected",
        path=request.url.path,
        method=request.method,
        error=str(exc),
        exc_info=True,
    )
    return JSONResponse(
        status_code=500,
        content={"detail": "Erro interno de persistência. Os dados podem não ter sido salvos."},
    )

# -------------------------------------------------------------------
# Middlewares
# -------------------------------------------------------------------

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


# Normaliza barras duplas vindas de proxies upstream (ex: AlphaEdtech //health → /health)
@app.middleware("http")
async def normalize_double_slash(request, call_next):
    if "//" in request.url.path:
        scope = request.scope
        scope["path"] = re.sub(r"/+", "/", scope["path"])
        scope["raw_path"] = scope["path"].encode()
    return await call_next(request)

# -------------------------------------------------------------------
# Routers
# -------------------------------------------------------------------

for _router in all_routers:
    app.include_router(_router)

@app.get("/health", tags=["Health"])
async def health():
    return {
        "status": "ok",
        "service": "cadife-smart-travel",
        "version": app.version,
        "env": settings.APP_ENV,
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG)