"""
Notification Debounce Service — Infrastructure Layer
======================================================
Controle de frequência de notificações push por lead_id usando Redis.
Evita spam de push quando a IA extrai blocos picados num prazo curto.

Regra de negócio (spec.md):
  - Debounce de 60 segundos por lead_id
  - Se uma notificação para o mesmo lead for solicitada dentro do TTL,
    ela é silenciosamente descartada.
"""

from __future__ import annotations

import structlog
from redis.asyncio import Redis

from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()

_DEBOUNCE_KEY_PREFIX = "cadife:notification:debounce"


class NotificationDebounceService:
    """Redis-backed debounce for FCM push notifications per lead."""

    def __init__(self, redis: Redis | None = None) -> None:
        self._redis = redis
        self._ttl = settings.NOTIFICATION_DEBOUNCE_TTL_SECONDS

    async def _get_redis(self) -> Redis:
        if self._redis is None:
            self._redis = Redis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
            )
        return self._redis

    async def try_acquire(self, lead_id: str) -> bool:
        """
        Atomicamente verifica e registra o debounce usando SET NX EX.
        Retorna True se a notificação pode ser enviada (lock adquirido),
        False se já existe debounce ativo (notificação deve ser suprimida).

        Substitui o par is_allowed()+touch() que sofria de TOCTOU em multi-instância.
        """
        redis = await self._get_redis()
        key = f"{_DEBOUNCE_KEY_PREFIX}:{lead_id}"
        # SET NX EX: atômico — só seta se a chave não existir
        was_set = await redis.set(key, "1", nx=True, ex=self._ttl)
        if was_set:
            logger.debug("notification_debounce_acquired", lead_id=lead_id, ttl=self._ttl)
            return True
        logger.debug("notification_debounce_active", lead_id=lead_id, ttl=self._ttl)
        return False

    async def is_allowed(self, lead_id: str) -> bool:
        """Verifica se não há debounce ativo. Prefira try_acquire() para evitar TOCTOU."""
        redis = await self._get_redis()
        key = f"{_DEBOUNCE_KEY_PREFIX}:{lead_id}"
        exists = await redis.exists(key)
        if exists:
            logger.debug("notification_debounce_active", lead_id=lead_id, ttl=self._ttl)
            return False
        return True

    async def touch(self, lead_id: str) -> None:
        """
        Registra debounce para o lead_id com TTL configurado.
        Prefira try_acquire() para operação atômica sem TOCTOU.
        """
        redis = await self._get_redis()
        key = f"{_DEBOUNCE_KEY_PREFIX}:{lead_id}"
        await redis.setex(key, self._ttl, "1")
        logger.debug("notification_debounce_set", lead_id=lead_id, ttl=self._ttl)

    async def clear(self, lead_id: str) -> None:
        """Limpa debounce manualmente (útil em testes ou reprocessamento)."""
        redis = await self._get_redis()
        key = f"{_DEBOUNCE_KEY_PREFIX}:{lead_id}"
        await redis.delete(key)
        logger.debug("notification_debounce_cleared", lead_id=lead_id)
