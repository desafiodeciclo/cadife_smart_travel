"""
Integration tests — Auth and User routes
========================================

These tests exercise the real FastAPI route handlers with an in-memory
SQLite database and the real authentication dependency.

They cover:
  - JWT validation errors
  - payload schema validation errors
  - middleware headers on authenticated routes
"""

from datetime import datetime, timedelta, timezone
from typing import AsyncGenerator

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient
from jose import jwt

from main import app
from app.infrastructure.config.settings import get_settings
from app.infrastructure.security.jwt import create_access_token, create_refresh_token, hash_password
from app.models.user import User, UserPerfil

settings = get_settings()


@pytest.fixture(autouse=True)
def clear_app_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


@pytest.fixture()
async def async_client_no_auth(override_get_db) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


async def create_user(db_session, email: str = "test@cadife.com", password: str = "TestPass123!", perfil: UserPerfil = UserPerfil.admin):
    user = User(
        email=email,
        nome="Test User",
        hashed_password=hash_password(password),
        perfil=perfil,
        telefone="+5511999999999",
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.mark.asyncio
async def test_auth_login_missing_password_returns_422(async_client_no_auth):
    response = await async_client_no_auth.post("/auth/login", json={"email": "test@cadife.com"})

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    assert response.json()["detail"]


@pytest.mark.asyncio
async def test_auth_login_invalid_credentials_returns_401(async_client_no_auth):
    response = await async_client_no_auth.post(
        "/auth/login",
        json={"email": "notfound@example.com", "password": "wrongpassword"},
    )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    assert response.json()["detail"] == "Credenciais inválidas"


@pytest.mark.asyncio
async def test_auth_login_valid_credentials_returns_tokens(async_client_no_auth, db_session):
    password = "Secret123!"
    user = await create_user(db_session, password=password)

    response = await async_client_no_auth.post(
        "/auth/login",
        json={"email": user.email, "password": password},
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_users_me_with_invalid_jwt_returns_401(async_client_no_auth):
    response = await async_client_no_auth.get(
        "/users/me",
        headers={"Authorization": "Bearer bad.token.value"},
    )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    assert "Token inválido" in response.json()["detail"]


@pytest.mark.asyncio
async def test_users_me_with_expired_jwt_returns_401(async_client_no_auth, db_session):
    user = await create_user(db_session)
    expired_token = jwt.encode(
        {
            "sub": str(user.id),
            "type": "access",
            "exp": datetime.now(timezone.utc) - timedelta(minutes=5),
        },
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )

    response = await async_client_no_auth.get(
        "/users/me",
        headers={"Authorization": f"Bearer {expired_token}"},
    )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    assert "Token inválido ou expirado" in response.json()["detail"]


@pytest.mark.asyncio
async def test_auth_refresh_with_access_token_returns_401(async_client_no_auth, db_session):
    user = await create_user(db_session)
    access_token = create_access_token(str(user.id))

    response = await async_client_no_auth.post(
        "/auth/refresh",
        json={"refresh_token": access_token},
    )

    assert response.status_code == status.HTTP_401_UNAUTHORIZED
    assert response.json()["detail"] == "Token inválido"


@pytest.mark.asyncio
async def test_register_fcm_token_missing_payload_returns_422(async_client_no_auth, db_session):
    user = await create_user(db_session)
    token = create_access_token(str(user.id))

    response = await async_client_no_auth.post(
        "/users/fcm-token",
        headers={"Authorization": f"Bearer {token}"},
        json={},
    )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    assert response.json()["detail"]


@pytest.mark.asyncio
async def test_users_me_returns_request_id_header(async_client_no_auth, db_session):
    user = await create_user(db_session)
    token = create_access_token(str(user.id))

    response = await async_client_no_auth.get(
        "/users/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == status.HTTP_200_OK
    assert "X-Request-ID" in response.headers
    assert response.headers["X-Request-ID"]
