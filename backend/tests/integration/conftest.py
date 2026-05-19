"""
Conftest for integration tests
==============================
Provides:
  - Module stubs for heavy optional dependencies (langchain, firebase_admin)
  - A fully-isolated SQLite in-memory test engine that creates tables from
    app.core.database.Base (app/models/*) only — InfraBase is excluded because
    some infrastructure models use PostgreSQL-specific types (JSONB) that are
    incompatible with SQLite. All tests in this suite use CoreBase models only.
  - Overrides for setup_database and db_session fixtures so integration tests
    do not share state with the unit-test suite.
"""

import asyncio
import sys
import types
from typing import AsyncGenerator, Generator
from unittest.mock import MagicMock

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# ── Heavy-dependency stubs ───────────────────────────────────────────────────


class _AutoStubModule(types.ModuleType):
    """Stub module that returns a MagicMock for any attribute access."""

    def __getattr__(self, name: str):
        value = MagicMock()
        setattr(self, name, value)
        return value


def _stub(name: str) -> None:
    if name not in sys.modules:
        sys.modules[name] = _AutoStubModule(name)


for _mod in [
    "langchain",
    "langchain.memory",
    "langchain.output_parsers",
    "langchain.prompts",
    "langchain.schema",
    "langchain.text_splitter",
    "langchain.chains",
    "langchain.chat_models",
    "langchain_google_genai",
    "langchain_community",
    "langchain_community.vectorstores",
    "langchain_chroma",
    "langchain_text_splitters",
    "langchain_core",
    "langchain_core.documents",
    "langchain_core.embeddings",
    "langchain_core.messages",
    "langchain_core.prompts",
    "langchain_core.runnables",
    "langchain_chroma.vectorstores",
    "langgraph",
    "langgraph.graph",
    "firebase_admin",
    "firebase_admin.messaging",
    "firebase_admin.credentials",
]:
    _stub(_mod)


# ── Model registrations (must happen BEFORE create_all) ─────────────────────
# Importing these modules registers their ORM classes with their respective
# Base.metadata so that create_all creates the correct tables.

import app.models.lead               # noqa: F401 — CoreBase
import app.models.briefing           # noqa: F401
import app.models.interacao          # noqa: F401
import app.models.lead_score_history # noqa: F401
import app.models.user               # noqa: F401
import app.models.agendamento        # noqa: F401
import app.models.travel_checkpoint  # noqa: F401
import app.models.notification_queue # noqa: F401
import app.models.proposta           # noqa: F401

# NOTE: Do NOT import app.infrastructure.persistence.models.* here.
# Importing any submodule triggers the package __init__.py, which registers
# ConversationSummaryModel (PostgreSQL JSONB) into InfraBase — incompatible
# with SQLite. The tests in this suite only require CoreBase tables.

from app.core.database import Base as CoreBase

# ── Isolated test engine ─────────────────────────────────────────────────────
# Named shared-cache URI ensures every connection within the same process
# sees the same in-memory database, which is required when a service function
# opens its own session (e.g. spawn_with_own_session) during a test.

_INT_DB_URL = (
    "sqlite+aiosqlite:///file:int_testdb?mode=memory&cache=shared&uri=true"
)

integration_engine = create_async_engine(_INT_DB_URL, echo=False, future=True)

IntegrationSessionLocal = async_sessionmaker(
    integration_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# ── Fixtures ─────────────────────────────────────────────────────────────────


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function")
def setup_database(event_loop) -> None:
    """Create all CoreBase tables and drop them after the test."""

    async def _setup() -> None:
        async with integration_engine.begin() as conn:
            await conn.run_sync(CoreBase.metadata.create_all)

    event_loop.run_until_complete(_setup())
    yield

    async def _teardown() -> None:
        async with integration_engine.begin() as conn:
            await conn.run_sync(CoreBase.metadata.drop_all)

    event_loop.run_until_complete(_teardown())


@pytest.fixture()
async def db_session(setup_database) -> AsyncGenerator[AsyncSession, None]:
    """Yield a session backed by the integration engine; roll back after test."""
    async with IntegrationSessionLocal() as session:
        yield session
        await session.rollback()
