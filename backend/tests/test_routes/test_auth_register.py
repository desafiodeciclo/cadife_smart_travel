import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import status

from app.models.user import User

@pytest.mark.asyncio
async def test_register_success(async_client: AsyncClient, db_session: AsyncSession):
    payload = {
        "name": "Test User",
        "email": "test_register@cadife.com",
        "password": "StrongPassword123"
    }
    
    response = await async_client.post("/auth/register", json=payload)
    
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"

@pytest.mark.asyncio
async def test_register_duplicate_email(async_client: AsyncClient, db_session: AsyncSession):
    payload = {
        "name": "Duplicate User",
        "email": "duplicate@cadife.com",
        "password": "StrongPassword123"
    }
    
    # First registration
    await async_client.post("/auth/register", json=payload)
    
    # Second registration should fail
    response = await async_client.post("/auth/register", json=payload)
    assert response.status_code == status.HTTP_409_CONFLICT
    assert response.json()["detail"] == "email_already_registered"

@pytest.mark.asyncio
async def test_register_weak_password(async_client: AsyncClient, db_session: AsyncSession):
    payload = {
        "name": "Weak User",
        "email": "weak@cadife.com",
        "password": "weakpassword" # no digits
    }
    
    response = await async_client.post("/auth/register", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    # Should contain validation error for password field
    assert any("password must contain letters and digits" in err["msg"] for err in response.json()["detail"])
