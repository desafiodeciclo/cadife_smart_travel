import os
import pytest

# Set dummy environment variables for testing before any app code is imported
os.environ["WHATSAPP_TOKEN"] = "test_token"
os.environ["PHONE_NUMBER_ID"] = "test_id"
os.environ["OPENAI_API_KEY"] = "test_key"
os.environ["VERIFY_TOKEN"] = "test_verify"
os.environ["DATABASE_URL"] = "postgresql+asyncpg://user:pass@localhost/db"
os.environ["APP_ENV"] = "development"

# Eagerly import all ORM models so SQLAlchemy mapper configuration is complete
# before any test instantiates a model class. This avoids "failed to locate a name"
# errors when dependent models (e.g. Agendamento, Proposta) are referenced by
# string in relationship() definitions but not yet imported.
import app.models.lead  # noqa: F401
import app.models.briefing  # noqa: F401
import app.models.interacao  # noqa: F401
import app.models.agendamento  # noqa: F401
import app.models.proposta  # noqa: F401
import app.models.user  # noqa: F401
import app.models.notification_queue  # noqa: F401
import app.models.dead_letter_queue  # noqa: F401
