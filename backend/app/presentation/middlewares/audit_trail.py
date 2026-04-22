"""
Presentation Layer — Audit Trail Middleware
Logging estruturado em JSON interceptando o ciclo de vida de cada requisição.

Campos registrados por evento:
  - timestamp, request_id, method, path, status_code
  - user_id (JWT decodificado, ou "anonymous")
  - duration_ms, ip
  - operation (rota limpa para agregação em observability stacks)

Integra-se com structlog configurado para JSON output.
"""

import time
import uuid
from typing import Callable

import structlog
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

logger = structlog.get_logger()


def _extract_user_id(request: Request) -> str:
    """Extrai user_id do request.state (populado pelo middleware de Auth, se autenticado)."""
    return str(getattr(request.state, "user_id", "anonymous"))


def _clean_path(path: str) -> str:
    """Remove UUIDs e IDs numéricos do path para facilitar agrupamento em dashboards."""
    import re

    path = re.sub(r"/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", "/{id}", path)
    path = re.sub(r"/\d+", "/{id}", path)
    return path


class AuditTrailMiddleware(BaseHTTPMiddleware):
    """
    Intercepta cada request e loga um evento JSON estruturado ao final,
    contendo os campos necessários para rastreamento em stacks de observabilidade
    (ex: Datadog, Grafana Loki, AWS CloudWatch Logs Insights).
    """

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        request_id = str(uuid.uuid4())
        start_time = time.perf_counter()

        # Injeta request_id no state para uso downstream (ex: respostas de erro)
        request.state.request_id = request_id

        bound_logger = logger.bind(
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            operation=_clean_path(request.url.path),
            ip=request.client.host if request.client else "unknown",
        )

        bound_logger.info("request_started")

        try:
            response: Response = await call_next(request)
        except Exception as exc:
            duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
            bound_logger.exception(
                "request_error",
                user_id=_extract_user_id(request),
                duration_ms=duration_ms,
                error=str(exc),
            )
            raise

        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
        user_id = _extract_user_id(request)

        log_fn = bound_logger.warning if response.status_code >= 400 else bound_logger.info

        log_fn(
            "request_finished",
            user_id=user_id,
            status_code=response.status_code,
            duration_ms=duration_ms,
        )

        # Propaga o request_id na resposta para correlação no cliente
        response.headers["X-Request-ID"] = request_id
        return response
