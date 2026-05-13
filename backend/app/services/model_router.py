"""
Model Router — Services Layer
==============================
Routes WhatsApp messages to the appropriate OpenRouter model based on type:
  text  → OPENROUTER_MODEL               (chat / conversation)
  audio → OPENROUTER_AUDIO_MODEL        (gpt-4o-audio-preview — input_audio via /chat/completions)
  image → OPENROUTER_VISION_MODEL       (vision — image description / OCR)

Audio pipeline:
  1. Converte OGG/Opus (formato WhatsApp) → WAV usando pydub + ffmpeg
  2. Envia ao gpt-4o-audio-preview via input_audio no /chat/completions
  Motivo: o endpoint /audio/transcriptions do OpenRouter tem bug de parsing (400 JSON)
  e Gemini não processa audio_url via OpenRouter.

Spec references:
  §3.3  Stack — multimodal pipeline
  §12.3 Reliability — media fallback tratado com mensagem amigável
"""

from __future__ import annotations

import base64
import subprocess
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

# GPT-4o-audio-preview aceita somente estes formatos em input_audio
_GPT4O_NATIVE_FORMATS = frozenset({"wav", "mp3"})

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


def _convert_to_wav(audio_bytes: bytes, src_format: str) -> bytes:
    """Converte áudio para WAV via ffmpeg (pipe stdin→stdout, sem arquivo em disco)."""
    cmd = [
        "ffmpeg",
        "-f", src_format,   # formato de entrada explícito
        "-i", "pipe:0",     # lê do stdin
        "-ar", "16000",     # 16 kHz
        "-ac", "1",         # mono
        "-f", "wav",
        "pipe:1",           # escreve no stdout
        "-loglevel", "error",
    ]
    try:
        result = subprocess.run(
            cmd,
            input=audio_bytes,
            capture_output=True,
            timeout=30,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(
            "ffmpeg não encontrado. Instale com: brew install ffmpeg (macOS) "
            "ou verifique o Dockerfile (apt-get install ffmpeg)."
        ) from exc

    if result.returncode != 0 or not result.stdout:
        raise RuntimeError(
            f"ffmpeg falhou ao converter {src_format}→wav: "
            f"{result.stderr.decode(errors='replace')[:300]}"
        )

    logger.info(
        "audio_converted_to_wav",
        src_format=src_format,
        src_bytes=len(audio_bytes),
        wav_bytes=len(result.stdout),
    )
    return result.stdout


async def _transcribe_with_gpt4o_audio(audio_b64: str, audio_fmt: str) -> str:
    """Transcrição primária via gpt-4o-audio-preview (input_audio no /chat/completions)."""
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
                            "Responda APENAS com a transcrição literal, sem comentários adicionais."
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
    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{_OPENROUTER_BASE}/chat/completions",
            json=payload,
            headers=auth_headers,
        )
        response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"] or ""


async def _transcribe_with_whisper(audio_wav: bytes, audio_fmt: str) -> str:
    """Fallback de transcrição via Whisper no OpenRouter (/audio/transcriptions)."""
    import io

    auth_headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        **_OPENROUTER_HEADERS,
    }
    files = {"file": (f"audio.{audio_fmt}", io.BytesIO(audio_wav), f"audio/{audio_fmt}")}
    data = {"model": settings.OPENROUTER_WHISPER_MODEL}

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{_OPENROUTER_BASE}/audio/transcriptions",
            headers=auth_headers,
            files=files,
            data=data,
        )
        response.raise_for_status()
        return response.json().get("text", "")


async def transcribe_audio(audio_bytes: bytes, mime_type: str) -> str:
    """Transcreve áudio via gpt-4o-audio-preview com fallback para Whisper."""
    normalized_mime = mime_type.split(";")[0].strip().lower()
    src_fmt = _EXT_MAP.get(normalized_mime, "ogg")

    if src_fmt in _GPT4O_NATIVE_FORMATS:
        audio_wav = audio_bytes
        audio_fmt = src_fmt
    else:
        logger.info(
            "audio_format_conversion_needed",
            src_format=src_fmt,
            mime_type=normalized_mime,
        )
        audio_wav = _convert_to_wav(audio_bytes, src_fmt)
        audio_fmt = "wav"

    audio_b64 = base64.b64encode(audio_wav).decode()

    try:
        return await _transcribe_with_gpt4o_audio(audio_b64, audio_fmt)
    except Exception as primary_exc:
        logger.warning(
            "audio_primary_model_failed_falling_back_to_whisper",
            primary_model=settings.OPENROUTER_AUDIO_MODEL,
            error=str(primary_exc),
        )
        return await _transcribe_with_whisper(audio_wav, audio_fmt)


async def analyze_image(
    image_bytes: bytes,
    mime_type: str,
    caption: Optional[str] = None,
) -> str:
    """Describe or extract data from an image via a vision model on OpenRouter."""
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
        return response.json()["choices"][0]["message"]["content"] or ""


async def route_media_message(
    msg_type: str,
    media_id: str,
    mime_type: str,
    caption: Optional[str] = None,
) -> Optional[str]:
    """Download and process a WhatsApp media message."""
    from app.services.whatsapp_service import download_media

    try:
        media_bytes = await download_media(media_id)
        
        # RESOLUÇÃO DO CONFLITO: Usando a lógica mais robusta da developer
        if not media_bytes:
            logger.warning("media_download_empty", msg_type=msg_type, media_id=media_id)
            return None

        if msg_type in _AUDIO_TYPES:
            return await transcribe_audio(media_bytes, mime_type)

        if msg_type in _VISION_TYPES:
            return await analyze_image(media_bytes, mime_type, caption)

        logger.debug("media_type_not_routable", msg_type=msg_type)
        return None

    except Exception as exc:
        logger.error("media_routing_failed", msg_type=msg_type, error=str(exc))
        return None