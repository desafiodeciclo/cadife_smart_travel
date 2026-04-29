"""
Alembic Environment — Async SQLAlchemy + Auto-detect
=====================================================
Configured for PostgreSQL + asyncpg (non-blocking migrations via
run_sync). Reads DATABASE_URL from app settings (pydantic-settings)
so there is a single source of truth — no duplicate connection strings.

Includes all ORM models via infrastructure.persistence.models import
to ensure Alembic can auto-generate accurate migration scripts.
"""
import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# ── Load application settings (reads .env) ────────────────────────────────
from app.infrastructure.config.settings import get_settings

# ── Import ALL ORM models so metadata is populated before autogenerate ─────
import app.infrastructure.persistence.models  # noqa: F401 — side-effect import

from app.infrastructure.persistence.database import Base

settings = get_settings()

# Alembic Config object, provides access to alembic.ini values
config = context.config

# Override sqlalchemy.url from app settings — single source of truth
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

# Setup Python logging from alembic.ini [loggers] section
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Metadata for 'autogenerate' — all tables registered via Base
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """
    Run migrations in 'offline' mode.
    Generates SQL script without DB connection — useful for review / CI.
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,           # detect column type changes
        compare_server_default=True,  # detect server_default changes
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in 'online' mode using async engine."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


def run_migrations_online() -> None:
    """Entry point for online migration — runs async loop."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
