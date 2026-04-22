"""
Repositories Package — Infrastructure/Persistence Layer
=======================================================
Public re-exports for all concrete repository implementations.
Application layer uses only domain interfaces; this package is
consumed by the DI container / FastAPI dependency providers.
"""
from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
from app.infrastructure.persistence.repositories.briefing_repository import BriefingRepository
from app.infrastructure.persistence.repositories.interacao_repository import InteracaoRepository
from app.infrastructure.persistence.repositories.agendamento_repository import AgendamentoRepository
from app.infrastructure.persistence.repositories.proposta_repository import PropostaRepository

__all__ = [
    "LeadRepository",
    "BriefingRepository",
    "InteracaoRepository",
    "AgendamentoRepository",
    "PropostaRepository",
]
