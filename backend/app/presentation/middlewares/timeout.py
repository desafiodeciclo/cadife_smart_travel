"""
Timeout Middleware — Presentation/Middlewares Layer
====================================================
Enforces a configurable request timeout to prevent staling connections
from exhausting the server's worker pool.

Key constraints from spec.md:
  - §12.3: Webhook must respond in < 5 seconds (Meta requirement)
  - §8.1:  IA response to WhatsApp client: max 3 seconds
  - §8.1:  FCM notification to consultant: max 2 seconds

The webhook route uses BackgroundTasks to respond immediately (200 OK)
while processing the message async — this middleware protects the
synchronous processing boundary.
"""
import asyncio

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()
settings = get_settings()


class TimeoutMiddleware(BaseHTTPMiddleware):
    """
    Cancels requests that exceed the configured timeout.

    - Webhook endpoints use WEBHOOK_TIMEOUT_SECONDS (< 5s per Meta policy).
    - All other endpoints use REQUEST_TIMEOUT_SECONDS (default: 30s).
    - Returns HTTP 504 Gateway Timeout on expiry, preserving X-Request-ID header.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # Determine timeout based on route
        is_webhook = request.url.path.startswith("/webhook")
        timeout = (
            settings.WEBHOOK_TIMEOUT_SECONDS if is_webhook
            else settings.REQUEST_TIMEOUT_SECONDS
        )

        try:
            response = await asyncio.wait_for(call_next(request), timeout=timeout)
            return response

        except asyncio.TimeoutError:
            request_id = request.headers.get("X-Request-ID", "unknown")
            logger.warning(
                "request_timeout",
                path=request.url.path,
                method=request.method,
                timeout_seconds=timeout,
                request_id=request_id,
            )
            return JSONResponse(
                status_code=504,
                content={
                    "detail": "Request timeout — o servidor demorou muito para processar a requisição.",
                    "request_id": request_id,
                },
                headers={"X-Request-ID": request_id},
            )
