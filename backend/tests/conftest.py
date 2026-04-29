import os
import pytest

# Set dummy environment variables for testing before any app code is imported
os.environ["WHATSAPP_TOKEN"] = "test_token"
os.environ["PHONE_NUMBER_ID"] = "test_id"
os.environ["OPENAI_API_KEY"] = "test_key"
os.environ["VERIFY_TOKEN"] = "test_verify"
os.environ["DATABASE_URL"] = "postgresql+asyncpg://user:pass@localhost/db"
os.environ["APP_ENV"] = "development"
