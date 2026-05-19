import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient
from typing import AsyncGenerator
from main import app
from app.infrastructure.security.jwt import create_access_token, hash_password
from app.models.user import User, UserPerfil
from datetime import datetime, timedelta, timezone
from app.infrastructure.config.settings import get_settings

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

async def create_user_helper(
    db_session,
    email: str = "identity@cadife.com",
    password: str = "Identity123!",
    perfil: UserPerfil = UserPerfil.agencia,
):
    user = User(
        email=email,
        nome="Identity User",
        hashed_password=hash_password(password),
        perfil=perfil,
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user

@pytest.mark.asyncio
async def test_logout_blacklists_token(async_client_no_auth, db_session):
    user = await create_user_helper(db_session)
    token = create_access_token(str(user.id))
    headers = {"Authorization": f"Bearer {token}"}

    # Verify we can access /users/me
    resp1 = await async_client_no_auth.get("/users/me", headers=headers)
    assert resp1.status_code == status.HTTP_200_OK

    # Logout
    resp_logout = await async_client_no_auth.post("/auth/logout", headers=headers)
    assert resp_logout.status_code == status.HTTP_204_NO_CONTENT

    # Verify token is now blocked
    resp2 = await async_client_no_auth.get("/users/me", headers=headers)
    assert resp2.status_code == status.HTTP_401_UNAUTHORIZED
    assert "revogado" in resp2.json()["detail"].lower() or "revogada" in resp2.json()["detail"].lower()

@pytest.mark.asyncio
async def test_logout_all_devices_invalidates_existing_tokens(async_client_no_auth, db_session):
    user = await create_user_helper(db_session)
    # Create token BEFORE global logout
    token = create_access_token(str(user.id))
    headers = {"Authorization": f"Bearer {token}"}

    # Verify access
    resp1 = await async_client_no_auth.get("/users/me", headers=headers)
    assert resp1.status_code == status.HTTP_200_OK

    # Logout all devices
    resp_logout = await async_client_no_auth.post("/auth/logout-all-devices", headers=headers)
    assert resp_logout.status_code == status.HTTP_204_NO_CONTENT

    # Verify existing token is blocked
    resp2 = await async_client_no_auth.get("/users/me", headers=headers)
    assert resp2.status_code == status.HTTP_401_UNAUTHORIZED
    assert "revogada" in resp2.json()["detail"].lower() or "revogado" in resp2.json()["detail"].lower()

    # Wait for the second to change so the new token has a higher iat
    import asyncio
    await asyncio.sleep(1.1)

    # Verify NEW token works
    new_token = create_access_token(str(user.id))
    resp3 = await async_client_no_auth.get("/users/me", headers={"Authorization": f"Bearer {new_token}"})
    assert resp3.status_code == status.HTTP_200_OK

@pytest.mark.asyncio
async def test_change_password_invalidates_all_sessions(async_client_no_auth, db_session):
    password = "InitialPass123!"
    user = await create_user_helper(db_session, password=password)
    
    # Session 1 token
    token1 = create_access_token(str(user.id))
    headers1 = {"Authorization": f"Bearer {token1}"}

    # Change password via Session 1
    new_password = "NewSecurePass456!"
    resp_change = await async_client_no_auth.post(
        "/auth/change-password",
        headers=headers1,
        json={"current_password": password, "new_password": new_password}
    )
    assert resp_change.status_code == status.HTTP_200_OK

    # Verify token1 is now invalid (because password change forces global logout)
    resp_verify = await async_client_no_auth.get("/users/me", headers=headers1)
    assert resp_verify.status_code == status.HTTP_401_UNAUTHORIZED

    import asyncio
    await asyncio.sleep(1.1)

    # Verify login with new password works
    resp_login = await async_client_no_auth.post(
        "/auth/login",
        json={"email": user.email, "password": new_password}
    )
    assert resp_login.status_code == status.HTTP_200_OK
    new_token = resp_login.json()["access_token"]
    
    resp_me = await async_client_no_auth.get("/users/me", headers={"Authorization": f"Bearer {new_token}"})
    assert resp_me.status_code == status.HTTP_200_OK

@pytest.mark.asyncio
async def test_reset_password_invalidates_all_sessions(async_client_no_auth, db_session):
    user = await create_user_helper(db_session)
    old_token = create_access_token(str(user.id))
    
    # Mock a reset token (in real app it would be generated via forgot-password)
    # But reset-password endpoint just needs a valid reset token.
    # Our implementation uses a JWT with type="reset"
    from app.infrastructure.security.jwt import create_reset_token
    reset_token = create_reset_token(str(user.id))
    
    new_password = "ResetPassword789!"
    resp_reset = await async_client_no_auth.post(
        "/auth/reset-password",
        json={"token": reset_token, "new_password": new_password}
    )
    assert resp_reset.status_code == status.HTTP_200_OK

    # Verify old session token is invalid
    resp_verify = await async_client_no_auth.get("/users/me", headers={"Authorization": f"Bearer {old_token}"})
    assert resp_verify.status_code == status.HTTP_401_UNAUTHORIZED

    import asyncio
    await asyncio.sleep(1.1)

    # Verify login with new password
    resp_login = await async_client_no_auth.post(
        "/auth/login",
        json={"email": user.email, "password": new_password}
    )
    assert resp_login.status_code == status.HTTP_200_OK
  
@pytest.mark.asyncio  
async def test_logout_all_devices_invalidates_refresh_tokens(async_client_no_auth, db_session):  
    from app.infrastructure.security.jwt import create_refresh_token  
    user = await create_user_helper(db_session)  
    refresh_token = create_refresh_token(str(user.id))  
    access_token = create_access_token(str(user.id))  
  
    # Logout all devices  
    await async_client_no_auth.post('/auth/logout-all-devices', headers={'Authorization': f'Bearer {access_token}'})  
  
    # Attempt refresh  
    resp = await async_client_no_auth.post('/auth/refresh', json={'refresh_token': refresh_token})  
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED 
