"""
ConversationSummary Pydantic Schemas — Presentation Layer
===========================================================
Request/response schemas for the conversation summary endpoints.
"""

import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ConversationSummaryTopics(BaseModel):
    """Structured topics extracted from a conversation session."""

    intencao_principal: Optional[str] = Field(
        None, description="Destino ou objetivo principal da viagem"
    )
    datas_e_passageiros: Optional[str] = Field(
        None, description="Datas de viagem e quantidade/perfil de passageiros"
    )
    orcamento: Optional[str] = Field(
        None, description="Faixa de orçamento e preferências financeiras"
    )
    restricoes_e_preferencias: Optional[str] = Field(
        None, description="Restrições alimentares, acessibilidade, preferências de hospedagem"
    )
    decisoes_tomadas: Optional[str] = Field(
        None, description="Decisões já acordadas durante a conversa"
    )
    proximos_passos: Optional[str] = Field(
        None, description="Próximos passos acordados com o cliente"
    )


class ConversationSummaryResponse(BaseModel):
    """Single conversation session summary."""

    id: uuid.UUID
    lead_id: uuid.UUID
    sessao_id: str
    resumo_json: Optional[ConversationSummaryTopics] = None
    resumo_pendente: bool
    gerado_em: datetime
    tokens_utilizados: Optional[int] = None

    model_config = {"from_attributes": True}


class ConversationSummaryListResponse(BaseModel):
    """Paginated list of conversation session summaries."""

    items: list[ConversationSummaryResponse]
    total: int
    page: int
    limit: int
    pages: int
