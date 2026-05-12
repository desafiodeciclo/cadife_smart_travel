import pytest
import uuid
from datetime import datetime, timezone
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.persistence.models.user_model import UserModel
from app.infrastructure.security.jwt import create_access_token

@pytest.mark.asyncio
async def test_get_me_unauthorized(async_client: AsyncClient):
    """Should return 401 if no token is provided."""
    # We use the raw client to ensure we are testing the middleware, 
    # as the async_client fixture might have overrides.
    response = await async_client.get("/users/me")
    assert response.status_code == 401
    # FastAPI HTTPBearer returns "Not authenticated" when token is missing
    assert response.json()["detail"] == "Not authenticated"

@pytest.mark.asyncio
async def test_get_me_invalid_token(async_client: AsyncClient, invalid_jwt_token: str):
    """Should return 401 if token is invalid."""
    headers = {"Authorization": f"Bearer {invalid_jwt_token}"}
    response = await async_client.get("/users/me", headers=headers)
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid token"

@pytest.mark.asyncio
async def test_get_me_expired_token(async_client: AsyncClient, expired_jwt_token: str):
    """Should return 401 if token is expired."""
    headers = {"Authorization": f"Bearer {expired_jwt_token}"}
    response = await async_client.get("/users/me", headers=headers)
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid token"

@pytest.mark.asyncio
async def test_get_me_success(async_client: AsyncClient, db_session: AsyncSession):
    """Should return 200 and user data if valid token is provided."""
    # 1. Create a user in the test DB
    user_id = uuid.uuid4()
    user = UserModel(
        id=user_id,
        nome="Authenticated User",
        email="auth_test@example.com",
        hashed_password="hashed_password_here",
        perfil="consultor",
        is_active=True,
        criado_em=datetime.now(timezone.utc),
    )
    db_session.add(user)
    await db_session.commit()

    # 2. Generate a token for this specific user
    token = create_access_token(str(user_id))

    # 3. Request /me
    headers = {"Authorization": f"Bearer {token}"}
    response = await async_client.get("/users/me", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(user_id)
    assert data["email"] == "auth_test@example.com"
    assert data["nome"] == "Authenticated User"
