"""
Settings Module — Infrastructure/Config Layer
=============================================
Validates all environment variables using pydantic-settings.
Based on spec.md Section 15 (Variáveis de Ambiente).

In production, secrets can be loaded from:
  - AWS Secrets Manager (via `boto3`)
  - HashiCorp Vault (via `hvac`)
by overriding `_load_external_secrets()`.
"""
from functools import lru_cache
from typing import Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Strict settings validation.
    Required vars will raise ValidationError at startup if missing,
    preventing silent misconfigurations in production.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # ── Application Behaviour ─────────────────────────────────────────────
    APP_ENV: Literal["development", "staging", "production"] = Field(
        default="development",
        description="Current environment — controls secret loading strategy",
    )
    DEBUG: bool = Field(default=False)

    # ── WhatsApp Cloud API (spec.md §15) ──────────────────────────────────
    WHATSAPP_TOKEN: str = Field(default="", description="Meta WhatsApp access token")
    PHONE_NUMBER_ID: str = Field(default="", description="Meta registered phone number ID")
    VERIFY_TOKEN: str = Field(
        default="cadife_verify_token",
        description="Secret token for Meta webhook verification",
    )
    META_APP_SECRET: str = Field(default="", description="Meta App Secret for X-Hub-Signature-256 validation")
    META_APP_ID: str = Field(default="", description="Meta App ID — required for token exchange")

    # ── OpenAI / LangChain (spec.md) ─────────────────────────
    OPENAI_API_KEY: str = Field(default="", description="OpenAI API key para LLM + embeddings")
    GEMINI_API_KEY: str = Field(default="", description="Google Gemini API key para LLM (fallback/alternativo)")
    LANGCHAIN_API_KEY: str = Field(default="", description="LangSmith observability key (optional)")

    # ── Langfuse Observability ────────────────────────────────────────────
    LANGFUSE_PUBLIC_KEY: str = Field(default="", description="Langfuse public key for tracing")
    LANGFUSE_SECRET_KEY: str = Field(default="", description="Langfuse secret key for tracing")
    LANGFUSE_HOST: str = Field(
        default="https://cloud.langfuse.com",
        description="Langfuse API host (self-hosted or cloud)",
    )

    # ── Database (spec.md §3.3 — PostgreSQL preferred) ────────────────────
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://cadife:cadife@localhost:5432/cadife_db",
        description="Async PostgreSQL connection string",
    )

    # ── JWT Auth (spec.md §12.2 — 1h access, 7d refresh) ──────────────────
    JWT_SECRET_KEY: str = Field(
        default="change-me-in-production",
        description="JWT signing secret — MUST be overridden in production",
    )
    JWT_ALGORITHM: str = Field(default="HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60, ge=1)
    REFRESH_TOKEN_EXPIRE_DAYS: int = Field(default=7, ge=1)

    # ── Firebase Admin SDK (spec.md §3.3 — FCM) ───────────────────────────
    FIREBASE_CREDENTIALS: str = Field(
        default="./firebase_credentials.json",
        description="Path to Firebase Admin JSON credentials file",
    )

    # ── RAG / ChromaDB (spec.md §3.3) ─────────────────────────────────────
    CHROMA_PERSIST_DIR: str = Field(default="./chroma_db")
    KNOWLEDGE_BASE_DIR: str = Field(default="./knowledge_base")
    INGESTION_CACHE_PATH: str = Field(default="./chroma_db/ingestion_cache.json")

    # ── CORS (spec.md §12.2) ──────────────────────────────────────────────
    ALLOWED_ORIGINS: str = Field(
        default="http://localhost:3000,http://localhost:8080",
        description="Comma-separated list of allowed CORS origins",
    )

    # ── Rate Limiting (spec.md §12.3) ─────────────────────────────────────
    REDIS_HOST: str = Field(default="localhost")
    REDIS_PORT: int = Field(default=6379)
    REDIS_PASSWORD: str = Field(default="")
    REDIS_DB: int = Field(default=0)
    REDIS_PREFIX: str = Field(default="", description="Prefix for redis keys (e.g. STG_)")
    REDIS_URL: str = Field(default="redis://localhost:6379/0")
    RATE_LIMIT_WEBHOOK: str = Field(default="100/minute")
    RATE_LIMIT_IA: str = Field(default="30/minute")
    RATE_LIMIT_DEFAULT: str = Field(default="60/minute")

    # ── PII Encryption at-rest (Fernet/AES-128) ───────────────────────────
    ENCRYPTION_KEY: str = Field(default="", description="Fernet key for PII encryption")
    HASH_KEY: str = Field(default="", description="HMAC-SHA256 key for searchable phone hash")

    # ── Request Timeout (spec.md §12.3 — webhook must respond in < 5s) ────
    REQUEST_TIMEOUT_SECONDS: float = Field(
        default=30.0,
        description="Global request timeout in seconds. Webhook endpoint uses 5s limit.",
        ge=1.0,
    )
    WEBHOOK_TIMEOUT_SECONDS: float = Field(
        default=4.5,
        description="Hard timeout for webhook endpoints (Meta requires < 5s response)",
        ge=1.0,
    )

    @field_validator("JWT_SECRET_KEY")
    @classmethod
    def validate_jwt_secret(cls, v: str, info) -> str:
        """Warn loudly in production if JWT secret is still the default placeholder."""
        # Access APP_ENV via info.data if already validated
        app_env = info.data.get("APP_ENV", "development")
        if app_env == "production" and v == "change-me-in-production":
            raise ValueError(
                "JWT_SECRET_KEY must be set to a secure random value in production. "
                "Generate one with: python -c \"import secrets; print(secrets.token_hex(32))\""
            )
        return v

    @model_validator(mode="after")
    def compute_redis_url(self) -> "Settings":
        """Compute REDIS_URL if individual connection params are provided."""
        if self.REDIS_PASSWORD or self.REDIS_HOST != "localhost":
            pwd = f":{self.REDIS_PASSWORD}@" if self.REDIS_PASSWORD else ""
            self.REDIS_URL = f"redis://{pwd}{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
        return self

    @field_validator("DATABASE_URL")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v.startswith(("postgresql+asyncpg://", "sqlite+aiosqlite://")):
            raise ValueError(
                "DATABASE_URL deve usar o driver asyncpg. "
                "Use 'postgresql+asyncpg://' para PostgreSQL."
            )
        return v


def _load_external_secrets(settings: Settings) -> Settings:
    """
    Secret Management Hook — Production Strategy.

    In development: reads from .env (default above).
    In production: override env vars from AWS Secrets Manager or HashiCorp Vault.

    Example (AWS):
        import boto3, json
        client = boto3.client("secretsmanager", region_name="us-east-1")
        secret = json.loads(client.get_secret_value(SecretId="cadife/prod")["SecretString"])
        os.environ.update(secret)

    Example (HashiCorp Vault):
        import hvac
        client = hvac.Client(url=os.environ["VAULT_ADDR"], token=os.environ["VAULT_TOKEN"])
        secret = client.secrets.kv.read_secret_version(path="cadife/prod")["data"]["data"]
        os.environ.update(secret)

    This hook is intentionally empty for MVP — the interface is ready for extension.
    """
    if settings.APP_ENV == "production":
        # TODO: Implement production secret loading strategy here.
        # Options: AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager.
        pass
    return settings


@lru_cache
def get_settings() -> Settings:
    """
    Returns a cached singleton Settings instance.
    The lru_cache ensures .env is read only once per process startup.
    """
    settings = Settings()
    return _load_external_secrets(settings)
