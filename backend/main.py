from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.database import create_tables
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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(webhook.router)
app.include_router(leads.router)
app.include_router(ia.router)
app.include_router(agenda.router)
app.include_router(propostas.router)
app.include_router(auth.router)


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "service": "cadife-smart-travel"}
