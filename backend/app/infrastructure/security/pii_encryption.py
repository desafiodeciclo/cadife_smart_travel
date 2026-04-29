"""
Infrastructure Layer — PII Encryption
TypeDecorator transparente do SQLAlchemy para criptografia at-rest
de campos com dados pessoais identificáveis (PII) usando Fernet (AES-128).

Uso:
    class Lead(Base):
        telefone      = mapped_column(EncryptedString(512))
        telefone_hash = mapped_column(String(64), index=True)

    # Para buscar:
    lead = db.execute(select(Lead).where(Lead.telefone_hash == hmac_hash(phone)))
"""

import hashlib
import hmac
import structlog
from sqlalchemy import String
from sqlalchemy.types import TypeDecorator

from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()


def hmac_hash(value: str) -> str:
    """HMAC-SHA256 determinístico para campos PII buscáveis (ex: telefone_hash).

    Fernet é não-determinístico (IV aleatório), portanto não pode ser usado
    em cláusulas WHERE. Este hash é estável para o mesmo valor + HASH_KEY,
    permitindo lookup no DB sem expor o dado em texto plano.
    """
    key = settings.HASH_KEY
    if not key:
        raise RuntimeError(
            "HASH_KEY não configurada. "
            "Gere com: python -c \"import secrets; print(secrets.token_hex(32))\""
        )
    return hmac.new(key.encode(), value.encode(), hashlib.sha256).hexdigest()


def _get_fernet():
    """Cria instância Fernet com a chave de ambiente.

    Importação lazy para evitar falha no startup quando ENCRYPTION_KEY
    ainda não está configurada (ex: durante testes unitários isolados).
    """
    from cryptography.fernet import Fernet, InvalidToken  # noqa: F401

    key = settings.ENCRYPTION_KEY
    if not key:
        raise RuntimeError(
            "ENCRYPTION_KEY não configurada. "
            "Gere com: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
        )
    return Fernet(key.encode() if isinstance(key, str) else key)


class EncryptedString(TypeDecorator):
    """
    Tipo SQLAlchemy que criptografa automaticamente o valor antes de
    persistir no banco e descriptografa na leitura.

    Armazena o cyphertext como VARCHAR no PostgreSQL — nenhuma alteração
    de schema é necessária além de aumentar o comprimento da coluna
    (dados encriptados têm overhead ~40 bytes + base64 ≈ 1.4x o tamanho).
    """

    impl = String
    cache_ok = True

    def process_bind_param(self, value: str | None, dialect) -> str | None:
        """Criptografa antes de escrever no DB."""
        if value is None:
            return value
        try:
            fernet = _get_fernet()
            return fernet.encrypt(value.encode("utf-8")).decode("utf-8")
        except Exception:
            logger.exception("pii_encryption_error", field="bind")
            raise

    def process_result_value(self, value: str | None, dialect) -> str | None:
        """Descriptografa ao ler do DB."""
        if value is None:
            return value
        try:
            fernet = _get_fernet()
            return fernet.decrypt(value.encode("utf-8")).decode("utf-8")
        except Exception:
            logger.exception("pii_decryption_error", field="result")
            raise
