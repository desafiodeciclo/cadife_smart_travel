import pytest
import uuid
from datetime import date
from pydantic import ValidationError
from app.presentation.schemas.briefing_schema import BriefingSchema
from app.presentation.schemas.lead_schema import LeadCreateSchema
from app.models.briefing import calculate_completude
from app.domain.entities.enums import PerfilViagem, OrcamentoPerfil
from app.services import lead_service
from app.models.lead import Lead
from app.models.briefing import Briefing
from app.models.interacao import Interacao
from app.models.agendamento import Agendamento
from app.models.proposta import Proposta
from app.models.user import User
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import MagicMock, AsyncMock

# ---------------------------------------------------------------------------
# 1. TESTES DE PARSING E VALIDAÇÃO (PYDANTIC)
# ---------------------------------------------------------------------------

def test_briefing_schema_validation_error():
    """Valida erro 422 ao enviar tipos incorretos."""
    with pytest.raises(ValidationError):
        # Orcamento deveria ser um enum/string válido, aqui enviamos algo que falha se validarmos estritamente
        # No caso, orcamento é opcional, mas se passarmos algo que não é OrcamentoPerfil...
        BriefingSchema(orcamento="valor_invalido_que_nao_esta_no_enum")

def test_briefing_schema_date_parsing():
    """Valida conversão de string para objeto date."""
    data = {
        "destino": "Paris",
        "data_ida": "2026-12-25",
        "orcamento": OrcamentoPerfil.alto
    }
    schema = BriefingSchema(**data)
    assert isinstance(schema.data_ida, date)
    assert schema.data_ida == date(2026, 12, 25)

def test_lead_schema_phone_validation():
    """Valida formato E.164 do telefone."""
    with pytest.raises(ValidationError):
        LeadCreateSchema(telefone="123", nome="Teste") # Formato inválido

# ---------------------------------------------------------------------------
# 2. TESTES DE LÓGICA DE COMPLETUDE (COMPLETUDE_PCT)
# ---------------------------------------------------------------------------

def test_calculate_completude_only_destination():
    """Cenário: Apenas destino preenchido = 20% (1/4 dos obrigatórios * 80%)."""
    briefing_data = {"destino": "Maldivas"}
    pct = calculate_completude(briefing_data)
    # REQUIRED_FIELDS = ["destino", "data_ida", "orcamento", "perfil"]
    # (1/4) * 80 = 20. 
    assert pct == 20 

def test_calculate_completude_full():
    """Cenário: Todos os campos preenchidos = 100%."""
    briefing_data = {
        "destino": "Japão",
        "data_ida": date(2026, 5, 10),
        "orcamento": OrcamentoPerfil.premium,
        "perfil": PerfilViagem.casal,
        "data_volta": date(2026, 5, 20),
        "qtd_pessoas": 2,
        "tipo_viagem": ["cultural"],
        "preferencias": ["gastronomia"],
        "tem_passaporte": True
    }
    pct = calculate_completude(briefing_data)
    assert pct == 100

# ---------------------------------------------------------------------------
# 3. TESTES DE PERSISTÊNCIA E UPSERT (MOCKED DB)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_upsert_lead_creation():
    """Valida criação de lead e briefing via upsert service."""
    db = AsyncMock(spec=AsyncSession)
    lead_data = {
        "telefone": "+5511999999999",
        "nome": "João Silva"
    }
    
    # Mock do retorno do scalar_one() para o returning do insert
    mock_lead = Lead(id=uuid.uuid4(), telefone="+5511999999999", nome="João Silva")
    result_mock = MagicMock()
    result_mock.scalar_one.return_value = mock_lead
    db.execute.return_value = result_mock
    
    lead = await lead_service.upsert_lead_with_resilience(db, lead_data)
    
    assert lead.telefone == "+5511999999999"
    assert db.execute.call_count >= 2 # Insert Lead + Insert Briefing

# ---------------------------------------------------------------------------
# 4. TESTES DE RESILIÊNCIA E PII
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_lead_pii_nullable():
    """Verifica se o sistema aceita telefone_hash nulo (simulado)."""
    db = AsyncMock(spec=AsyncSession)
    # Criando objeto diretamente para testar o modelo
    lead = Lead(telefone="+5511999999999", telefone_hash=None)
    assert lead.telefone_hash is None # SQLAlchemy permite na instância

@pytest.mark.asyncio
async def test_database_offline_resilience():
    """Simula UndefinedTableError e verifica tratamento amigável."""
    from sqlalchemy.exc import ProgrammingError
    db = AsyncMock(spec=AsyncSession)
    # Simula erro de tabela inexistente
    db.execute.side_effect = ProgrammingError("statement", "params", "relation \"leads\" does not exist")
    
    with pytest.raises(RuntimeError) as excinfo:
        await lead_service.upsert_lead_with_resilience(db, {"telefone": "+5511988888888"})
    
    assert "Banco de dados não inicializado" in str(excinfo.value)
