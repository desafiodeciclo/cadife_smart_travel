
import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.lead import Lead
from app.models.user import User
from app.domain.entities.enums import LeadStatus
from app.infrastructure.persistence.models.aya_toggle_history_model import AyaToggleHistoryModel
from app.infrastructure.security.dependencies import get_current_user
from main import app

@pytest.fixture
def consultant_user():
    return User(
        id=uuid.uuid4(),
        nome="Consultant User",
        email="consultant@example.com",
        perfil="consultor",
        is_active=True
    )

@pytest.fixture
def other_consultant():
    return User(
        id=uuid.uuid4(),
        nome="Other Consultant",
        email="other@example.com",
        perfil="consultor",
        is_active=True
    )

@pytest.mark.asyncio
async def test_toggle_aya_success_admin(client: TestClient, db_session: AsyncSession):
    # Setup: Create a lead
    lead = Lead(
        id=uuid.uuid4(),
        nome="Lead Teste",
        telefone="+5511988887777",
        aya_ativo=True,
        status=LeadStatus.novo
    )
    db_session.add(lead)
    await db_session.commit()

    # Action: Toggle AYA to false
    response = client.patch(
        f"/leads/{lead.id}/aya-toggle",
        json={"ativo": False, "motivo": "Teste de desativação"}
    )

    # Assertions
    assert response.status_code == 200
    data = response.json()
    assert data["aya_ativo"] is False
    assert data["motivo"] == "Teste de desativação"

    # Verify DB state
    await db_session.refresh(lead)
    assert lead.aya_ativo is False

    # Verify History
    result = await db_session.execute(select(AyaToggleHistoryModel).where(AyaToggleHistoryModel.lead_id == lead.id))
    history = result.scalars().all()
    assert len(history) == 1
    assert history[0].ativo is False
    assert history[0].motivo == "Teste de desativação"

@pytest.mark.asyncio
async def test_toggle_aya_consultant_own_lead(client: TestClient, db_session: AsyncSession, consultant_user):
    # Setup: Lead assigned to consultant
    lead = Lead(
        id=uuid.uuid4(),
        nome="Lead Consultant",
        telefone="+5511966665555",
        aya_ativo=True,
        status=LeadStatus.novo,
        consultor_id=consultant_user.id
    )
    db_session.add(lead)
    await db_session.commit()

    # Override user to be the consultant
    async def get_consultant():
        return consultant_user
    app.dependency_overrides[get_current_user] = get_consultant

    try:
        response = client.patch(
            f"/leads/{lead.id}/aya-toggle",
            json={"ativo": False, "motivo": "Atendimento manual"}
        )
        assert response.status_code == 200
        assert response.json()["aya_ativo"] is False
    finally:
        app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_toggle_aya_consultant_forbidden(client: TestClient, db_session: AsyncSession, other_consultant):
    # Setup: Lead assigned to a different consultant
    lead = Lead(
        id=uuid.uuid4(),
        nome="Lead Other",
        telefone="+5511944443333",
        aya_ativo=True,
        status=LeadStatus.novo,
        consultor_id=uuid.uuid4() # Different ID
    )
    db_session.add(lead)
    await db_session.commit()

    # Override user to be the other consultant
    async def get_consultant():
        return other_consultant
    app.dependency_overrides[get_current_user] = get_consultant

    try:
        response = client.patch(
            f"/leads/{lead.id}/aya-toggle",
            json={"ativo": False, "motivo": "Tentativa indevida"}
        )
        assert response.status_code == 403
        assert "Acesso negado" in response.json()["detail"]
    finally:
        app.dependency_overrides.pop(get_current_user, None)

@pytest.mark.asyncio
async def test_toggle_aya_history_integrity(client: TestClient, db_session: AsyncSession):
    # Setup: Lead
    lead = Lead(
        id=uuid.uuid4(),
        nome="Lead History",
        telefone="+5511922221111",
        aya_ativo=False,
        status=LeadStatus.novo
    )
    db_session.add(lead)
    await db_session.commit()

    # Action: Toggle AYA to true
    client.patch(
        f"/leads/{lead.id}/aya-toggle",
        json={"ativo": True, "motivo": "Retomada"}
    )

    # Verify History has correct fields
    result = await db_session.execute(select(AyaToggleHistoryModel).where(AyaToggleHistoryModel.lead_id == lead.id))
    history = result.scalar_one()
    assert history.ativo is True
    assert history.motivo == "Retomada"
    assert history.alterado_por is not None
    assert history.alterado_em is not None
