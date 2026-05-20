"""
Integration tests — Admin routes
=================================
Tests CRUD of consultants, lead reassignment, and RBAC restrictions.
"""

import uuid

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from main import app
from app.infrastructure.security.jwt import create_access_token, hash_password
from app.domain.entities.enums import UserPerfil
from app.models.user import User
from app.models.lead import Lead
from app.infrastructure.security.pii_encryption import hmac_hash


@pytest.fixture(autouse=True)
def clear_app_overrides():
    app.dependency_overrides.clear()
    yield
    app.dependency_overrides.clear()


@pytest.fixture()
async def async_client_no_auth(override_get_db) -> AsyncClient:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


async def create_admin(db_session, email: str = "admin@cadife.com"):
    user = User(
        email=email,
        nome="Admin Test",
        hashed_password=hash_password("Secret123!"),
        perfil=UserPerfil.admin,
        is_active=True,
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


async def create_consultor(db_session, email: str = "consultor@cadife.com"):
    user = User(
        email=email,
        nome="Consultor Test",
        hashed_password=hash_password("Secret123!"),
        perfil=UserPerfil.consultor,
        is_active=True,
        telefone="+5511988888888",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


async def create_lead(db_session, consultor_id: uuid.UUID | None = None):
    phone = "+5511999999999"
    lead = Lead(
        nome="Lead Test",
        telefone=phone,
        telefone_hash=hmac_hash(phone),
        consultor_id=consultor_id,
    )
    db_session.add(lead)
    await db_session.commit()
    await db_session.refresh(lead)
    return lead


@pytest.mark.asyncio
async def test_create_consultor_success(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.post(
        "/admin/users",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "nome": "Novo Consultor",
            "email": "novo@cadife.com",
            "telefone": "+5511977777777",
            "role": "consultor",
        },
    )

    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["nome"] == "Novo Consultor"
    assert data["email"] == "novo@cadife.com"
    assert data["perfil"] == "consultor"
    assert data["is_active"] is True
    assert "metrics" in data


@pytest.mark.asyncio
async def test_create_consultor_duplicate_email_returns_409(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    await create_consultor(db_session, email="duplicado@cadife.com")
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.post(
        "/admin/users",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "nome": "Outro",
            "email": "duplicado@cadife.com",
            "role": "consultor",
        },
    )

    assert response.status_code == status.HTTP_409_CONFLICT
    assert "E-mail já cadastrado" in response.json()["detail"]


@pytest.mark.asyncio
async def test_list_users_returns_consultores(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    await create_lead(db_session, consultor_id=consultor.id)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.get(
        "/admin/users",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    emails = {u["email"] for u in data["items"]}
    # Admin é excluído da lista de consultores; apenas consultor/agencia aparecem.
    assert admin.email not in emails
    assert consultor.email in emails


@pytest.mark.asyncio
async def test_update_consultor_success(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.patch(
        f"/admin/users/{consultor.id}",
        headers={"Authorization": f"Bearer {token}"},
        json={"nome": "Consultor Atualizado", "is_active": False},
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["nome"] == "Consultor Atualizado"
    assert data["is_active"] is False


@pytest.mark.asyncio
async def test_delete_consultor_soft_delete(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.delete(
        f"/admin/users/{consultor.id}",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == status.HTTP_204_NO_CONTENT


@pytest.mark.asyncio
async def test_delete_consultor_with_reassign(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    target = await create_consultor(db_session, email="target@cadife.com")
    lead = await create_lead(db_session, consultor_id=consultor.id)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.delete(
        f"/admin/users/{consultor.id}",
        headers={"Authorization": f"Bearer {token}"},
        params={"reassign_to": str(target.id)},
    )

    assert response.status_code == status.HTTP_204_NO_CONTENT
    # Verify lead was reassigned
    from sqlalchemy import select
    result = await db_session.execute(select(Lead).where(Lead.id == lead.id))
    updated_lead = result.scalar_one()
    assert updated_lead.consultor_id == target.id


@pytest.mark.asyncio
async def test_reassign_lead_success(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    old_consultor = await create_consultor(db_session, email="old@cadife.com")
    new_consultor = await create_consultor(db_session, email="new@cadife.com")
    lead = await create_lead(db_session, consultor_id=old_consultor.id)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.patch(
        f"/admin/leads/{lead.id}/reassign",
        headers={"Authorization": f"Bearer {token}"},
        json={"new_consultor_id": str(new_consultor.id)},
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["old_consultor_id"] == str(old_consultor.id)
    assert data["new_consultor_id"] == str(new_consultor.id)
    assert data["lead_id"] == str(lead.id)


@pytest.mark.asyncio
async def test_reassign_lead_same_consultor_returns_422(async_client_no_auth, db_session):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    lead = await create_lead(db_session, consultor_id=consultor.id)
    token = create_access_token(str(admin.id))

    response = await async_client_no_auth.patch(
        f"/admin/leads/{lead.id}/reassign",
        headers={"Authorization": f"Bearer {token}"},
        json={"new_consultor_id": str(consultor.id)},
    )

    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT
    assert "já pertence" in response.json()["detail"]


@pytest.mark.asyncio
async def test_agency_metrics_returns_global_aggregation(
    async_client_no_auth, db_session
):
    admin = await create_admin(db_session)
    consultor = await create_consultor(db_session)
    # Lead with consultor assigned
    await create_lead(db_session, consultor_id=consultor.id)
    # Orphan lead (no consultor) — must still be counted globally
    orphan_phone = "+5511977777777"
    orphan = Lead(
        nome="Orphan Lead",
        telefone=orphan_phone,
        telefone_hash=hmac_hash(orphan_phone),
        consultor_id=None,
    )
    db_session.add(orphan)
    await db_session.commit()

    token = create_access_token(str(admin.id))
    response = await async_client_no_auth.get(
        "/admin/metrics",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["total_leads"] >= 2
    assert data["consultores_ativos"] >= 1
    assert "receita_estimada" in data
    assert "leads_novos_mes" in data
    assert "leads_fechados_mes" in data
    assert "leads_perdidos_mes" in data


@pytest.mark.asyncio
async def test_agency_metrics_forbidden_for_consultor(
    async_client_no_auth, db_session
):
    consultor = await create_consultor(db_session)
    token = create_access_token(str(consultor.id))
    response = await async_client_no_auth.get(
        "/admin/metrics",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN


@pytest.mark.asyncio
async def test_auto_assign_orphans_endpoint_distributes(
    async_client_no_auth, db_session
):
    admin = await create_admin(db_session)
    consultor_a = await create_consultor(db_session, email="ana@x.com")
    consultor_b = await create_consultor(db_session, email="bia@x.com")

    # 5 orphan leads
    for i in range(5):
        phone = f"+551199999{i:04d}"
        lead = Lead(
            nome=f"Orphan {i}",
            telefone=phone,
            telefone_hash=hmac_hash(phone),
            consultor_id=None,
        )
        db_session.add(lead)
    await db_session.commit()

    token = create_access_token(str(admin.id))
    response = await async_client_no_auth.post(
        "/admin/leads/auto-assign-orphans",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["assigned"] == 5
    assert data["skipped"] == 0
    assert data["no_consultor_available"] is False


@pytest.mark.asyncio
async def test_non_admin_cannot_access_admin_routes(async_client_no_auth, db_session):
    consultor = await create_consultor(db_session)
    token = create_access_token(str(consultor.id))

    response = await async_client_no_auth.get(
        "/admin/users",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "permissão insuficiente" in response.json()["detail"]
