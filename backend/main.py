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
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.core.config import get_settings
from app.core.database import create_tables
from app.infrastructure.security.rate_limiter import limiter
from app.presentation.middlewares.audit_trail import AuditTrailMiddleware
from app.presentation.middlewares.security_headers import SecurityHeadersMiddleware
from app.infrastructure.adapters.firebase import init_firebase
from app.infrastructure.config.settings import get_settings
from app.infrastructure.persistence.database import create_tables

# ── Presentation Layer Routers ────────────────────────────────────────────
from app.routes import agenda, auth, ia, leads, propostas, webhook

# ── Presentation Layer Middlewares ────────────────────────────────────────
from app.presentation.middlewares.request_id import RequestIdMiddleware
from app.presentation.middlewares.timeout import TimeoutMiddleware

logger = structlog.get_logger()
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown hooks."""
    logger.info(
        "startup_begin",
        env=settings.APP_ENV,
        debug=settings.DEBUG,
    )

    # CP1: Database tables (dev only — use Alembic in production)
    await create_tables()
    logger.info("database_tables_ready")

    # CP4: Firebase Admin SDK initialization
    init_firebase()

    logger.info("startup_complete", version=app.version)
    yield
    logger.info("shutdown_complete")


# ─────────────────────────────────────────────────────────────────────────
# FastAPI Application Factory
# ─────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Cadife Smart Travel API",
    description=(
        "Backend inteligente de atendimento turístico via WhatsApp + App Flutter. "
        "Spec: spec.md v1.0 | MVP 25 dias."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.APP_ENV != "production" else None,
    redoc_url="/redoc" if settings.APP_ENV != "production" else None,
)

# ── Rate Limiter ──────────────────────────────────────────────────────────────
# Registra o limiter no estado da app e o handler para o erro 429
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── Middlewares (ordem importa: o último adicionado executa primeiro) ─────────
# 1. CORS (mais externo — retorna antes de qualquer outro processamento)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restringir em produção para domínios conhecidos
# ── Middleware Registration (order matters — outermost executes first) ────
# 1. RequestId must be first to assign ID before all other processing
# 2. Timeout wraps inner handlers to enforce SLAs
# 3. CORS handles preflight before any business logic

app.add_middleware(RequestIdMiddleware)
app.add_middleware(TimeoutMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restrict to known origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# 2. Security Headers — injeta headers em toda resposta
app.add_middleware(SecurityHeadersMiddleware)
# 3. Audit Trail — loga request lifecycle em JSON estruturado
app.add_middleware(AuditTrailMiddleware)

# ── Router Registration (spec.md §5) ─────────────────────────────────────
app.include_router(webhook.router)   # §5.1 — Webhook WhatsApp
app.include_router(leads.router)     # §5.3 — Leads (CRM)
app.include_router(ia.router)        # §5.2 — IA e Processamento
app.include_router(agenda.router)    # §5.4 — Agenda e Agendamentos
app.include_router(propostas.router) # §5.5 — Propostas
app.include_router(auth.router)      # §5.6 — Autenticação e Usuários


# ── Health Check ──────────────────────────────────────────────────────────
@app.get("/health", tags=["Health"], summary="Service health check")
async def health():
    """
    Returns service status.
    Used by load balancers and Docker health checks.
    """
    return {
        "status": "ok",
        "service": "cadife-smart-travel",
        "version": app.version,
        "env": settings.APP_ENV,
    }
