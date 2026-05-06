"""
Tests — Security & Observability
Cobre:
  - Criptografia PII (EncryptedString): cifra e decifra corretamente
  - Security Headers: todas as respostas contêm os headers esperados
  - Rate Limiting: rota excede threshold e retorna 429
  - Audit Trail: middleware loga campos obrigatórios em JSON
"""

import json
import logging
from unittest.mock import patch

import pytest
from cryptography.fernet import Fernet
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.presentation.middlewares.audit_trail import AuditTrailMiddleware
from app.presentation.middlewares.security_headers import SecurityHeadersMiddleware


# ──────────────────────────────────────────────────────────────────────────────
# Fixtures
# ──────────────────────────────────────────────────────────────────────────────

TEST_ENCRYPTION_KEY = Fernet.generate_key().decode()


@pytest.fixture()
def test_key() -> str:
    return TEST_ENCRYPTION_KEY


@pytest.fixture()
def fernet(test_key):
    from cryptography.fernet import Fernet as F

    return F(test_key.encode())


# ──────────────────────────────────────────────────────────────────────────────
# 1. Criptografia PII
# ──────────────────────────────────────────────────────────────────────────────


class TestEncryptedString:
    """Testa o TypeDecorator EncryptedString sem banco de dados."""

    def test_roundtrip_cifra_e_decifra(self, test_key):
        """Valor persistido é devolvido intacto após encrypt/decrypt."""
        with patch("app.infrastructure.security.pii_encryption.settings") as mock_settings:
            mock_settings.ENCRYPTION_KEY = test_key
            from app.infrastructure.security.pii_encryption import EncryptedString

            enc_type = EncryptedString(512)
            plaintext = "+5584998765432"

            ciphertext = enc_type.process_bind_param(plaintext, dialect=None)
            assert ciphertext != plaintext, "Valor não deve ser armazenado em claro"
            assert len(ciphertext) > len(plaintext), "Ciphertext deve ser maior que o original"

            recovered = enc_type.process_result_value(ciphertext, dialect=None)
            assert recovered == plaintext

    def test_none_retorna_none(self, test_key):
        """Campos nulos não são processados."""
        with patch("app.infrastructure.security.pii_encryption.settings") as mock_settings:
            mock_settings.ENCRYPTION_KEY = test_key
            from app.infrastructure.security.pii_encryption import EncryptedString

            enc_type = EncryptedString(512)
            assert enc_type.process_bind_param(None, dialect=None) is None
            assert enc_type.process_result_value(None, dialect=None) is None

    def test_diferentes_valores_geram_ciphertexts_distintos(self, test_key):
        """Fernet é não-determinístico: mesma entrada → ciphertexts diferentes."""
        with patch("app.infrastructure.security.pii_encryption.settings") as mock_settings:
            mock_settings.ENCRYPTION_KEY = test_key
            from app.infrastructure.security.pii_encryption import EncryptedString

            enc_type = EncryptedString(512)
            c1 = enc_type.process_bind_param("João Silva", dialect=None)
            c2 = enc_type.process_bind_param("João Silva", dialect=None)
            assert c1 != c2, "Cada encrypt deve gerar token único (IV aleatório)"

    def test_sem_chave_levanta_runtime_error(self):
        """Sem ENCRYPTION_KEY configurada, deve falhar explicitamente."""
        with patch("app.infrastructure.security.pii_encryption.settings") as mock_settings:
            mock_settings.ENCRYPTION_KEY = ""
            from app.infrastructure.security.pii_encryption import EncryptedString

            enc_type = EncryptedString(512)
            with pytest.raises(RuntimeError, match="ENCRYPTION_KEY"):
                enc_type.process_bind_param("teste", dialect=None)


# ──────────────────────────────────────────────────────────────────────────────
# 2. Security Headers
# ──────────────────────────────────────────────────────────────────────────────


def _make_headers_app() -> TestClient:
    app = FastAPI()
    app.add_middleware(SecurityHeadersMiddleware)

    @app.get("/ping")
    async def ping():
        return {"pong": True}

    return TestClient(app)


class TestSecurityHeaders:
    def test_hsts_presente(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert "strict-transport-security" in response.headers
        assert "max-age=31536000" in response.headers["strict-transport-security"]

    def test_x_content_type_nosniff(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert response.headers.get("x-content-type-options") == "nosniff"

    def test_x_frame_deny(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert response.headers.get("x-frame-options") == "DENY"

    def test_csp_presente(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert "content-security-policy" in response.headers

    def test_referrer_policy_presente(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert "referrer-policy" in response.headers

    def test_permissions_policy_presente(self):
        client = _make_headers_app()
        response = client.get("/ping")
        assert "permissions-policy" in response.headers


# ──────────────────────────────────────────────────────────────────────────────
# 3. Rate Limiting
# ──────────────────────────────────────────────────────────────────────────────


def _make_rate_limit_app(limit: str = "3/minute") -> TestClient:
    """App de teste com limiter em memória (sem Redis)."""
    limiter = Limiter(key_func=get_remote_address, storage_uri="memory://", headers_enabled=True)
    app = FastAPI()
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    @app.post("/test-limited")
    @limiter.limit(limit)
    async def limited_route(request: Request):
        return JSONResponse({"ok": True})

    return TestClient(app, raise_server_exceptions=True)


class TestRateLimiting:
    def test_dentro_do_limite_retorna_200(self):
        client = _make_rate_limit_app("3/minute")
        for _ in range(3):
            response = client.post("/test-limited")
            assert response.status_code == 200

    def test_excede_limite_retorna_429(self):
        client = _make_rate_limit_app("3/minute")
        for _ in range(3):
            client.post("/test-limited")
        response = client.post("/test-limited")  # 4ª requisição
        assert response.status_code == 429

    def test_headers_rate_limit_presentes(self):
        """slowapi deve injetar X-RateLimit-* headers."""
        client = _make_rate_limit_app("10/minute")
        response = client.post("/test-limited")
        assert response.status_code == 200
        # headers podem variar por versão do slowapi, verificamos ao menos um
        has_rl_header = any(
            k.lower().startswith("x-ratelimit") for k in response.headers
        )
        assert has_rl_header, "Resposta deve conter headers X-RateLimit-*"


# ──────────────────────────────────────────────────────────────────────────────
# 4. Audit Trail — Middleware de Logging
# ──────────────────────────────────────────────────────────────────────────────


def _make_audit_app() -> tuple[FastAPI, TestClient]:
    app = FastAPI()
    app.add_middleware(AuditTrailMiddleware)

    @app.get("/audit-test")
    async def audit_route():
        return {"ok": True}

    return app, TestClient(app)


class TestAuditTrail:
    def test_x_request_id_presente_na_resposta(self):
        _, client = _make_audit_app()
        response = client.get("/audit-test")
        assert "x-request-id" in response.headers
        # Deve ser um UUID válido
        import uuid

        uuid.UUID(response.headers["x-request-id"])  # Levanta ValueError se inválido

    def test_request_ids_diferentes_por_request(self):
        _, client = _make_audit_app()
        ids = {client.get("/audit-test").headers["x-request-id"] for _ in range(5)}
        assert len(ids) == 5, "Cada request deve ter um request_id único"

    def test_log_emitido_com_campos_obrigatorios(self):
        """Verifica que o logger emite eventos com campos vitais."""
        from unittest.mock import ANY, patch, MagicMock

        _, client = _make_audit_app()
        
        with patch("app.presentation.middlewares.audit_trail.logger.bind") as mock_bind:
            mock_bound = MagicMock()
            mock_bind.return_value = mock_bound
            
            client.get("/audit-test")
            
            # Checks if 'request_finished' was logged via info
            mock_bound.info.assert_any_call(
                "request_finished",
                user_id=ANY,
                status_code=ANY,
                duration_ms=ANY,
            )
