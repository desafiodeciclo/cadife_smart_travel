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
    LANGCHAIN_API_KEY: str = ""
    DEBUG: bool = False

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
