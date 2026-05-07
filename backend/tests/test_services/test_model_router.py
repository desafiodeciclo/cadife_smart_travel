"""
Tests — model_router service
Tests isolate network calls with unittest.mock so no real API keys are needed.
"""
from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services import model_router


# ── select_model ──────────────────────────────────────────────────────────────

def test_select_model_text_returns_chat_model():
    model = model_router.select_model("text")
    # Must match the configured chat model (not audio/vision)
    assert model == model_router.settings.OPENROUTER_MODEL


def test_select_model_audio_returns_audio_model():
    assert model_router.select_model("audio") == model_router.settings.OPENROUTER_AUDIO_MODEL


def test_select_model_voice_returns_audio_model():
    assert model_router.select_model("voice") == model_router.settings.OPENROUTER_AUDIO_MODEL


def test_select_model_image_returns_vision_model():
    assert model_router.select_model("image") == model_router.settings.OPENROUTER_VISION_MODEL


def test_select_model_unknown_falls_back_to_chat():
    assert model_router.select_model("sticker") == model_router.settings.OPENROUTER_MODEL


# ── transcribe_audio ──────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_transcribe_audio_returns_text():
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"choices": [{"message": {"content": "Quero viajar para Portugal"}}]}

    with patch("app.services.model_router.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        result = await model_router.transcribe_audio(b"fake_audio", "audio/ogg")

    assert result == "Quero viajar para Portugal"


@pytest.mark.asyncio
async def test_transcribe_audio_uses_correct_language():
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"choices": [{"message": {"content": "oi"}}]}

    with patch("app.services.model_router.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        await model_router.transcribe_audio(b"fake_audio", "audio/mpeg")

        payload = mock_client.post.call_args.kwargs["json"]
        text_part = next(p for p in payload["messages"][0]["content"] if p["type"] == "text")
        assert "português" in text_part["text"]


@pytest.mark.asyncio
async def test_transcribe_audio_maps_mime_to_extension():
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"choices": [{"message": {"content": "hello"}}]}

    with patch("app.services.model_router.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        await model_router.transcribe_audio(b"data", "audio/mpeg")

        payload = mock_client.post.call_args.kwargs["json"]
        audio_part = next(p for p in payload["messages"][0]["content"] if p["type"] == "input_audio")
        assert audio_part["input_audio"]["format"] == "mp3"


# ── analyze_image ─────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_analyze_image_returns_description():
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {
        "choices": [{"message": {"content": "Passaporte brasileiro em nome de João"}}]
    }

    with patch("app.services.model_router.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        result = await model_router.analyze_image(b"fake_image", "image/jpeg")

    assert "Passaporte" in result


@pytest.mark.asyncio
async def test_analyze_image_includes_caption_in_prompt():
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"choices": [{"message": {"content": "descrição"}}]}

    with patch("app.services.model_router.httpx.AsyncClient") as mock_client_cls:
        mock_client = AsyncMock()
        mock_client.__aenter__ = AsyncMock(return_value=mock_client)
        mock_client.__aexit__ = AsyncMock(return_value=None)
        mock_client.post = AsyncMock(return_value=mock_response)
        mock_client_cls.return_value = mock_client

        await model_router.analyze_image(b"img", "image/jpeg", caption="meu passaporte")

        payload = mock_client.post.call_args.kwargs["json"]
        user_content = payload["messages"][0]["content"]
        text_part = next(p for p in user_content if p["type"] == "text")
        assert "meu passaporte" in text_part["text"]


# ── route_media_message ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_route_media_audio_calls_transcribe():
    with (
        patch("app.services.whatsapp_service.download_whatsapp_media", new_callable=AsyncMock) as mock_dl,
        patch("app.services.model_router.transcribe_audio", new_callable=AsyncMock) as mock_tr,
    ):
        mock_dl.return_value = (b"audio_bytes", "audio/ogg")
        mock_tr.return_value = "Quero ir para Lisboa"

        result = await model_router.route_media_message(
            msg_type="audio",
            media_id="media123",
            mime_type="audio/ogg",
        )

    assert result == "Quero ir para Lisboa"
    mock_tr.assert_awaited_once()


@pytest.mark.asyncio
async def test_route_media_image_calls_analyze():
    with (
        patch("app.services.whatsapp_service.download_whatsapp_media", new_callable=AsyncMock) as mock_dl,
        patch("app.services.model_router.analyze_image", new_callable=AsyncMock) as mock_an,
    ):
        mock_dl.return_value = (b"img_bytes", "image/jpeg")
        mock_an.return_value = "Passaporte brasileiro"

        result = await model_router.route_media_message(
            msg_type="image",
            media_id="media456",
            mime_type="image/jpeg",
            caption="meu doc",
        )

    assert result == "Passaporte brasileiro"
    mock_an.assert_awaited_once_with(b"img_bytes", "image/jpeg", "meu doc")


@pytest.mark.asyncio
async def test_route_media_returns_none_on_download_error():
    import httpx

    with patch(
        "app.services.whatsapp_service.download_whatsapp_media",
        new_callable=AsyncMock,
        side_effect=httpx.TimeoutException("timeout"),
    ):
        result = await model_router.route_media_message(
            msg_type="audio",
            media_id="bad_id",
            mime_type="audio/ogg",
        )

    assert result is None


@pytest.mark.asyncio
async def test_route_media_unsupported_type_returns_none():
    with patch(
        "app.services.whatsapp_service.download_whatsapp_media",
        new_callable=AsyncMock,
        return_value=(b"data", "video/mp4"),
    ):
        result = await model_router.route_media_message(
            msg_type="video",
            media_id="vid123",
            mime_type="video/mp4",
        )

    assert result is None
