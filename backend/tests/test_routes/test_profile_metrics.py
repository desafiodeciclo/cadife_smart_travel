import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient
from main import app
from app.infrastructure.security.jwt import create_access_token
from app.models.user import User, UserPerfil
from app.infrastructure.persistence.models.sale_goal_model import SaleGoalModel
from datetime import datetime, timezone

@pytest.fixture()
async def auth_headers(db_session, override_get_db):
    user = User(
        email="metrics@cadife.com",
        nome="Metrics User",
        hashed_password="...",
        perfil=UserPerfil.consultor,
        is_active=True
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    token = create_access_token(str(user.id))
    return {"Authorization": f"Bearer {token}"}, user

@pytest.mark.asyncio
async def test_update_bio_sanitization(auth_headers):
    headers, user = auth_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.patch(
            "/users/me/bio",
            headers=headers,
            json={"bio": "Hello <script>alert(1)</script> world!"}
        )
        assert resp.status_code == 200
        assert resp.json()["bio"] == "Hello alert(1) world!"

@pytest.mark.asyncio
async def test_get_metrics_empty(auth_headers):
    headers, user = auth_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/users/me/metrics", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["leads_total"] == 0
        assert data["taxa_conversao"] == 0.0

@pytest.mark.asyncio
async def test_get_goals_backfill(auth_headers):
    headers, user = auth_headers
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/users/me/goals?months=2", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["goals"]) == 2
        assert data["goals"][0]["target"] == 0
