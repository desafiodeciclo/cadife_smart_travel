import pytest
from pydantic import ValidationError
from app.infrastructure.config.settings import Settings

def test_settings_load_defaults(monkeypatch):
    """Testa se as settings carregam com valores padrão quando possível."""
    monkeypatch.setenv("WHATSAPP_TOKEN", "test_token")
    monkeypatch.setenv("PHONE_NUMBER_ID", "test_id")
    monkeypatch.setenv("GEMINI_API_KEY", "test_gemini")
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://user:pass@localhost/db")
    monkeypatch.setenv("VERIFY_TOKEN", "test_verify")
    monkeypatch.setenv("APP_ENV", "development")
    
    settings = Settings()
    assert settings.APP_ENV == "development"
    assert settings.WHATSAPP_TOKEN == "test_token"

def test_settings_production_invalid_jwt(monkeypatch):
    """Testa se o validador rejeita a secret padrão em produção."""
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("JWT_SECRET_KEY", "change-me-in-production") # Valor proibido em prod
    monkeypatch.setenv("WHATSAPP_TOKEN", "test")
    monkeypatch.setenv("PHONE_NUMBER_ID", "test")
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://u:p@h/d")
    monkeypatch.setenv("GEMINI_API_KEY", "test")
    monkeypatch.setenv("VERIFY_TOKEN", "test")
    
    with pytest.raises(ValidationError) as exc:
        Settings()
    
    assert "JWT_SECRET_KEY must be set to a secure random value in production" in str(exc.value)

def test_settings_invalid_db_driver(monkeypatch):
    """Testa se o validador exige driver assíncrono."""
    monkeypatch.setenv("DATABASE_URL", "postgresql://user:pass@localhost/db") # Sem asyncpg
    monkeypatch.setenv("WHATSAPP_TOKEN", "test")
    monkeypatch.setenv("GEMINI_API_KEY", "test")
    monkeypatch.setenv("VERIFY_TOKEN", "test")

    with pytest.raises(ValidationError) as exc:
        Settings()
    
    assert "DATABASE_URL deve usar o driver asyncpg" in str(exc.value)
