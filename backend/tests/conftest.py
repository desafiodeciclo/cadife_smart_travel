import os
import pytest

# Set dummy environment variables for testing before any app code is imported
os.environ["WHATSAPP_TOKEN"] = "test_token"
os.environ["PHONE_NUMBER_ID"] = "test_id"
os.environ["OPENAI_API_KEY"] = "test_key"
os.environ["VERIFY_TOKEN"] = "test_verify"
os.environ["DATABASE_URL"] = "postgresql+asyncpg://user:pass@localhost/db"
os.environ["APP_ENV"] = "development"
os.environ["ENCRYPTION_KEY"] = "858iXm1S2iXN5sH3W6V-q7W_U8U7z6T5S4R3Q2P1O0N="
os.environ["HASH_KEY"] = "f8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7"
