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
from app.routes import agenda, auth, ia, leads, propostas, webhook

logger = structlog.get_logger()
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("startup_begin")
    await create_tables()
    logger.info("startup_complete")
    yield
    logger.info("shutdown")


app = FastAPI(
    title="Cadife Smart Travel API",
    description="Backend inteligente de atendimento turístico via WhatsApp + App Flutter",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
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
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# 2. Security Headers — injeta headers em toda resposta
app.add_middleware(SecurityHeadersMiddleware)
# 3. Audit Trail — loga request lifecycle em JSON estruturado
app.add_middleware(AuditTrailMiddleware)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(webhook.router)
app.include_router(leads.router)
app.include_router(ia.router)
app.include_router(agenda.router)
app.include_router(propostas.router)
app.include_router(auth.router)


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "service": "cadife-smart-travel"}
