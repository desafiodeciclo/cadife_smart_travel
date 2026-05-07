"""
Model Router — Services Layer
==============================
Routes WhatsApp messages to the appropriate OpenRouter model based on type:
  text  → OPENROUTER_MODEL         (chat / conversation)
  audio → OPENROUTER_AUDIO_MODEL   (Whisper — transcription)
  image → OPENROUTER_VISION_MODEL  (vision — image description / OCR)

Handles media download, preprocessing, and returns plain text to the AI layer
so the rest of the pipeline (briefing extraction, RAG, AYA response) stays
model-agnostic.

Spec references:
  §3.3  Stack — multimodal pipeline
  §12.3 Reliability — media fallback tratado com mensagem amigável
"""

from __future__ import annotations

import base64
from typing import Optional

import httpx
import structlog

from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()

_AUDIO_TYPES = frozenset({"audio", "voice"})
_VISION_TYPES = frozenset({"image"})

_IMAGE_ANALYSIS_PROMPT = (
    "Descreva detalhadamente o conteúdo desta imagem para um sistema de atendimento de uma "
    "agência de viagens. Se for um documento (passaporte, passagem aérea, voucher, itinerário, "
    "bilhete), extraia as informações relevantes de forma estruturada. Se for outra coisa, "
    "descreva o que você vê de forma objetiva."
)

_EXT_MAP: dict[str, str] = {
    "audio/ogg": "ogg",
    "audio/mpeg": "mp3",
    "audio/mp4": "mp4",
    "audio/wav": "wav",
    "audio/webm": "webm",
    "audio/aac": "aac",
    "audio/amr": "amr",
}

_OPENROUTER_BASE = "https://openrouter.ai/api/v1"
_OPENROUTER_HEADERS = {
    "HTTP-Referer": "https://cadifetour.com",
    "X-Title": "Cadife Smart Travel",
}


def select_model(msg_type: str) -> str:
    """Return the OpenRouter model ID for a given WhatsApp message type."""
    if msg_type in _AUDIO_TYPES:
        return settings.OPENROUTER_AUDIO_MODEL
    if msg_type in _VISION_TYPES:
        return settings.OPENROUTER_VISION_MODEL
    return settings.OPENROUTER_MODEL


async def _transcribe_audio_whisper(audio_bytes: bytes, mime_type: str) -> Optional[str]:
    """
    Tenta transcrição via endpoint /audio/transcriptions do OpenRouter (Whisper).

    Usa openai/whisper-large-v3 enviando o arquivo como multipart/form-data,
    igual à API da OpenAI. Retorna None se o endpoint não estiver disponível
    para o provider configurado — o caller deve usar fallback multimodal.
    """
    normalized = mime_type.split(";")[0].strip().lower()
    ext = _EXT_MAP.get(normalized, "ogg")

    try:
        auth_headers = {
            "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
            **_OPENROUTER_HEADERS,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{_OPENROUTER_BASE}/audio/transcriptions",
                headers=auth_headers,
                files={"file": (f"audio.{ext}", audio_bytes, normalized)},
                data={"model": settings.OPENROUTER_WHISPER_MODEL},
            )
            response.raise_for_status()

        text = response.json().get("text", "").strip()
        logger.info(
            "audio_transcribed_whisper",
            model=settings.OPENROUTER_WHISPER_MODEL,
            chars=len(text),
        )
        return text or None

    except httpx.HTTPStatusError as exc:
        logger.warning(
            "whisper_transcript_error",
            status=exc.response.status_code,
            body=exc.response.text[:400],
            model=settings.OPENROUTER_WHISPER_MODEL,
            fallback_to="gemini_multimodal",
        )
        return None
    except Exception as exc:
        logger.warning(
            "whisper_transcript_error",
            error=str(exc),
            error_type=type(exc).__name__,
            model=settings.OPENROUTER_WHISPER_MODEL,
            fallback_to="gemini_multimodal",
        )
        return None


async def transcribe_audio(audio_bytes: bytes, mime_type: str) -> str:
    """Transcreve áudio via OpenRouter.

    Estratégia com fallback automático:
      1. openai/whisper-large-v3 via /audio/transcriptions (mais preciso)
      2. Gemini multimodal via /chat/completions (fallback universal)

    Raises:
        httpx.HTTPStatusError: somente se o fallback multimodal também falhar.
    """
    # Tentativa 1 — Whisper via /audio/transcriptions
    whisper_result = await _transcribe_audio_whisper(audio_bytes, mime_type)
    if whisper_result:
        return whisper_result

    # Tentativa 2 — Gemini multimodal via /chat/completions (lógica original)
    logger.info("transcribe_audio_using_multimodal_fallback", mime_type=mime_type)
    normalized_mime = mime_type.split(";")[0].strip().lower()
    audio_b64 = base64.b64encode(audio_bytes).decode()
    audio_fmt = _EXT_MAP.get(normalized_mime, "ogg")

    payload = {
        "model": settings.OPENROUTER_AUDIO_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_audio",
                        "input_audio": {"data": audio_b64, "format": audio_fmt},
                    },
                    {
                        "type": "text",
                        "text": (
                            "Transcreva exatamente o que foi dito neste áudio em português. "
                            "Responda APENAS com a transcrição literal, sem comentários."
                        ),
                    },
                ],
            }
        ],
        "max_tokens": 1000,
    }

    auth_headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        **_OPENROUTER_HEADERS,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{_OPENROUTER_BASE}/chat/completions",
                json=payload,
                headers=auth_headers,
            )
            response.raise_for_status()
            data = response.json()
            text: str = data["choices"][0]["message"]["content"] or ""
    except httpx.HTTPStatusError as exc:
        logger.error(
            "audio_multimodal_fallback_error",
            model=settings.OPENROUTER_AUDIO_MODEL,
            status=exc.response.status_code,
            body=exc.response.text[:400],
            hint="input_audio format may not be supported by this model via OpenRouter",
        )
        raise
    except (KeyError, IndexError) as exc:
        logger.error(
            "audio_multimodal_response_parse_error",
            model=settings.OPENROUTER_AUDIO_MODEL,
            error=str(exc),
            hint="Unexpected response structure — model may have returned empty choices",
        )
        raise RuntimeError(f"Unexpected audio response structure: {exc}") from exc

    logger.info(
        "audio_transcribed",
        model=settings.OPENROUTER_AUDIO_MODEL,
        chars=len(text),
    )
    return text


async def analyze_image(
    image_bytes: bytes,
    mime_type: str,
    caption: Optional[str] = None,
) -> str:
    """Describe or extract data from an image via a vision model on OpenRouter.

    Returns a plain-text description / OCR extraction.

    Raises:
        httpx.HTTPStatusError: on API error.
    """
    image_b64 = base64.b64encode(image_bytes).decode()
    data_url = f"data:{mime_type};base64,{image_b64}"

    prompt = _IMAGE_ANALYSIS_PROMPT
    if caption:
        prompt += f"\n\nLegenda enviada pelo cliente: {caption}"

    payload = {
        "model": settings.OPENROUTER_VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "image_url", "image_url": {"url": data_url}},
                    {"type": "text", "text": prompt},
                ],
            }
        ],
        "max_tokens": 600,
    }

    auth_headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        **_OPENROUTER_HEADERS,
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{_OPENROUTER_BASE}/chat/completions",
            json=payload,
            headers=auth_headers,
        )
        response.raise_for_status()
        description: str = response.json()["choices"][0]["message"]["content"] or ""

    logger.info(
        "image_analyzed",
        model=settings.OPENROUTER_VISION_MODEL,
        chars=len(description),
    )
    return description


async def route_media_message(
    msg_type: str,
    media_id: str,
    mime_type: str,
    caption: Optional[str] = None,
) -> Optional[str]:
    """Download and process a WhatsApp media message.

    Orchestrates: download → transcribe/analyze → return plain text.
    Returns None (caller should use graceful fallback) on any failure.
    """
    from app.services.whatsapp_service import download_media

    try:
        media_bytes = await download_media(media_id)
        if not media_bytes:
            logger.warning("media_download_empty", msg_type=msg_type, media_id=media_id)
            return None

        if msg_type in _AUDIO_TYPES:
            return await transcribe_audio(media_bytes, mime_type)

        if msg_type in _VISION_TYPES:
            return await analyze_image(media_bytes, mime_type, caption)

        logger.debug("media_type_not_routable", msg_type=msg_type)
        return None

    except httpx.HTTPStatusError as exc:
        logger.error(
            "media_api_error",
            msg_type=msg_type,
            status_code=exc.response.status_code,
            error=str(exc),
        )
        return None

    except httpx.TimeoutException:
        logger.error("media_download_timeout", msg_type=msg_type, media_id=media_id)
        return None

    except Exception as exc:
        logger.error("media_routing_failed", msg_type=msg_type, error=str(exc))
        return None
