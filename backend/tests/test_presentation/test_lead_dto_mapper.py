"""
Tests — Presentation/DTO & DataLeak Prevention
================================================
Unit tests for Lead DTO mappers and the contract that ORM instances
are never returned directly from route handlers.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any
from unittest.mock import MagicMock

import pytest
from pydantic import ValidationError

from app.application.dto.lead_mapper import (
    map_counts_to_metrics,
    map_lead_to_detail,
    map_lead_to_list_item,
    map_leads_to_list_response,
)
from app.domain.entities.enums import LeadOrigem, LeadScore, LeadStatus, PropostaStatus
from app.presentation.schemas.leads import LeadDetailDTO, LeadListItemDTO, LeadListResponseDTO, LeadMetricsDTO


# ── Helpers ────────────────────────────────────────────────────────────────

def make_fake_lead(**overrides: Any) -> MagicMock:
    """Build a MagicMock that quacks like a Lead ORM instance."""
    lead = MagicMock()
    lead.id = overrides.get("id", uuid.uuid4())
    lead.nome = overrides.get("nome", "João Silva")
    lead.telefone = overrides.get("telefone", "5584999990001")
    lead.origem = overrides.get("origem", LeadOrigem.whatsapp)
    lead.status = overrides.get("status", LeadStatus.novo)
    lead.score = overrides.get("score", None)
    lead.consultor_id = overrides.get("consultor_id", None)
    lead.is_archived = overrides.get("is_archived", False)
    lead.criado_em = overrides.get("criado_em", datetime.now())
    lead.atualizado_em = overrides.get("atualizado_em", datetime.now())

    # Relationships
    lead.briefing = overrides.get("briefing", None)
    lead.consultor = overrides.get("consultor", None)
    lead.propostas = overrides.get("propostas", [])

    # Sensitive field that must NEVER leak to the wire
    lead.telefone_hash = overrides.get("telefone_hash", "a1b2c3")
    return lead


def make_fake_proposta(**overrides: Any) -> MagicMock:
    p = MagicMock()
    p.id = overrides.get("id", uuid.uuid4())
    p.descricao = overrides.get("descricao", "Proposta A")
    p.status = overrides.get("status", PropostaStatus.rascunho)
    p.valor_estimado = overrides.get("valor_estimado", Decimal("5000.00"))
    p.criado_em = overrides.get("criado_em", datetime.now())
    return p


# ── List Item Mapper ───────────────────────────────────────────────────────

def test_map_lead_to_list_item_masks_phone():
    lead = make_fake_lead(telefone="5584999990001")
    dto = map_lead_to_list_item(lead)
    assert dto.telefone_mascarado == "5584*****0001"


def test_map_lead_to_list_item_omits_sensitive_fields():
    lead = make_fake_lead()
    dto = map_lead_to_list_item(lead)
    # telefone_hash must not exist on the DTO
    assert not hasattr(dto, "telefone_hash")
    # Raw telefone must not exist on the DTO
    assert not hasattr(dto, "telefone")


def test_map_lead_to_list_item_includes_completude():
    briefing = MagicMock()
    briefing.completude_pct = 75
    lead = make_fake_lead(briefing=briefing)
    dto = map_lead_to_list_item(lead, completude_pct=briefing.completude_pct)
    assert dto.completude_pct == 75


# ── Detail Mapper ──────────────────────────────────────────────────────────

def test_map_lead_to_detail_exposes_phone_for_consultant():
    """Detail view may expose full phone because the consultant needs it."""
    lead = make_fake_lead(telefone="5584999990001")
    dto = map_lead_to_detail(lead)
    assert dto.telefone == "5584999990001"


def test_map_lead_to_detail_omits_telefone_hash():
    lead = make_fake_lead()
    dto = map_lead_to_detail(lead)
    assert not hasattr(dto, "telefone_hash")


def test_map_lead_to_detail_maps_propostas():
    proposta = make_fake_proposta()
    lead = make_fake_lead(propostas=[proposta])
    dto = map_lead_to_detail(lead)
    assert len(dto.propostas) == 1
    assert dto.propostas[0].id == proposta.id
    assert dto.propostas[0].valor_estimado == Decimal("5000.00")


def test_map_lead_to_detail_maps_consultor():
    consultor = MagicMock()
    consultor.nome = "Ana Paula"
    consultor.avatar_url = "https://cdn.example/avatar.png"
    lead = make_fake_lead(consultor=consultor)
    dto = map_lead_to_detail(lead)
    assert dto.consultor_nome == "Ana Paula"
    assert dto.consultor_avatar == "https://cdn.example/avatar.png"


def test_map_lead_to_detail_safe_with_none_consultor():
    lead = make_fake_lead(consultor=None)
    dto = map_lead_to_detail(lead)
    assert dto.consultor_nome is None
    assert dto.consultor_avatar is None


def test_map_lead_to_detail_safe_with_magicmock_propostas():
    """MagicMock for propostas must not break iteration."""
    lead = make_fake_lead()
    # propostas defaults to [] in make_fake_lead, so this is already safe.
    dto = map_lead_to_detail(lead)
    assert dto.propostas == []


# ── Paginated List Mapper ──────────────────────────────────────────────────

def test_map_leads_to_list_response_computes_pages():
    leads = [make_fake_lead() for _ in range(5)]
    resp = map_leads_to_list_response(leads, total=23, page=1, limit=5)
    assert isinstance(resp, LeadListResponseDTO)
    assert resp.total == 23
    assert resp.page == 1
    assert resp.limit == 5
    assert resp.pages == 5  # ceil(23/5)


# ── Metrics Mapper ─────────────────────────────────────────────────────────

def test_map_counts_to_metrics():
    counts = {
        "total_ativos": 100,
        "novo": 10,
        "em_atendimento": 20,
        "qualificado": 30,
        "agendado": 15,
        "proposta": 10,
        "fechado": 10,
        "perdido": 5,
    }
    dto = map_counts_to_metrics(counts)
    assert dto.total_ativos == 100
    assert dto.total_qualificados == 30


# ── Schema Contract Enforcement ────────────────────────────────────────────

def test_lead_detail_dto_rejects_extra_fields():
    """Ensure DTO schema is strict — extra fields cause validation errors."""
    with pytest.raises(ValidationError):
        LeadDetailDTO(
            id=uuid.uuid4(),
            nome="Test",
            telefone="5584999990001",
            origem=LeadOrigem.whatsapp,
            status=LeadStatus.novo,
            is_archived=False,
            criado_em=datetime.now(),
            atualizado_em=datetime.now(),
            telefone_hash="bad",  # extra field
        )


def test_lead_list_item_dto_rejects_raw_telefone():
    with pytest.raises(ValidationError):
        LeadListItemDTO(
            id=uuid.uuid4(),
            nome="Test",
            telefone="5584999990001",  # raw phone not allowed in list view
            origem=LeadOrigem.whatsapp,
            status=LeadStatus.novo,
            criado_em=datetime.now(),
            atualizado_em=datetime.now(),
        )


def test_lead_metrics_dto_rejects_extra_fields():
    with pytest.raises(ValidationError):
        LeadMetricsDTO(
            total_ativos=1,
            total_novos=1,
            total_em_atendimento=1,
            total_qualificados=1,
            total_agendados=1,
            total_proposta=1,
            total_fechados=1,
            total_perdidos=1,
            leaked_field="bad",
        )
