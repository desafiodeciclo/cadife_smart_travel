"""
Database Module — Infrastructure/Persistence Layer
===================================================
Async SQLAlchemy engine and session factory for PostgreSQL (spec.md §3.3).
"""

from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import NullPool

from app.infrastructure.config.settings import get_settings

settings = get_settings()

engine_url = make_url(settings.DATABASE_URL)
engine_kwargs = {
    "echo": settings.DEBUG,
    "pool_pre_ping": True,
    "poolclass": NullPool,
}

# NullPool is used for stability on Windows; no pool size parameters needed.

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
