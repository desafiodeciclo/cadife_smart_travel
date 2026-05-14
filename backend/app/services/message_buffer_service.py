"""
Message Buffer Service — Debounce de mensagens fragmentadas por phone.

Problema resolvido: quando o cliente digita em múltiplas mensagens curtas
("Quero ir", "para Portugal", "em julho") cada webhook dispara um LLM completo.
Este serviço acumula mensagens do mesmo phone por DEBOUNCE_S segundos e entrega
o texto sintetizado em uma única chamada ao callback.

Integração (webhook handler):
    Em vez de agendar BackgroundTask direto, chame:
        await message_buffer_service.buffer_and_fire(
            phone=phone,
            text=text,
            callback=_process_buffered,
        )
    onde `_process_buffered(phone, synthesized_text)` abre a própria sessão DB.
"""

from __future__ import annotations

import asyncio
from typing import Awaitable, Callable

import structlog

logger = structlog.get_logger()

_DEBOUNCE_S: float = 4.0

# Estado global por worker — substituir por Redis para multi-worker
_pending_texts: dict[str, list[str]] = {}
_pending_tasks: dict[str, asyncio.Task] = {}  # type: ignore[type-arg]


async def buffer_and_fire(
    phone: str,
    text: str,
    callback: Callable[[str, str], Awaitable[None]],
) -> None:
    """Acumula `text` para `phone` e dispara `callback(phone, text_sintetizado)`
    após DEBOUNCE_S segundos de silêncio.

    Cada nova mensagem reinicia o timer. Se apenas uma mensagem chegar dentro
    do intervalo, ela é entregue diretamente sem síntese extra.
    """
    if phone not in _pending_texts:
        _pending_texts[phone] = []
    _pending_texts[phone].append(text)

    existing = _pending_tasks.get(phone)
    if existing and not existing.done():
        existing.cancel()

    async def _flush() -> None:
        try:
            await asyncio.sleep(_DEBOUNCE_S)
        except asyncio.CancelledError:
            return

        texts = _pending_texts.pop(phone, [])
        _pending_tasks.pop(phone, None)

        if not texts:
            return

        synthesized = " ".join(texts)
        if len(texts) > 1:
            logger.info(
                "message_buffer_flushed",
                phone=phone,
                fragments=len(texts),
                synthesized_preview=synthesized[:80],
            )

        await callback(phone, synthesized)

    _pending_tasks[phone] = asyncio.create_task(_flush())
