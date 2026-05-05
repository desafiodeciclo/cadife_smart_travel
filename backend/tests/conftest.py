"""
Test Configuration — Pytest fixtures for database, auth, and client setup.
========================================================================
This file configures the test suite to use an in-memory SQLite database
(via aiosqlite) instead of PostgreSQL, allowing for fast, isolated tests.

Key design decisions:
  - Overrides FastAPI's `get_db` dependency to use the test DB session.
  - Overrides `get_current_user` to simulate authenticated requests.
  - Creates all tables via `Base.metadata.create_all` (bypassing Alembic).
  - Automatically cleans up the DB session and tables after each test.
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
# Must be set BEFORE importing app modules to avoid real PostgreSQL/WhatsApp
os.environ["WHATSAPP_TOKEN"] = "test_token"
os.environ["PHONE_NUMBER_ID"] = "test_id"
os.environ["OPENAI_API_KEY"] = "test_key"
os.environ["VERIFY_TOKEN"] = "test_verify"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["APP_ENV"] = "test"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-12345678901234567890"
os.environ["JWT_ALGORITHM"] = "HS256"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "15"
os.environ["REFRESH_TOKEN_EXPIRE_DAYS"] = "7"

# Now import the app and models AFTER setting env vars
from main import app
from app.infrastructure.persistence.database import Base, get_db, AsyncSessionLocal
from app.infrastructure.security.dependencies import get_current_user
from app.infrastructure.security.jwt import create_access_token
from app.infrastructure.config.settings import get_settings

settings = get_settings()

# ── Test Database Engine ────────────────────────────────────────────────
# We create a new engine and sessionmaker specifically for testing.
test_engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    future=True,
)

# Session factory for tests
TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def setup_database() -> AsyncGenerator[None, None]:
    """
    Create all tables in the test database once per session.
    We use run_sync because create_all is a sync operation.
    """
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture()
async def db_session(setup_database) -> AsyncGenerator[AsyncSession, None]:
    """
    Create a new database session for a test, and roll back afterwards.
    This ensures test isolation.
    """
    async with TestSessionLocal() as session:
        yield session
        # Rollback any changes made during the test
        await session.rollback()


# ── FastAPI Dependency Overrides ───────────────────────────────────────
@pytest.fixture()
def override_get_db(db_session: AsyncSession):
    """Override the `get_db` dependency to use the test session."""

    async def _get_db():
        yield db_session

    app.dependency_overrides[get_db] = _get_db
    yield
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture()
def override_get_current_user():
    """Override the `get_current_user` dependency with a mock user."""
    from app.infrastructure.persistence.models.user_model import UserModel

    # Create a mock user object
    mock_user = UserModel(
        id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
        nome="Test User",
        email="test@example.com",
        hashed_password="hashed_password_here",
        telefone="+5511999999999",
        perfil="admin",  # Default to admin for full access in tests
        is_active=True,
        criado_em=datetime.now(timezone.utc),
    )

    async def _get_current_user(*args, **kwargs):
        return mock_user

    app.dependency_overrides[get_current_user] = _get_current_user
    yield mock_user
    app.dependency_overrides.pop(get_current_user, None)


# ── Test Client ─────────────────────────────────────────────────────────
@pytest.fixture()
def client(override_get_db, override_get_current_user) -> TestClient:
    """Return a TestClient configured with the test dependencies."""
    return TestClient(app)


@pytest.fixture()
async def async_client(override_get_db, override_get_current_user) -> AsyncGenerator[AsyncClient, None]:
    """Return an AsyncClient for testing async endpoints."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


# ── JWT Fixtures ────────────────────────────────────────────────────────
@pytest.fixture()
def valid_jwt_token() -> str:
    """Generate a valid JWT access token for the mock user."""
    user_id = "00000000-0000-0000-0000-000000000001"
    return create_access_token(user_id)


@pytest.fixture()
def expired_jwt_token() -> str:
    """Generate an expired JWT access token."""
    payload = {
        "sub": "00000000-0000-0000-0000-000000000001",
        "type": "access",
        "exp": datetime.now(timezone.utc) - timedelta(hours=1),
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


@pytest.fixture()
def invalid_jwt_token() -> str:
    """Generate an invalid JWT token (wrong signature)."""
    payload = {
        "sub": "00000000-0000-0000-0000-000000000001",
        "type": "access",
    }
    # Use a different secret to simulate a bad signature
    return jwt.encode(payload, "wrong-secret-key", algorithm=settings.JWT_ALGORITHM)
