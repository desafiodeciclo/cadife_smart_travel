"""
Persistence Models Package — Infrastructure/Persistence Layer
=============================================================
Centralised import of all ORM models so that:
  1. Alembic env.py can import `models` once and detect all tables.
  2. SQLAlchemy mapper registry is populated before metadata operations.

Import order matters: Lead must be defined before dependent models.
"""
from app.infrastructure.persistence.models.user_model import UserModel  # noqa: F401
from app.infrastructure.persistence.models.lead_model import LeadModel  # noqa: F401
from app.infrastructure.persistence.models.briefing_model import BriefingModel  # noqa: F401
from app.infrastructure.persistence.models.interacao_model import InteracaoModel  # noqa: F401
from app.infrastructure.persistence.models.agendamento_model import AgendamentoModel  # noqa: F401
from app.infrastructure.persistence.models.proposta_model import PropostaModel  # noqa: F401

__all__ = [
    "UserModel",
    "LeadModel",
    "BriefingModel",
    "InteracaoModel",
    "AgendamentoModel",
    "PropostaModel",
]
