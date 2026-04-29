from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    WHATSAPP_TOKEN: str = ""
    PHONE_NUMBER_ID: str = ""
    VERIFY_TOKEN: str = "cadife_verify_token"
    OPENAI_API_KEY: str = ""
    DATABASE_URL: str = "postgresql+asyncpg://cadife:cadife@localhost:5432/cadife_db"
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    FIREBASE_CREDENTIALS: str = "./firebase_credentials.json"
    CHROMA_PERSIST_DIR: str = "./chroma_db"
    KNOWLEDGE_BASE_DIR: str = "./knowledge_base"
    INGESTION_CACHE_PATH: str = "./chroma_db/ingestion_cache.json"
    LANGCHAIN_API_KEY: str = ""
    DEBUG: bool = False

    # Rate Limiting
    REDIS_URL: str = "redis://localhost:6379/0"
    RATE_LIMIT_WEBHOOK: str = "100/minute"
    RATE_LIMIT_IA: str = "30/minute"
    RATE_LIMIT_DEFAULT: str = "60/minute"

    # Criptografia PII at-rest (Fernet/AES-128)
    ENCRYPTION_KEY: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
