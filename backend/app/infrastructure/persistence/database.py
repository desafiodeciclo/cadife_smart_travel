"""
Database Module — Infrastructure/Persistence Layer
===================================================
Async SQLAlchemy engine and session factory for PostgreSQL (spec.md §3.3).
"""

from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.infrastructure.config.settings import get_settings

settings = get_settings()

engine_url = make_url(settings.DATABASE_URL)
engine_kwargs = {
    "echo": settings.DEBUG,
    "pool_pre_ping": True,
}

# Async SQLite does not support pool_size / max_overflow in SQLAlchemy 2.x.
if engine_url.get_backend_name() != "sqlite":
    # 5 + 10 = 15 conexões por worker. Com 4 workers uvicorn = 60 conexões,
    # bem abaixo do limite padrão do PostgreSQL (100). Usar PgBouncer em produção
    # com múltiplas instâncias para aumentar a capacidade sem alterar esses números.
    engine_kwargs.update(
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=1800,
    )

engine = create_async_engine(settings.DATABASE_URL, **engine_kwargs)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """SQLAlchemy declarative base — all ORM models inherit from this."""


async def create_tables() -> None:
    """Create all tables on startup (development/testing only).
    In production, use Alembic migrations instead.
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
