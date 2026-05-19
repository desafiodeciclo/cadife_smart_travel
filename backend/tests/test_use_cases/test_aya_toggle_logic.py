
import uuid
from unittest.mock import AsyncMock, MagicMock, patch
import pytest
from app.application.use_cases import process_whatsapp_message
from app.domain.entities.enums import LeadStatus, TipoMensagem

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

@pytest.mark.asyncio
async def test_aya_disabled_early_return():
    """When aya_ativo is False, message should be persisted but AI should not be called."""
    db = AsyncMock()
    lead = _fake_lead(aya_ativo=False)
    
    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_aya_disabled_notification") as mock_notify,
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.save_interacao = AsyncMock()
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Olá",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        
        await process_whatsapp_message.execute(_text_payload(), db)
        
    # Verify persistence
    mock_ls.save_interacao.assert_awaited_once()
    # Verify notification
    mock_notify.assert_awaited_once_with(db, lead)
    # Verify early return (AI services NOT called)
    mock_ai.process_message.assert_not_called()
    mock_ws.send_message.assert_not_called()

@pytest.mark.asyncio
async def test_aya_enabled_full_flow():
    """When aya_ativo is True, full flow should execute."""
    db = AsyncMock()
    lead = _fake_lead(aya_ativo=True)
    
    with (
        patch("app.application.use_cases.process_whatsapp_message.lead_service") as mock_ls,
        patch("app.application.use_cases.process_whatsapp_message.ai_service") as mock_ai,
        patch("app.application.use_cases.process_whatsapp_message.whatsapp_service") as mock_ws,
        patch("app.application.use_cases.process_whatsapp_message._enqueue_message_received_notification") as mock_notify,
    ):
        mock_ls.upsert_lead_with_resilience = AsyncMock(return_value=lead)
        mock_ls.update_lead_status = AsyncMock(return_value=lead)
        mock_ls.get_recent_interacoes = AsyncMock(return_value=[])
        mock_ls.update_briefing_from_extraction = AsyncMock(return_value=MagicMock(completude_pct=10))
        mock_ls.save_interacao = AsyncMock()
        mock_ls.update_interacao_send_result = AsyncMock()
        
        mock_ai.process_message = AsyncMock(return_value="Olá cliente")
        mock_ai.extract_briefing = AsyncMock()
        
        mock_ws.extract_message_from_payload = MagicMock(return_value={
            "phone": "5584999990001",
            "text": "Olá",
            "type": "text",
            "name": "Maria",
            "message_id": "wamid.test",
        })
        mock_ws.send_message = AsyncMock(return_value=MagicMock(success=True))
        
        await process_whatsapp_message.execute(_text_payload(), db)
        
    # Verify AI was called
    mock_ai.process_message.assert_awaited_once()
    mock_ws.send_message.assert_awaited_once()
