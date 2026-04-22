"""
Repository Interfaces — Domain/Interfaces Layer
================================================
Abstract contracts that the Infrastructure layer must implement.
The Application layer (Use Cases) depends only on these abstractions,
never on concrete SQLAlchemy/DB implementations — enabling testability.
"""
import uuid
from abc import ABC, abstractmethod
from typing import Optional

from app.domain.entities.enums import LeadScore, LeadStatus


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
