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
    APP_ENV: Literal["development", "staging", "production", "test"] = Field(
        default="development",
        description="Current environment — controls secret loading strategy",
    )
    DEBUG: bool = Field(default=False)

    # ── WhatsApp Cloud API (spec.md §15) ──────────────────────────────────
    WHATSAPP_TOKEN: str = Field(default="", description="Meta WhatsApp access token")
    PHONE_NUMBER_ID: str = Field(
        default="", description="Meta registered phone number ID"
    )
    VERIFY_TOKEN: str = Field(
        default="cadife_verify_token",
        description="Secret token for Meta webhook verification",
    )
    META_APP_SECRET: str = Field(
        default="", description="Meta App Secret for X-Hub-Signature-256 validation"
    )
    META_APP_ID: str = Field(
        default="", description="Meta App ID — required for token exchange"
    )

    # ── OpenRouter (chat LLM + embeddings) ───────────────────────────────
    OPENROUTER_API_KEY: str = Field(
        default="", description="OpenRouter API key para chat LLM e embeddings"
    )
    OPENROUTER_MODEL: str = Field(
        default="google/gemini-2.0-flash-001",
        description="Modelo principal para chat/lógica conversacional (Gemini 2.0 Flash estável)",
    )
    OPENROUTER_AUDIO_MODEL: str = Field(
        default="openai/gpt-4o-audio-preview",
        description="Modelo para transcrição de áudio via input_audio no /chat/completions (aceita WAV/MP3)",
    )
    OPENROUTER_VISION_MODEL: str = Field(
        default="google/gemini-2.0-flash-001",
        description="Modelo para análise de fotos/prints enviados pelo cliente (preferências de viagem)",
    )
    OPENROUTER_EMBEDDING_MODEL: str = Field(
        default="google/gemini-embedding-2-preview",
        description="Modelo para embeddings RAG (base de conhecimento Cadife)",
    )
    OPENROUTER_TRIAGEM_MODEL: str = Field(
        default="mistralai/ministral-8b-2512",
        description="TriagemAgent — extração JSON estruturado do CRM (identificação cliente novo/recorrente)",
    )
    OPENROUTER_CONVERSION_MODEL: str = Field(
        default="google/gemini-2.0-flash-001",
        description="OrquestradorAgent — raciocínio conversacional RAG-aware com LangGraph",
    )
    OPENROUTER_WHISPER_MODEL: str = Field(
        default="openai/whisper-large-v3",
        description="Modelo Whisper primário para transcrição de áudio via /audio/transcriptions",
    )
    OPENROUTER_IMAGE_GEN_MODEL: str = Field(
        default="recraft/recraft-v3",
        description="Modelo de geração de imagens inspiracionais ao final do briefing (recraft-v4 quando disponível via OpenRouter)",
    )
    OPENROUTER_FALLBACK_MODEL: str = Field(
        default="mistralai/ministral-8b-2512",
        description="Modelo fallback econômico para redundância quando cadeia principal falha",
    )

    # ── Google Gemini (mantido para compatibilidade — não mais necessário) ─
    GEMINI_API_KEY: str = Field(
        default="", description="Gemini API key (legado — substituído pelo OpenRouter)"
    )
    LANGCHAIN_API_KEY: str = Field(
        default="", description="LangSmith observability key (optional)"
    )

    # ── LangSmith Observability ───────────────────────────────────────────
    LANGCHAIN_TRACING_V2: str = Field(
        default="false", description="Ativar tracing LangSmith (true/false)"
    )
    LANGCHAIN_PROJECT: str = Field(
        default="cadife-smart-travel", description="Nome do projeto no LangSmith"
    )
    LANGCHAIN_ENDPOINT: str = Field(
        default="https://api.smith.langchain.com",
        description="Endpoint da API LangSmith",
    )

    SLACK_WEBHOOK_URL: str = Field(
        default="", description="Slack webhook URL for critical alerts"
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

    # ── Google Calendar Integration ────────────────────────────────────────
    GOOGLE_CALENDAR_CREDENTIALS: str = Field(
        default="./google_calendar_credentials.json",
        description="Caminho para o arquivo JSON de credenciais da conta de serviço Google",
    )
    GOOGLE_CALENDAR_ID: str = Field(
        default="primary",
        description="ID da Agenda do Google onde as curadorias serão agendadas",
    )

    # ── RAG / PGVector (produção) ──────────────────────────────────────────
    PGVECTOR_CONNECTION_STRING: str = Field(
        default="postgresql+psycopg://cadife:cadife@localhost:5432/cadife_db",
        description="Sync psycopg3 connection para PGVector (langchain-postgres)",
    )
    KNOWLEDGE_BASE_DIR: str = Field(default="./knowledge_base")
    INGESTION_CACHE_PATH: str = Field(
        default="/opt/cadife/app/storage/cache/ingestion_cache.json",
        description=(
            "Caminho absoluto para o cache JSON de ingestão RAG. "
            "Deve estar fora da pasta de código para evitar Permission Denied. "
            "O diretório é criado automaticamente se não existir."
        ),
    )

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
    REDIS_PREFIX: str = Field(
        default="", description="Prefix for redis keys (e.g. STG_)"
    )
    REDIS_URL: str = Field(default="redis://localhost:6379/0")
    RATE_LIMIT_WEBHOOK: str = Field(default="100/minute")
    RATE_LIMIT_IA: str = Field(default="30/minute")
    RATE_LIMIT_DEFAULT: str = Field(default="60/minute")

    # ── PII Encryption at-rest (Fernet/AES-128) ───────────────────────────
    ENCRYPTION_KEY: str = Field(default="", description="Fernet key for PII encryption")
    HASH_KEY: str = Field(
        default="", description="HMAC-SHA256 key for searchable phone hash"
    )

    # ── Notification Queue & DLQ ──────────────────────────────────────────
    NOTIFICATION_MAX_RETRIES: int = Field(default=3, ge=0)
    NOTIFICATION_RETRY_DELAY_SECONDS: int = Field(default=60, ge=1)
    NOTIFICATION_DEBOUNCE_TTL_SECONDS: int = Field(default=60, ge=1)
    NOTIFICATION_PROCESSING_TIMEOUT_SECONDS: int = Field(
        default=120,
        ge=1,
        description="Timeout to recover jobs stuck in 'processing' after a worker crash (seconds)",
    )

    # ── Cache / Redis (spec.md §5.3) ──────────────────────────────────────
    CACHE_TTL_SECONDS: int = Field(
        default=300,
        ge=1,
        description="Default TTL for Redis-backed endpoint cache (seconds)",
    )
    CACHE_ENABLED: bool = Field(
        default=True,
        description="Global toggle for response caching via Redis",
    )

    # ── Business Rules (spec.md §8.4) ─────────────────────────────────────
    LEAD_EXPIRATION_DAYS: int = Field(
        default=30,
        ge=1,
        description="Days of inactivity before a lead is automatically transitioned to PERDIDO",
    )
    PROPOSTA_EXPIRATION_HOURS_DEFAULT: int = Field(
        default=48,
        ge=1,
        description="Default SLA in hours before a proposal (enviada/em_revisao) is auto-expired",
    )
    PROPOSTA_EXPIRATION_WEBHOOK_URL: str = Field(
        default="",
        description="Optional HTTP endpoint to POST when proposals are auto-expired (CRM, Slack, etc.)",
    )

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
                'Generate one with: python -c "import secrets; print(secrets.token_hex(32))"'
            )
        return v

    @model_validator(mode="after")
    def compute_redis_url(self) -> "Settings":
        """Compute REDIS_URL if individual connection params are provided."""
        if self.REDIS_PASSWORD or self.REDIS_HOST != "localhost":
            pwd = f":{self.REDIS_PASSWORD}@" if self.REDIS_PASSWORD else ""
            self.REDIS_URL = (
                f"redis://{pwd}{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
            )
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
