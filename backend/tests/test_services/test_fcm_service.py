"""
Tests — Services/FCMService
============================
Unit tests for Firebase Cloud Messaging helpers.

Coverage:
  - send_push_notification: success, firebase not initialized, send error
  - notify_new_lead: with and without destino
  - notify_travel_status_change: notifiable statuses, ignored statuses, with lead_nome
"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.domain.entities.enums import LeadStatus
from app.services import fcm_service


@pytest.fixture(autouse=True)
def reset_firebase_state():
    """Reset singleton state between tests."""
    original = fcm_service._firebase_initialized
    yield
    fcm_service._firebase_initialized = original


# ── send_push_notification ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_send_push_notification_success():
    fcm_service._firebase_initialized = True

    with patch("app.services.fcm_service.asyncio.to_thread", new=AsyncMock(return_value="msg_id")):
        with patch.dict("sys.modules", {"firebase_admin.messaging": MagicMock()}):
            import firebase_admin.messaging as mock_msg

            mock_msg.Message = MagicMock(return_value=MagicMock())
            mock_msg.Notification = MagicMock(return_value=MagicMock())

            result = await fcm_service.send_push_notification(
                fcm_token="token_abc",
                title="Test",
                body="Hello",
                data={"key": "val"},
            )

    assert result is True


@pytest.mark.asyncio
async def test_send_push_notification_firebase_not_initialized():
    fcm_service._firebase_initialized = False

    with patch.object(fcm_service, "_init_firebase", return_value=False):
        result = await fcm_service.send_push_notification(
            fcm_token="token_abc",
            title="Test",
            body="Hello",
        )

    assert result is False


@pytest.mark.asyncio
async def test_send_push_notification_send_error():
    fcm_service._firebase_initialized = True

    with patch(
        "app.services.fcm_service.asyncio.to_thread",
        new=AsyncMock(side_effect=Exception("FCM error")),
    ):
        with patch.dict("sys.modules", {"firebase_admin.messaging": MagicMock()}):
            import firebase_admin.messaging as mock_msg

            mock_msg.Message = MagicMock(return_value=MagicMock())
            mock_msg.Notification = MagicMock(return_value=MagicMock())

            result = await fcm_service.send_push_notification(
                fcm_token="token_abc",
                title="Test",
                body="Hello",
            )

    assert result is False


# ── notify_new_lead ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_notify_new_lead_with_destino():
    with patch.object(
        fcm_service, "send_push_notification", new=AsyncMock(return_value=True)
    ) as mock_send:
        result = await fcm_service.notify_new_lead(
            fcm_token="tok",
            lead_nome="Maria Silva",
            destino="Paris",
        )

    assert result is True
    call_kwargs = mock_send.call_args.kwargs
    assert "Paris" in call_kwargs["body"]
    assert "Maria Silva" in call_kwargs["body"]
    assert call_kwargs["data"]["type"] == "new_lead"


@pytest.mark.asyncio
async def test_notify_new_lead_without_destino():
    with patch.object(
        fcm_service, "send_push_notification", new=AsyncMock(return_value=True)
    ) as mock_send:
        result = await fcm_service.notify_new_lead(
            fcm_token="tok",
            lead_nome=None,
            destino=None,
        )

    assert result is True
    call_kwargs = mock_send.call_args.kwargs
    assert "Novo contato" in call_kwargs["body"]


# ── notify_travel_status_change ───────────────────────────────────────────────


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "status, expected_data_type",
    [
        (LeadStatus.qualificado, "travel_status_change"),
        (LeadStatus.agendado, "travel_status_change"),
        (LeadStatus.proposta, "travel_status_change"),
        (LeadStatus.fechado, "travel_status_change"),
    ],
)
async def test_notify_travel_status_change_notifiable(status, expected_data_type):
    with patch.object(
        fcm_service, "send_push_notification", new=AsyncMock(return_value=True)
    ) as mock_send:
        result = await fcm_service.notify_travel_status_change(
            fcm_token="tok",
            new_status=status,
        )

    assert result is True
    call_kwargs = mock_send.call_args.kwargs
    assert call_kwargs["data"]["type"] == expected_data_type
    assert call_kwargs["data"]["new_status"] == status.value


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "status",
    [LeadStatus.novo, LeadStatus.em_atendimento, LeadStatus.perdido],
)
async def test_notify_travel_status_change_ignored_statuses(status):
    with patch.object(
        fcm_service, "send_push_notification", new=AsyncMock(return_value=True)
    ) as mock_send:
        result = await fcm_service.notify_travel_status_change(
            fcm_token="tok",
            new_status=status,
        )

    assert result is False
    mock_send.assert_not_called()


@pytest.mark.asyncio
async def test_notify_travel_status_change_with_lead_nome():
    with patch.object(
        fcm_service, "send_push_notification", new=AsyncMock(return_value=True)
    ) as mock_send:
        await fcm_service.notify_travel_status_change(
            fcm_token="tok",
            new_status=LeadStatus.proposta,
            lead_nome="João",
        )

    call_kwargs = mock_send.call_args.kwargs
    assert "João" in call_kwargs["title"]
