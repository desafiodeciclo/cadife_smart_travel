import pytest
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.services.lead_service import create_manual_lead
from app.presentation.schemas.leads import ManualLeadCreate
from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus
from app.models.lead import Lead

@pytest.mark.asyncio
async def test_create_manual_lead_success(db_session: AsyncSession):
    """Testa a criação bem-sucedida de um lead manual com briefing e score."""
    data = ManualLeadCreate(
        nome="João da Silva",
        telefone="+5511999999999",
        origem=LeadOrigem.indicacao,
        destino_interesse="Paris",
        orcamento_estimado="alto",
        numero_passageiros=2,
        datas_aproximadas="Outubro de 2024"
    )

    lead = await create_manual_lead(db_session, data)

    # Validações básicas no objeto retornado
    assert lead.nome == "João da Silva"
    assert lead.origem == LeadOrigem.indicacao
    assert lead.status == LeadStatus.novo
    assert lead.score == LeadScore.morno

    # Valida persistência e relação com briefing via nova query
    stmt = select(Lead).options(selectinload(Lead.briefing)).where(Lead.id == lead.id)
    res = await db_session.execute(stmt)
    lead_db = res.scalar_one()

    assert lead_db.briefing is not None
    assert lead_db.briefing.destino == "Paris"
    assert lead_db.briefing.completude_pct > 0


@pytest.mark.asyncio
async def test_create_manual_lead_with_preferencias_and_datas(db_session: AsyncSession):
    """Testa que preferencias e datas_aproximadas são persistidas em observacoes."""
    data = ManualLeadCreate(
        nome="Maria Souza",
        telefone="+5511777777777",
        origem=LeadOrigem.presencial,
        destino_interesse="Maldivas",
        numero_passageiros=2,
        datas_aproximadas="2026-12-20",
        preferencias="Hotel beira-mar, voo noturno",
    )

    lead = await create_manual_lead(db_session, data)

    stmt = select(Lead).options(selectinload(Lead.briefing)).where(Lead.id == lead.id)
    res = await db_session.execute(stmt)
    lead_db = res.scalar_one()

    assert lead_db.briefing is not None
    assert lead_db.briefing.observacoes is not None
    assert "2026-12-20" in lead_db.briefing.observacoes
    assert "Hotel beira-mar" in lead_db.briefing.observacoes
    assert "voo noturno" in lead_db.briefing.observacoes

@pytest.mark.asyncio
async def test_create_manual_lead_duplication_blocked(db_session: AsyncSession):
    """Testa que a criação é bloqueada se o telefone já existir (force_create=False)."""
    phone = "+5511888888888"
    data1 = ManualLeadCreate(
        nome="Existente",
        telefone=phone,
        origem=LeadOrigem.telefone
    )
    await create_manual_lead(db_session, data1)

    data2 = ManualLeadCreate(
        nome="Duplicado",
        telefone=phone,
        origem=LeadOrigem.presencial,
        force_create=False
    )

    with pytest.raises(ValueError) as excinfo:
        await create_manual_lead(db_session, data2)
    
    assert "DUPLICATE_LEAD" in str(excinfo.value)
