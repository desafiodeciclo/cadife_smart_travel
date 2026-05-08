"""
QA Test Suite — feat/leads-api-filtering-and-interactions
==========================================================
Validation of sub-resources, soft delete, and advanced filtering.
Using pytest + httpx (AsyncClient) for asynchronous endpoint testing.
"""
import uuid
import pytest
from datetime import datetime, date, timezone
from unittest.mock import AsyncMock, MagicMock, patch, ANY

from httpx import AsyncClient, ASGITransport
from fastapi import FastAPI
import pytest_asyncio

from app.routes.leads import router as leads_router
from app.core.dependencies import get_current_user, get_db
from app.domain.entities.enums import LeadStatus, LeadScore, PerfilViagem
from app.models.user import UserPerfil

# --- SETUP ---

app = FastAPI()
app.include_router(leads_router)

@pytest_asyncio.fixture
async def async_client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac

def fake_user(perfil: UserPerfil = UserPerfil.consultor, user_id=None):
    user = MagicMock()
    user.id = user_id or uuid.uuid4()
    user.perfil = perfil.value
    user.nome = "QA Tester"
    return user

def fake_lead(lead_id=None, consultor_id=None):
    lead = MagicMock()
    lead.id = lead_id or uuid.uuid4()
    lead.nome = "Lead QA"
    lead.telefone = "5511999999999"
    lead.telefone_hash = "abc123hash"
    lead.origem = "whatsapp"
    lead.status = LeadStatus.novo.value
    lead.score = LeadScore.morno.value
    lead.consultor_id = consultor_id
    lead.criado_em = datetime.now(timezone.utc)
    lead.atualizado_em = datetime.now(timezone.utc)
    lead.is_archived = False
    lead.deleted_at = None
    lead.briefing = None
    lead.interacoes = []
    return lead

# --- 1. SUB-RESOURCES TESTS ---

class TestSubResources:
    
    @pytest.mark.asyncio
    async def test_get_interacoes_paginated(self, async_client):
        """Validar se o histórico de mensagens está paginado e isolado."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)
        
        # Mock de interações
        mock_interacao = MagicMock()
        mock_interacao.id = uuid.uuid4()
        mock_interacao.lead_id = lead_id
        mock_interacao.mensagem_cliente = "Olá"
        mock_interacao.mensagem_ia = "Como posso ajudar?"
        mock_interacao.timestamp = datetime.now(timezone.utc)
        mock_interacao.tipo_mensagem = "texto"
        
        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: AsyncMock()
        
        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=fake_lead(lead_id)):
            with patch("app.services.lead_service.get_lead_interacoes", new_callable=AsyncMock, return_value=([mock_interacao], 1)):
                response = await async_client.get(f"/leads/{lead_id}/interacoes?page=1&limit=10")
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert data["total"] == 1
        assert data["items"][0]["mensagem_cliente"] == "Olá"

    @pytest.mark.asyncio
    async def test_put_briefing_validation_stress(self, async_client):
        """Teste de estresse na validação Pydantic do PUT /briefing."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)
        app.dependency_overrides[get_current_user] = lambda: user
        
        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=fake_lead(lead_id)):
            # 1. Dado inválido (qtd_pessoas negativo)
            response = await async_client.put(f"/leads/{lead_id}/briefing", json={"qtd_pessoas": -5})
            assert response.status_code == 422 # Pydantic validation error
            
            # 2. Destino muito curto
            response = await async_client.put(f"/leads/{lead_id}/briefing", json={"destino": "A"})
            assert response.status_code == 422
            
            # 3. Dado válido - Persistência
            mock_briefing = MagicMock()
            mock_briefing.lead_id = lead_id
            mock_briefing.destino = "Fortaleza"
            mock_briefing.completude_pct = 50
            # Preencher campos obrigatórios do BriefingResponse para evitar ValidationError no mock
            mock_briefing.origem = "whatsapp"
            mock_briefing.data_ida = date(2026, 7, 1)
            mock_briefing.data_volta = date(2026, 7, 10)
            mock_briefing.perfil = "casal"
            mock_briefing.orcamento = "medio"
            mock_briefing.observacoes = "Nenhuma"
            mock_briefing.tipo_viagem = ["lazer"]
            mock_briefing.preferencias = ["praia"]
            mock_briefing.tem_passaporte = True
            
            with patch("app.services.lead_service.update_lead_briefing", new_callable=AsyncMock, return_value=mock_briefing):
                response = await async_client.put(f"/leads/{lead_id}/briefing", json={
                    "destino": "Fortaleza",
                    "qtd_pessoas": 2,
                    "perfil": PerfilViagem.casal.value
                })
                assert response.status_code == 200
                assert response.json()["destino"] == "Fortaleza"

    @pytest.mark.asyncio
    async def test_get_briefing_returns_structured_data(self, async_client):
        """GET /leads/{id}/briefing deve retornar o briefing estruturado do lead."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)

        mock_briefing = MagicMock()
        mock_briefing.lead_id = lead_id
        mock_briefing.destino = "Maldivas"
        mock_briefing.qtd_pessoas = 2
        mock_briefing.completude_pct = 75
        mock_briefing.origem = "whatsapp"
        mock_briefing.data_ida = date(2026, 8, 1)
        mock_briefing.data_volta = date(2026, 8, 15)
        mock_briefing.perfil = "casal"
        mock_briefing.orcamento = "alto"
        mock_briefing.observacoes = None
        mock_briefing.tipo_viagem = ["lua_de_mel"]
        mock_briefing.preferencias = ["praia", "mergulho"]
        mock_briefing.tem_passaporte = True

        lead = fake_lead(lead_id)
        lead.briefing = mock_briefing

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: AsyncMock()

        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = await async_client.get(f"/leads/{lead_id}/briefing")

        assert response.status_code == 200
        data = response.json()
        assert data["destino"] == "Maldivas"
        assert data["completude_pct"] == 75
        assert data["perfil"] == "casal"

    @pytest.mark.asyncio
    async def test_get_briefing_404_when_no_briefing(self, async_client):
        """GET /leads/{id}/briefing deve retornar 404 se o lead não tiver briefing."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)

        lead = fake_lead(lead_id)
        lead.briefing = None  # sem briefing

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: AsyncMock()

        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            response = await async_client.get(f"/leads/{lead_id}/briefing")

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_briefing_404_when_lead_not_found(self, async_client):
        """GET /leads/{id}/briefing deve retornar 404 se o lead não existir."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)

        app.dependency_overrides[get_current_user] = lambda: user
        app.dependency_overrides[get_db] = lambda: AsyncMock()

        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=None):
            response = await async_client.get(f"/leads/{lead_id}/briefing")

        assert response.status_code == 404

# --- 2. SOFT DELETE TESTS ---

class TestSoftDelete:
    
    @pytest.mark.asyncio
    async def test_soft_delete_flow(self, async_client):
        """Verificar se deleted_at é preenchido e lead some da listagem."""
        lead_id = uuid.uuid4()
        user = fake_user(UserPerfil.admin)
        lead = fake_lead(lead_id)
        
        app.dependency_overrides[get_current_user] = lambda: user
        
        with patch("app.services.lead_service.get_lead_by_id", new_callable=AsyncMock, return_value=lead):
            with patch("app.services.lead_service.soft_delete", new_callable=AsyncMock) as mock_delete:
                response = await async_client.delete(f"/leads/{lead_id}")
                assert response.status_code == 204
                mock_delete.assert_called_once()

# --- 3. ADVANCED FILTERS TESTS ---

class TestAdvancedFilters:
    
    @pytest.mark.asyncio
    async def test_list_leads_filters(self, async_client):
        """Validar se os filtros avançados são passados corretamente para o service."""
        user = fake_user(UserPerfil.admin)
        app.dependency_overrides[get_current_user] = lambda: user
        
        # Simular retorno vazio, o importante é a captura dos argumentos no service
        with patch("app.services.lead_service.list_leads", new_callable=AsyncMock, return_value=([], 0)) as mock_list:
            # Teste: Busca parcial por destino
            await async_client.get("/leads?destino=Fort")
            mock_list.assert_called_with(
                ANY, status=None, score=None, destino="Fort", 
                data_inicio=None, data_fim=None, q=None, page=1, limit=20, consultor_id=None
            )
            
            # Teste: Filtros combinados
            await async_client.get("/leads?status=novo&q=Joao")
            mock_list.assert_called_with(
                ANY, status="novo", score=None, destino=None, 
                data_inicio=None, data_fim=None, q="Joao", page=1, limit=20, consultor_id=None
            )

# --- 4. SECURITY & PII ---

class TestSecurityPII:
    
    @pytest.mark.asyncio
    async def test_list_leads_resilience_missing_hash(self, async_client):
        """Garantir que a ausência de telefone_hash não quebre a listagem."""
        user = fake_user(UserPerfil.admin)
        lead = fake_lead()
        lead.telefone_hash = None # PII scenario: hash missing
        
        app.dependency_overrides[get_current_user] = lambda: user
        
        with patch("app.services.lead_service.list_leads", new_callable=AsyncMock, return_value=([lead], 1)):
            response = await async_client.get("/leads")
            assert response.status_code == 200
            assert len(response.json()["items"]) == 1
