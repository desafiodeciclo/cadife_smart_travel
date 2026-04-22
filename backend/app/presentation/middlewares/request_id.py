"""
Request ID Middleware — Presentation/Middlewares Layer
=======================================================
Injects a unique X-Request-ID header into every request and response.
Enables end-to-end request tracing across structured logs (structlog).

Usage in logs:
    structlog.contextvars.bind_contextvars(request_id=request_id)
    logger.info("event_name")  # automatically includes request_id
"""
import uuid

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = structlog.get_logger()


class RequestIdMiddleware(BaseHTTPMiddleware):
    """
    Assigns a unique UUID4 to each incoming request.
    - Reads `X-Request-ID` from client header if present (allows client-side correlation).
    - Generates a new UUID if not provided.
    - Injects the ID into structured logging context (structlog contextvars).
    - Adds `X-Request-ID` to the response headers.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        # Prefer client-supplied ID for distributed tracing; generate one if absent
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())

        # Bind to structlog context so all logs within this request carry the ID
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(
            request_id=request_id,
            method=request.method,
            path=request.url.path,
        )

        response = await call_next(request)

        # Expose the ID in the response for client-side correlation
        response.headers["X-Request-ID"] = request_id

        return response
