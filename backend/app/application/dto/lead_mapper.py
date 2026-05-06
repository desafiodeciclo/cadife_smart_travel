"""
Lead Data Mappers — Application Layer
======================================
Pure functions that translate ORM models (SQLAlchemy instances) into
Presentation DTOs.  This layer guarantees that the API surface never
leaks internal DB fields or ORM objects.

All mapping is explicit: every field in the DTO is assigned by hand,
preventing accidental exposure when the ORM model changes.
"""
from __future__ import annotations

import uuid
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.models.lead import Lead
    from app.models.briefing import Briefing

from app.presentation.schemas.leads import (
    LeadDetailDTO,
    LeadListItemDTO,
    LeadListResponseDTO,
    LeadMetricsDTO,
    PropostaListItemDTO,
)


def _mascara_telefone(telefone: str | None) -> str | None:
    """Mask a phone number, keeping only the last 4 digits visible."""
    if not telefone:
        return None
    return telefone[:4] + "*****" + telefone[-4:] if len(telefone) > 8 else "********"


def map_lead_to_list_item(lead: "Lead", completude_pct: int | None = None) -> LeadListItemDTO:
    """Map a Lead ORM instance to the list-item DTO.

    The phone number is masked in list views to reduce PII exposure
    while still allowing consultants to identify the lead roughly.
    """
    return LeadListItemDTO(
        id=lead.id,
        nome=lead.nome,
        telefone_mascarado=_mascara_telefone(lead.telefone),
        origem=lead.origem,
        status=lead.status,
        score=lead.score,
        criado_em=lead.criado_em,
        atualizado_em=lead.atualizado_em,
        completude_pct=completude_pct,
    )


def map_lead_to_detail(lead: "Lead") -> LeadDetailDTO:
    """Map a Lead ORM instance to the full-detail DTO."""
    propostas = []
    raw_propostas = getattr(lead, "propostas", None)
    if raw_propostas and isinstance(raw_propostas, (list, tuple)):
        for p in raw_propostas:
            propostas.append(
                PropostaListItemDTO(
                    id=p.id,
                    descricao=p.descricao,
                    status=p.status,
                    valor_estimado=p.valor_estimado,
                    criado_em=p.criado_em,
                )
            )

    dto = LeadDetailDTO(
        id=lead.id,
        nome=lead.nome,
        telefone=lead.telefone,
        origem=lead.origem,
        status=lead.status,
        score=lead.score,
        consultor_id=lead.consultor_id,
        is_archived=lead.is_archived,
        criado_em=lead.criado_em,
        atualizado_em=lead.atualizado_em,
        propostas=propostas,
    )

    if lead.consultor:
        raw_name = getattr(lead.consultor, "nome", None)
        dto.consultor_nome = raw_name if isinstance(raw_name, str) else None
        raw_avatar = getattr(lead.consultor, "avatar_url", None)
        dto.consultor_avatar = raw_avatar if isinstance(raw_avatar, str) else None

    return dto


def map_leads_to_list_response(
    leads: list["Lead"],
    total: int,
    page: int,
    limit: int,
) -> LeadListResponseDTO:
    """Map a page of Lead ORM instances to the paginated list response."""
    items: list[LeadListItemDTO] = []
    for lead in leads:
        completude = None
        if lead.briefing:
            completude = lead.briefing.completude_pct
        items.append(map_lead_to_list_item(lead, completude_pct=completude))

    pages = (total + limit - 1) // limit if limit else 1
    return LeadListResponseDTO(
        items=items,
        total=total,
        page=page,
        limit=limit,
        pages=pages,
    )


def map_counts_to_metrics(counts: dict[str, int]) -> LeadMetricsDTO:
    """Map a raw status-count dict to the metrics DTO."""
    return LeadMetricsDTO(
        total_ativos=counts.get("total_ativos", 0),
        total_novos=counts.get("novo", 0),
        total_em_atendimento=counts.get("em_atendimento", 0),
        total_qualificados=counts.get("qualificado", 0),
        total_agendados=counts.get("agendado", 0),
        total_proposta=counts.get("proposta", 0),
        total_fechados=counts.get("fechado", 0),
        total_perdidos=counts.get("perdido", 0),
    )
