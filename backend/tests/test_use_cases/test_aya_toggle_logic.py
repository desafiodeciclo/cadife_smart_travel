"""
Tests — AYA toggle logic
========================
Covers the aya_ativo field behaviour for leads.

Note: aya_ativo early-return logic is tracked as a pending feature
(currently the execute() flow always runs the full AI path regardless
of aya_ativo). Tests verify the full flow works correctly for both states.
"""

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.application.use_cases import process_whatsapp_message
from app.domain.entities.enums import LeadStatus
from app.services.whatsapp_service import SendResult


def _text_payload(phone: str = "5584999990001", text: str = "Olá") -> dict:
    return {
        "entry": [
            {
                "changes": [
                    {
                        "value": {
                            "messages": [
                                {
                                    "from": phone,
                                    "id": "wamid.test",
                                    "type": "text",
                                    "text": {"body": text},
                                }
                            ],
                            "contacts": [{"profile": {"name": "Maria"}}],
                        }
                    }
                ]
            }
        ]
    }


def _fake_lead(phone: str = "5584999990001", aya_ativo: bool = True):
    lead = MagicMock()
    lead.id = uuid.uuid4()
    lead.telefone = phone
    lead.status = LeadStatus.novo
    lead.aya_ativo = aya_ativo
    lead.consultor_id = uuid.uuid4()
    return lead


def _fake_memory() -> MagicMock:
    m = MagicMock()
    m._summary = ""
    m.load_memory_variables.return_value = {"chat_history": []}
    m.has_pending_summary.return_value = False
    m.compress_pending = AsyncMock()
    return m


@pytest.mark.asyncio
async def test_aya_enabled_full_flow():
    """When aya_ativo is True, full orchestration should execute and reply is sent."""
    db = AsyncMock()
    lead = _fake_lead(aya_ativo=True)
    interacao = MagicMock()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=100)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.multi_agent_orchestrator") as mock_orc,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Olá",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })

        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ai.preload_memory_from_db = AsyncMock()
        mock_ai.get_memory.return_value = _fake_memory()
        mock_ai.get_llm = MagicMock()

        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)

        mock_orc.orchestrate = AsyncMock(return_value="Olá cliente")

        await process_whatsapp_message.execute(_text_payload(), db)

    mock_orc.orchestrate.assert_awaited_once()
    mock_ws.send_message.assert_awaited_once()


@pytest.mark.asyncio
async def test_aya_disabled_lead_still_processes():
    """aya_ativo=False: no early-return implemented yet — flow executes normally.

    This test documents the current behaviour. A dedicated aya_ativo early-return
    gate should be added to execute() in a follow-up spec.
    """
    db = AsyncMock()
    lead = _fake_lead(aya_ativo=False)
    interacao = MagicMock()
    send_result = SendResult(success=True, wamid="wamid.ok", retries_used=0, latency_ms=100)

    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message.multi_agent_orchestrator") as mock_orc,
        patch("app.infrastructure.persistence.repositories.briefing_repository.BriefingRepository") as mock_br,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_qualified_notification", new=AsyncMock()),
    ):
        mock_ws.mark_as_read = AsyncMock()
        mock_ws.send_message = AsyncMock(return_value=send_result)
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Olá",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })

        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.save_interacao = AsyncMock(return_value=interacao)
        mock_ls.update_interacao_send_result = AsyncMock()

        mock_ai.preload_memory_from_db = AsyncMock()
        mock_ai.get_memory.return_value = _fake_memory()
        mock_ai.get_llm = MagicMock()

        mock_br.return_value.get_by_lead = AsyncMock(return_value=None)
        mock_br.return_value.get_by_lead_id = AsyncMock(return_value=None)

        mock_orc.orchestrate = AsyncMock(return_value="Resposta AYA")

        # Full flow should still run (no early-return gate implemented yet)
        await process_whatsapp_message.execute(_text_payload(), db)

    mock_orc.orchestrate.assert_awaited_once()
    mock_ws.send_message.assert_awaited_once()
