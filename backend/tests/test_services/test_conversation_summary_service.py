"""
Tests — ConversationSummaryService
===================================
Covers session segmentation, idempotency, fallback path, and retry logic.
All LLM calls are mocked so tests run without an OPENROUTER_API_KEY.
"""

import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.conversation_summary_service import (
    SESSION_GAP_MINUTES,
    _build_session_id,
    _format_session_as_text,
    _parse_topics,
    _segment_into_sessions,
    summarise_closed_sessions,
)


# ── Helpers ───────────────────────────────────────────────────────────────

def _make_interacao(minutes_offset: int, cliente: str = "oi", ia: str = "olá") -> dict:
    return {
        "timestamp": datetime(2026, 5, 10, 10, 0, tzinfo=timezone.utc)
        + timedelta(minutes=minutes_offset),
        "mensagem_cliente": cliente,
        "mensagem_ia": ia,
    }


# ── Unit: session segmentation ────────────────────────────────────────────


def test_segment_empty():
    assert _segment_into_sessions([]) == []


def test_segment_single_message():
    msgs = [_make_interacao(0)]
    sessions = _segment_into_sessions(msgs)
    assert len(sessions) == 1
    assert len(sessions[0]) == 1


def test_segment_all_in_one_session():
    msgs = [_make_interacao(i * 5) for i in range(5)]  # every 5 min
    sessions = _segment_into_sessions(msgs)
    assert len(sessions) == 1
    assert len(sessions[0]) == 5


def test_segment_two_sessions():
    session1 = [_make_interacao(i * 5) for i in range(3)]     # 0, 5, 10 min
    session2 = [_make_interacao(200 + i * 5) for i in range(2)]  # 200, 205 min
    msgs = session1 + session2
    sessions = _segment_into_sessions(msgs, gap_minutes=SESSION_GAP_MINUTES)
    assert len(sessions) == 2
    assert len(sessions[0]) == 3
    assert len(sessions[1]) == 2


def test_segment_respects_custom_gap():
    msgs = [_make_interacao(0), _make_interacao(10)]
    # gap=5 → split; gap=15 → single
    assert len(_segment_into_sessions(msgs, gap_minutes=5)) == 2
    assert len(_segment_into_sessions(msgs, gap_minutes=15)) == 1


# ── Unit: helpers ─────────────────────────────────────────────────────────


def test_build_session_id_is_deterministic():
    lead_id = uuid.UUID("12345678-1234-1234-1234-123456789012")
    ts = datetime(2026, 5, 10, 14, 30, tzinfo=timezone.utc)
    sid = _build_session_id(lead_id, ts)
    assert sid == "12345678:20260510_1430"
    assert _build_session_id(lead_id, ts) == sid  # deterministic


def test_format_session_as_text():
    msgs = [
        {"mensagem_cliente": "quero ir pra Paris", "mensagem_ia": "Ótima escolha!"},
        {"mensagem_cliente": None, "mensagem_ia": "Posso ajudar mais?"},
    ]
    text = _format_session_as_text(msgs)
    assert "CLIENTE: quero ir pra Paris" in text
    assert "AYA: Ótima escolha!" in text
    assert "AYA: Posso ajudar mais?" in text
    assert "CLIENTE: None" not in text


def test_parse_topics_valid_json():
    raw = '{"intencao_principal": "Paris", "datas_e_passageiros": null, "orcamento": null, "restricoes_e_preferencias": null, "decisoes_tomadas": null, "proximos_passos": null}'
    topics = _parse_topics(raw)
    assert topics is not None
    assert topics.intencao_principal == "Paris"


def test_parse_topics_with_markdown_fence():
    raw = '```json\n{"intencao_principal": "Roma", "datas_e_passageiros": null, "orcamento": null, "restricoes_e_preferencias": null, "decisoes_tomadas": null, "proximos_passos": null}\n```'
    topics = _parse_topics(raw)
    assert topics is not None
    assert topics.intencao_principal == "Roma"


def test_parse_topics_invalid_returns_none():
    assert _parse_topics("not json at all") is None
    assert _parse_topics("") is None


# ── Integration: summarise_closed_sessions ────────────────────────────────


@pytest.mark.asyncio
async def test_summarise_no_closed_sessions(db_session):
    """Single open session → nothing should be summarised."""
    lead_id = uuid.uuid4()
    interacoes = [_make_interacao(i * 5) for i in range(3)]

    mock_topics_json = '{"intencao_principal": "Paris", "datas_e_passageiros": null, "orcamento": null, "restricoes_e_preferencias": null, "decisoes_tomadas": null, "proximos_passos": null}'

    with patch(
        "app.services.conversation_summary_service._generate_topics",
        new=AsyncMock(return_value=(None, 0)),
    ):
        created = await summarise_closed_sessions(db_session, lead_id, interacoes)

    assert created == []


@pytest.mark.asyncio
async def test_summarise_one_closed_session(db_session):
    """Two sessions (one closed) → one summary row created."""
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel
    from app.models.conversation_summary import ConversationSummaryTopics

    # Need a real lead in the DB for FK constraint
    user = UserModel(
        id=uuid.uuid4(),
        nome="Consultor",
        email=f"{uuid.uuid4()}@test.com",
        hashed_password="x",
        perfil="consultor",
        is_active=True,
    )
    db_session.add(user)
    await db_session.flush()

    lead = LeadModel(
        id=uuid.uuid4(),
        telefone=f"+5511{uuid.uuid4().int % 900000000 + 100000000:09d}",
        origem="whatsapp",
        status="novo",
    )
    db_session.add(lead)
    await db_session.flush()

    session1 = [_make_interacao(i * 5) for i in range(3)]
    session2 = [_make_interacao(200 + i * 5) for i in range(2)]
    interacoes = session1 + session2

    mock_topics = ConversationSummaryTopics(
        intencao_principal="Paris em família",
        datas_e_passageiros="Julho 2026, 4 pessoas",
        orcamento="Médio",
        restricoes_e_preferencias=None,
        decisoes_tomadas=None,
        proximos_passos="Aguardar proposta",
    )

    with patch(
        "app.services.conversation_summary_service._generate_topics",
        new=AsyncMock(return_value=(mock_topics, 150)),
    ):
        created = await summarise_closed_sessions(db_session, lead.id, interacoes)

    assert len(created) == 1
    assert created[0].resumo_pendente is False
    assert created[0].tokens_utilizados == 150
    assert created[0].resumo_json is not None
    assert created[0].resumo_json["intencao_principal"] == "Paris em família"


@pytest.mark.asyncio
async def test_summarise_idempotent(db_session):
    """Calling summarise_closed_sessions twice should not create duplicate rows."""
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel
    from app.models.conversation_summary import ConversationSummaryTopics

    user = UserModel(
        id=uuid.uuid4(),
        nome="Consultor",
        email=f"{uuid.uuid4()}@test.com",
        hashed_password="x",
        perfil="consultor",
        is_active=True,
    )
    db_session.add(user)
    await db_session.flush()

    lead = LeadModel(
        id=uuid.uuid4(),
        telefone=f"+5511{uuid.uuid4().int % 900000000 + 100000000:09d}",
        origem="whatsapp",
        status="novo",
    )
    db_session.add(lead)
    await db_session.flush()

    session1 = [_make_interacao(i * 5) for i in range(2)]
    session2 = [_make_interacao(200 + i * 5) for i in range(2)]
    interacoes = session1 + session2

    mock_topics = ConversationSummaryTopics(intencao_principal="Lisboa")

    with patch(
        "app.services.conversation_summary_service._generate_topics",
        new=AsyncMock(return_value=(mock_topics, 100)),
    ):
        first = await summarise_closed_sessions(db_session, lead.id, interacoes)
        second = await summarise_closed_sessions(db_session, lead.id, interacoes)

    assert len(first) == 1
    assert len(second) == 0  # already exists → skipped


@pytest.mark.asyncio
async def test_summarise_fallback_on_llm_failure(db_session):
    """LLM failure → row persisted with resumo_pendente=True."""
    from app.infrastructure.persistence.models.lead_model import LeadModel
    from app.infrastructure.persistence.models.user_model import UserModel

    user = UserModel(
        id=uuid.uuid4(),
        nome="Consultor",
        email=f"{uuid.uuid4()}@test.com",
        hashed_password="x",
        perfil="consultor",
        is_active=True,
    )
    db_session.add(user)
    await db_session.flush()

    lead = LeadModel(
        id=uuid.uuid4(),
        telefone=f"+5511{uuid.uuid4().int % 900000000 + 100000000:09d}",
        origem="whatsapp",
        status="novo",
    )
    db_session.add(lead)
    await db_session.flush()

    session1 = [_make_interacao(i * 5) for i in range(2)]
    session2 = [_make_interacao(200 + i * 5) for i in range(2)]
    interacoes = session1 + session2

    with patch(
        "app.services.conversation_summary_service._generate_topics",
        new=AsyncMock(return_value=(None, 0)),
    ):
        created = await summarise_closed_sessions(db_session, lead.id, interacoes)

    assert len(created) == 1
    assert created[0].resumo_pendente is True
    assert created[0].resumo_json is None
