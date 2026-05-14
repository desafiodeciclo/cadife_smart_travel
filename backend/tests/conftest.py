"""
Test Configuration — Pytest fixtures for database, auth, and client setup.
========================================================================
This file configures the test suite to use an in-memory SQLite database
(via aiosqlite) instead of PostgreSQL, allowing for fast, isolated tests.
"""

import asyncio
import os
import uuid
from datetime import datetime, timedelta, timezone
from typing import AsyncGenerator, Generator

import pytest
from fastapi.testclient import TestClient
from httpx import ASGITransport, AsyncClient
from jose import jwt
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# ── Environment Setup ────────────────────────────────────────────────────
os.environ["WHATSAPP_TOKEN"] = "test_token"
os.environ["PHONE_NUMBER_ID"] = "test_id"
os.environ["GEMINI_API_KEY"] = "test_key"
os.environ["VERIFY_TOKEN"] = "test_verify"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["APP_ENV"] = "test"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-12345678901234567890"
os.environ["JWT_ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "15"
os.environ["REFRESH_TOKEN_EXPIRE_DAYS"] = "7"
os.environ["ENCRYPTION_KEY"] = "858iXm1S2iXN5sH3W6V-q7W_U8U7z6T5S4R3Q2P1O0N="
os.environ["HASH_KEY"] = "f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7"
os.environ["REDIS_PREFIX"] = "CACHE"

# ── Import ALL models to avoid 'name not defined' errors ────────────────
# The centralized __init__.py handles the correct import order and prevents
# duplication between legacy Core models and new Infrastructure models.
import app.infrastructure.persistence.models  # noqa: F401

from main import app
from app.infrastructure.persistence.database import Base as InfraBase
from app.core.database import Base as CoreBase
from app.core.dependencies import get_db
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.security.jwt import create_access_token
from app.infrastructure.config.settings import get_settings

settings = get_settings()

# ── Test Database Engine ────────────────────────────────────────────────
test_engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
)

TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="function")
def setup_database(event_loop) -> None:
    """Create and drop all tables in the test database."""
    async def _setup() -> None:
        async with test_engine.begin() as conn:
            # Clean duplicate indexes caused by extend_existing=True across legacy/infra models
            for table in InfraBase.metadata.tables.values():
                unique_indexes = set()
                deduped_indexes = set()
                for idx in table.indexes:
                    if idx.name not in unique_indexes:
                        unique_indexes.add(idx.name)
                        deduped_indexes.add(idx)
                table.indexes = deduped_indexes
            
            # Create all tables once
            await conn.run_sync(InfraBase.metadata.create_all)

    event_loop.run_until_complete(_setup())
    yield
    async def _teardown() -> None:
        async with test_engine.begin() as conn:
            await conn.run_sync(InfraBase.metadata.drop_all)
    event_loop.run_until_complete(_teardown())

@pytest.fixture()
async def db_session(setup_database) -> AsyncGenerator[AsyncSession, None]:
    """Create a new database session for a test."""
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()

# ── FastAPI Dependency Overrides ───────────────────────────────────────
@pytest.fixture()
def override_get_db(db_session: AsyncSession):
    async def _get_db():
        yield db_session
    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.pop(get_db, None)

@pytest.fixture()
def override_get_current_user():
    from app.infrastructure.persistence.models.user_model import UserModel
    mock_user = UserModel(
        id=uuid.UUID("deadeade-dead-dead-dead-deadeadeadea"),
        nome="Test User",
        email="test@example.com",
        hashed_password="hashed_password_here",
        telefone="+5511999999999",
        perfil="admin",
        is_active=True,
        criado_em=datetime.now(timezone.utc),
    )
    async def _get_current_user():
        return mock_user
    app.dependency_overrides[get_current_user] = _get_current_user
    yield mock_user
    app.dependency_overrides.pop(get_current_user, None)

# ── Test Clients ────────────────────────────────────────────────────────
@pytest.fixture()
def client(override_get_db, override_get_current_user) -> TestClient:
    return TestClient(app)

@pytest.fixture()
async def async_client(
    override_get_db, override_get_current_user
) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

# ── JWT Fixtures ────────────────────────────────────────────────────────
@pytest.fixture()
def valid_jwt_token() -> str:
    user_id = "deadeade-dead-dead-dead-deadeadeadea"
    return create_access_token(user_id)

@pytest.fixture()
def expired_jwt_token() -> str:
    payload = {
        "sub": "deadeade-dead-dead-dead-deadeadeadea",
        "type": "access",
        "exp": datetime.now(timezone.utc) - timedelta(hours=1),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

@pytest.fixture()
def invalid_jwt_token() -> str:
    payload = {"sub": "deadeade-dead-dead-dead-deadeadeadea", "type": "access"}
    return jwt.encode(payload, "wrong-secret-key", algorithm=settings.JWT_ALGORITHM)
