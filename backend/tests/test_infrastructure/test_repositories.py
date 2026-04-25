"""
Tests — Infrastructure/Persistence/Repositories
=================================================
Unit tests for all concrete repository implementations.
Uses AsyncMock to simulate the SQLAlchemy session — no real DB needed.

Coverage targets:
  - LeadRepository: create, get_by_id, get_by_phone, update_status/score, soft_delete, list_all
  - BriefingRepository: upsert (create + update paths)
  - InteracaoRepository: create, list_by_lead
  - AgendamentoRepository: create, update_status, list_by_lead
  - PropostaRepository: create, update, list_by_lead
"""
import uuid
from datetime import date, time
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.domain.entities.enums import (
    AgendamentoStatus,
    AgendamentoTipo,
    LeadScore,
    LeadStatus,
    PropostaStatus,
    TipoMensagem,
)
from app.infrastructure.persistence.models.lead_model import LeadModel
from app.infrastructure.persistence.models.briefing_model import BriefingModel
from app.infrastructure.persistence.models.interacao_model import InteracaoModel
from app.infrastructure.persistence.models.agendamento_model import AgendamentoModel
from app.infrastructure.persistence.models.proposta_model import PropostaModel
from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
from app.infrastructure.persistence.repositories.briefing_repository import BriefingRepository
from app.infrastructure.persistence.repositories.interacao_repository import InteracaoRepository
from app.infrastructure.persistence.repositories.agendamento_repository import AgendamentoRepository
from app.infrastructure.persistence.repositories.proposta_repository import PropostaRepository


# ── Helpers ─────────────────────────────────────────────────────────────────

def make_session() -> AsyncMock:
    """Return a mock AsyncSession with commonly needed methods."""
    session = AsyncMock()
    session.get = AsyncMock(return_value=None)
    session.execute = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    session.add = MagicMock()
    return session


def fake_lead(phone: str = "5584999990001") -> LeadModel:
    lead = LeadModel()
    lead.id = uuid.uuid4()
    lead.telefone = phone
    lead.nome = "Teste"
    lead.status = LeadStatus.novo.value
    lead.score = None
    lead.is_archived = False
    return lead


# ══════════════════════════════════════════════════════════════════════════════
# LeadRepository
# ══════════════════════════════════════════════════════════════════════════════

class TestLeadRepository:

    @pytest.mark.asyncio
    async def test_create_returns_lead_model(self):
        """create() should add a new LeadModel to session and return it."""
        session = make_session()
        repo = LeadRepository(session)

        lead = fake_lead()
        session.flush = AsyncMock()
        session.refresh = AsyncMock(side_effect=lambda obj: None)
        session.add = MagicMock()

        with patch.object(repo, 'add', AsyncMock(return_value=lead)):
            result = await repo.create(telefone="5584999990001", nome="Teste")

        assert result is lead

    @pytest.mark.asyncio
    async def test_get_by_id_returns_none_when_missing(self):
        """get_by_id() should return None for unknown UUID."""
        session = make_session()
        session.get = AsyncMock(return_value=None)
        repo = LeadRepository(session)

        result = await repo.get_by_id(uuid.uuid4())
        assert result is None

    @pytest.mark.asyncio
    async def test_get_by_id_returns_model(self):
        """get_by_id() should return the ORM model when found."""
        lead = fake_lead()
        session = make_session()
        session.get = AsyncMock(return_value=lead)
        repo = LeadRepository(session)

        result = await repo.get_by_id(lead.id)
        assert result is lead

    @pytest.mark.asyncio
    async def test_get_by_phone_returns_none_when_missing(self):
        """get_by_phone() should return None when no matching phone."""
        session = make_session()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        session.execute = AsyncMock(return_value=mock_result)
        repo = LeadRepository(session)

        result = await repo.get_by_phone("5584000000000")
        assert result is None

    @pytest.mark.asyncio
    async def test_update_status_raises_on_missing_lead(self):
        """update_status() should raise ValueError when lead not found."""
        session = make_session()
        session.get = AsyncMock(return_value=None)
        repo = LeadRepository(session)

        with pytest.raises(ValueError, match="não encontrado"):
            await repo.update_status(uuid.uuid4(), LeadStatus.qualificado)

    @pytest.mark.asyncio
    async def test_update_status_sets_correct_value(self):
        """update_status() should set status enum value on model."""
        lead = fake_lead()
        session = make_session()
        session.get = AsyncMock(return_value=lead)
        repo = LeadRepository(session)

        result = await repo.update_status(lead.id, LeadStatus.qualificado)
        assert result.status == LeadStatus.qualificado.value

    @pytest.mark.asyncio
    async def test_update_score_sets_correct_value(self):
        """update_score() should set score enum value on model."""
        lead = fake_lead()
        session = make_session()
        session.get = AsyncMock(return_value=lead)
        repo = LeadRepository(session)

        result = await repo.update_score(lead.id, LeadScore.quente)
        assert result.score == LeadScore.quente.value

    @pytest.mark.asyncio
    async def test_soft_delete_sets_archived_true(self):
        """soft_delete() should set is_archived=True on the model."""
        lead = fake_lead()
        session = make_session()
        session.get = AsyncMock(return_value=lead)
        repo = LeadRepository(session)

        await repo.soft_delete(lead.id)
        assert lead.is_archived is True

    @pytest.mark.asyncio
    async def test_soft_delete_raises_on_missing_lead(self):
        """soft_delete() should raise ValueError when lead not found."""
        session = make_session()
        session.get = AsyncMock(return_value=None)
        repo = LeadRepository(session)

        with pytest.raises(ValueError):
            await repo.soft_delete(uuid.uuid4())


# ══════════════════════════════════════════════════════════════════════════════
# BriefingRepository
# ══════════════════════════════════════════════════════════════════════════════

class TestBriefingRepository:

    @pytest.mark.asyncio
    async def test_upsert_creates_when_none_exists(self):
        """upsert() should create new BriefingModel when no existing one."""
        session = make_session()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        session.execute = AsyncMock(return_value=mock_result)

        repo = BriefingRepository(session)
        lead_id = uuid.uuid4()
        created_briefing = BriefingModel()
        created_briefing.id = uuid.uuid4()
        created_briefing.lead_id = lead_id

        with patch.object(repo, 'add', AsyncMock(return_value=created_briefing)):
            result = await repo.upsert(lead_id, {"destino": "Paris"})

        assert result is created_briefing

    @pytest.mark.asyncio
    async def test_upsert_updates_when_exists(self):
        """upsert() should update existing briefing when found."""
        existing = BriefingModel()
        existing.id = uuid.uuid4()
        existing.lead_id = uuid.uuid4()
        existing.destino = None
        existing.completude_pct = 0

        session = make_session()
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = existing
        session.execute = AsyncMock(return_value=mock_result)

        repo = BriefingRepository(session)
        result = await repo.upsert(existing.lead_id, {"destino": "Lisboa"})

        assert result.destino == "Lisboa"


# ══════════════════════════════════════════════════════════════════════════════
# InteracaoRepository
# ══════════════════════════════════════════════════════════════════════════════

class TestInteracaoRepository:

    @pytest.mark.asyncio
    async def test_create_interacao(self):
        """create() should call add() and return an InteracaoModel."""
        session = make_session()
        repo = InteracaoRepository(session)
        lead_id = uuid.uuid4()

        interacao = InteracaoModel()
        interacao.id = uuid.uuid4()
        interacao.lead_id = lead_id

        with patch.object(repo, 'add', AsyncMock(return_value=interacao)):
            result = await repo.create(
                lead_id=lead_id,
                mensagem_cliente="Quero ir para Paris",
                tipo_mensagem=TipoMensagem.texto,
            )

        assert result.lead_id == lead_id


# ══════════════════════════════════════════════════════════════════════════════
# AgendamentoRepository
# ══════════════════════════════════════════════════════════════════════════════

class TestAgendamentoRepository:

    @pytest.mark.asyncio
    async def test_create_agendamento(self):
        """create() should return an AgendamentoModel with correct fields."""
        session = make_session()
        repo = AgendamentoRepository(session)
        lead_id = uuid.uuid4()

        ag = AgendamentoModel()
        ag.id = uuid.uuid4()
        ag.lead_id = lead_id
        ag.status = AgendamentoStatus.pendente.value

        with patch.object(repo, 'add', AsyncMock(return_value=ag)):
            result = await repo.create(
                lead_id=lead_id,
                data=date(2026, 6, 15),
                hora=time(10, 0),
                tipo=AgendamentoTipo.online,
            )

        assert result.status == AgendamentoStatus.pendente.value

    @pytest.mark.asyncio
    async def test_update_status_agendamento(self):
        """update_status() should set the correct status value."""
        ag = AgendamentoModel()
        ag.id = uuid.uuid4()
        ag.status = AgendamentoStatus.pendente.value

        session = make_session()
        session.get = AsyncMock(return_value=ag)
        repo = AgendamentoRepository(session)

        result = await repo.update_status(ag.id, AgendamentoStatus.confirmado)
        assert result.status == AgendamentoStatus.confirmado.value


# ══════════════════════════════════════════════════════════════════════════════
# PropostaRepository
# ══════════════════════════════════════════════════════════════════════════════

class TestPropostaRepository:

    @pytest.mark.asyncio
    async def test_create_proposta(self):
        """create() should return PropostaModel in rascunho status."""
        session = make_session()
        repo = PropostaRepository(session)
        lead_id = uuid.uuid4()

        proposta = PropostaModel()
        proposta.id = uuid.uuid4()
        proposta.lead_id = lead_id
        proposta.status = PropostaStatus.rascunho.value

        with patch.object(repo, 'add', AsyncMock(return_value=proposta)):
            result = await repo.create(
                lead_id=lead_id,
                descricao="Pacote Portugal 10 dias",
                valor_estimado=Decimal("12500.00"),
            )

        assert result.status == PropostaStatus.rascunho.value

    @pytest.mark.asyncio
    async def test_update_proposta_status(self):
        """update() with status kwarg should change status correctly."""
        proposta = PropostaModel()
        proposta.id = uuid.uuid4()
        proposta.status = PropostaStatus.rascunho.value
        proposta.descricao = "Pacote X"
        proposta.valor_estimado = None

        session = make_session()
        session.get = AsyncMock(return_value=proposta)
        repo = PropostaRepository(session)

        result = await repo.update(proposta.id, status=PropostaStatus.enviada)
        assert result.status == PropostaStatus.enviada.value

    @pytest.mark.asyncio
    async def test_update_proposta_raises_when_not_found(self):
        """update() should raise ValueError for missing proposta."""
        session = make_session()
        session.get = AsyncMock(return_value=None)
        repo = PropostaRepository(session)

        with pytest.raises(ValueError, match="não encontrada"):
            await repo.update(uuid.uuid4(), status=PropostaStatus.aprovada)
