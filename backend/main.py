"""
Application Entry Point — Cadife Smart Travel API
==================================================
FastAPI application factory following Clean Architecture.
Registers middlewares, routers, and startup/shutdown lifecycle hooks.

Spec references:
  - §3.3  Stack: FastAPI + PostgreSQL + Firebase FCM
  - §5    Endpoints: webhook, ia, leads, agenda, propostas, auth
  - §12.2 Security: HTTPS, JWT, rate limiting (middleware hooks)
  - §12.3 Reliability: structured logs, timeout middleware
"""

from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

# Core / Infra
from app.infrastructure.config.settings import get_settings
from app.infrastructure.config.logging_config import configure_logging
from app.infrastructure.persistence.database import create_tables
from app.infrastructure.adapters.firebase import init_firebase
from app.infrastructure.security.rate_limiter import limiter
from app.services.ingestion_pipeline import get_ingestion_pipeline

# Routers
from app.routes import agenda, auth, ia, leads, propostas, webhook

# Middlewares
from app.presentation.middlewares.request_id import RequestIdMiddleware
from app.presentation.middlewares.timeout import TimeoutMiddleware
from app.presentation.middlewares.audit_trail import AuditTrailMiddleware
from app.presentation.middlewares.security_headers import SecurityHeadersMiddleware

# -------------------------------------------------------------------
# Config
# -------------------------------------------------------------------

settings = get_settings()
configure_logging()
logger = structlog.get_logger()


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

    logger.info("startup_complete", version="1.0.0")

    yield

    logger.info("shutdown_complete")


# -------------------------------------------------------------------
# FastAPI App
# -------------------------------------------------------------------

app = FastAPI(
    title="Cadife Smart Travel API",
    description="Backend inteligente para turismo via WhatsApp + Flutter.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.APP_ENV != "production" else None,
    redoc_url="/redoc" if settings.APP_ENV != "production" else None,
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
# Middlewares (order matters)
# -------------------------------------------------------------------
# ── Middleware Registration (order matters — outermost executes first) ────
# 1. RequestId must be first to assign ID before all other processing
# 2. Timeout wraps inner handlers to enforce SLAs
# 3. CORS handles preflight before any business logic

# 1. Request ID
app.add_middleware(RequestIdMiddleware)

# 2. Timeout
app.add_middleware(TimeoutMiddleware)

# 3. CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.ALLOWED_ORIGINS.split(",") if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. Security Headers
app.add_middleware(SecurityHeadersMiddleware)

# 5. Audit Logs
app.add_middleware(AuditTrailMiddleware)

# -------------------------------------------------------------------
# Routers
# -------------------------------------------------------------------

app.include_router(webhook.router)
app.include_router(leads.router)
app.include_router(ia.router)
app.include_router(agenda.router)
app.include_router(propostas.router)
app.include_router(auth.router)

# -------------------------------------------------------------------
# Health Check
# -------------------------------------------------------------------

@app.get("/health", tags=["Health"])
async def health():
    return {
        "status": "ok",
        "service": "cadife-smart-travel",
        "version": app.version,
        "env": settings.APP_ENV,
    }