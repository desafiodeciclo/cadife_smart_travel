"""
Presentation Layer — Security Headers Middleware
Injeta HTTP Security Headers em todas as respostas da API:
  - HSTS (Strict-Transport-Security)
  - Content-Security-Policy
  - X-Content-Type-Options
  - X-Frame-Options
  - Referrer-Policy
  - Permissions-Policy
"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Middleware que adiciona headers de segurança obrigatórios em toda resposta."""

    async def dispatch(self, request: Request, call_next) -> Response:
        response: Response = await call_next(request)

        # Força HTTPS por 1 ano e inclui subdomínios
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains; preload"
        )
        # Bloqueia sniffing de MIME type pelo browser
        response.headers["X-Content-Type-Options"] = "nosniff"
        # Impede que a página seja carregada em iframe (clickjacking)
        response.headers["X-Frame-Options"] = "DENY"
        # Política de referrer conservadora
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        # Desabilita features sensíveis de browser não utilizadas pela API
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=(), payment=()"
        )
        # CSP restritivo: API JSON-only, sem recursos de browser
        response.headers["Content-Security-Policy"] = (
            "default-src 'none'; frame-ancestors 'none'"
        )
        # Remove o header que expõe o servidor
        if "server" in response.headers:
            del response.headers["server"]

        return response
