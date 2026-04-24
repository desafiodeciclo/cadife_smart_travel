"""
Repository Interfaces — Domain/Interfaces Layer
================================================
Abstract contracts that the Infrastructure layer must implement.
The Application layer (Use Cases) depends only on these abstractions,
never on concrete SQLAlchemy/DB implementations — enabling testability.
"""
import uuid
from abc import ABC, abstractmethod
from datetime import date, time
from decimal import Decimal
from typing import Optional

from app.domain.entities.enums import (
    AgendamentoStatus,
    AgendamentoTipo,
    LeadScore,
    LeadStatus,
    PropostaStatus,
    TipoMensagem,
)


class ILeadRepository(ABC):
    """Interface for Lead persistence operations."""

    @abstractmethod
    async def get_by_phone(self, phone: str) -> Optional[object]:
        ...

    @abstractmethod
    async def get_by_id(self, lead_id: uuid.UUID) -> Optional[object]:
        ...

    @abstractmethod
    async def create(self, telefone: str, nome: Optional[str] = None) -> object:
        ...

    @abstractmethod
    async def update_status(self, lead_id: uuid.UUID, status: LeadStatus) -> object:
        ...

    @abstractmethod
    async def update_score(self, lead_id: uuid.UUID, score: LeadScore) -> object:
        ...

    @abstractmethod
    async def list_all(
        self,
        status: Optional[str] = None,
        score: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        limit: int = 20,
    ) -> tuple[list, int]:
        ...

    @abstractmethod
    async def soft_delete(self, lead_id: uuid.UUID) -> None:
        ...


class IBriefingRepository(ABC):
    """Interface for Briefing persistence operations."""

    @abstractmethod
    async def get_by_lead(self, lead_id: uuid.UUID) -> Optional[object]:
        ...

    @abstractmethod
    async def upsert(self, lead_id: uuid.UUID, data: dict) -> object:
        ...


class IInteracaoRepository(ABC):
    """Interface for Interacao (WhatsApp message exchange) persistence."""

    @abstractmethod
    async def create(
        self,
        lead_id: uuid.UUID,
        mensagem_cliente: Optional[str] = None,
        mensagem_ia: Optional[str] = None,
        tipo_mensagem: TipoMensagem = TipoMensagem.texto,
    ) -> object:
        ...

    @abstractmethod
    async def list_by_lead(
        self,
        lead_id: uuid.UUID,
        page: int = 1,
        limit: int = 50,
    ) -> tuple[list, int]:
        ...


class IAgendamentoRepository(ABC):
    """Interface for Agendamento (curation appointment) persistence."""

    @abstractmethod
    async def create(
        self,
        lead_id: uuid.UUID,
        data: date,
        hora: time,
        tipo: AgendamentoTipo = AgendamentoTipo.online,
        consultor_id: Optional[uuid.UUID] = None,
    ) -> object:
        ...

    @abstractmethod
    async def update_status(
        self,
        agendamento_id: uuid.UUID,
        status: AgendamentoStatus,
    ) -> object:
        ...

    @abstractmethod
    async def list_by_lead(self, lead_id: uuid.UUID) -> list:
        ...

    @abstractmethod
    async def list_by_consultor(
        self,
        consultor_id: uuid.UUID,
        data: Optional[date] = None,
    ) -> list:
        ...


class IPropostaRepository(ABC):
    """Interface for Proposta (travel proposal) persistence."""

    @abstractmethod
    async def create(
        self,
        lead_id: uuid.UUID,
        descricao: str,
        valor_estimado: Optional[Decimal] = None,
        consultor_id: Optional[uuid.UUID] = None,
    ) -> object:
        ...

    @abstractmethod
    async def update(
        self,
        proposta_id: uuid.UUID,
        *,
        status: Optional[PropostaStatus] = None,
        descricao: Optional[str] = None,
        valor_estimado: Optional[Decimal] = None,
    ) -> object:
        ...

    @abstractmethod
    async def get_by_id(self, proposta_id: uuid.UUID) -> Optional[object]:
        ...

    @abstractmethod
    async def list_by_lead(
        self,
        lead_id: uuid.UUID,
        status: Optional[PropostaStatus] = None,
    ) -> list:
        ...

    @abstractmethod
    async def list_by_consultor(
        self,
        consultor_id: uuid.UUID,
        status: Optional[PropostaStatus] = None,
    ) -> list:
        ...


class INotificationService(ABC):
    """Interface for push notification delivery (FCM)."""

    @abstractmethod
    async def notify_new_lead(self, fcm_token: str, lead_name: str, destino: Optional[str]) -> None:
        ...


class IMessageGateway(ABC):
    """Interface for outbound messaging (WhatsApp)."""

    @abstractmethod
    async def send(self, phone: str, message: str) -> None:
        ...
