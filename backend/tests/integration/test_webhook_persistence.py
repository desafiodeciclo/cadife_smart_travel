"""
Integration Tests — Webhook Persistence (Guardrail 3.2)
=========================================================
Verifica que as operações de persistência críticas do fluxo WhatsApp→BD
funcionam corretamente contra um banco de dados real (SQLite in-memory).

Estes testes exercitam diretamente as funções de serviço em vez de chamar
execute() completo, pois o upsert de lead usa dialeto PostgreSQL (insert
ON CONFLICT DO UPDATE) que não funciona com SQLite.  O foco é na camada de
persistência corrigida nas Fases 1 e 2:

  - Fix 1.3 / Phase 2: update_briefing_from_extraction com commit=False (UoW)
  - Fix 1.4 / Phase 2: save_interacao + update_interacao_send_result em UoW
  - Phase 2: activate_checkpoint usa savepoint para não envenenar tx externa
"""

import uuid
from datetime import date
from unittest.mock import AsyncMock, patch

import pytest
from sqlalchemy import select

from app.domain.entities.enums import LeadOrigem, LeadStatus, TravelCheckpoint
from app.infrastructure.security.pii_encryption import hmac_hash
from app.models.briefing import Briefing, BriefingExtracted
from app.models.interacao import Interacao
from app.models.lead import Lead
from app.models.travel_checkpoint import TravelCheckpointRecord
from app.services import lead_service
from app.services.whatsapp_service import SendResult

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_PHONE = "5511987654300"


def _make_lead() -> Lead:
    return Lead(
        id=uuid.uuid4(),
        telefone=_PHONE,
        telefone_hash=hmac_hash(_PHONE),
        status=LeadStatus.em_atendimento,
        origem=LeadOrigem.whatsapp,
    )


def _make_send_result(success: bool = True) -> SendResult:
    return SendResult(success=success, wamid="wamid.test.123", latency_ms=10)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def patch_side_effects():
    """
    Stub FCM and spawn_with_own_session so tests don't fire network calls or
    create background tasks that outlive the test and access the shared DB.
    """
    with (
        patch(
            "app.services.lead_service._get_client_fcm_token",
            new=AsyncMock(return_value=None),
        ),
        patch(
            "app.infrastructure.persistence.session_utils.spawn_with_own_session",
            return_value=None,
        ),
    ):
        yield


# ---------------------------------------------------------------------------
# Test 1 — briefing fields persist via Unit-of-Work (commit=False + ext commit)
# ---------------------------------------------------------------------------


async def test_briefing_fields_persist_in_unit_of_work(db_session):
    """
    Garante que update_briefing_from_extraction(commit=False) + db.commit()
    externo persiste os campos do briefing no banco.

    Regresso: antes do fix de UoW (Fase 2), o briefing era silenciosamente
    descartado quando uma sessão isolada dentro do orquestrador comitava,
    invalidando o objeto Lead na sessão pai.
    """
    lead = _make_lead()
    db_session.add(lead)
    await db_session.flush()
    await db_session.refresh(lead)

    extracted = BriefingExtracted(destino="Lisboa")

    await lead_service.update_briefing_from_extraction(
        db_session, lead, extracted, commit=False
    )

    # Simulate the single UoW commit that _process does at the end.
    await db_session.commit()

    result = await db_session.execute(
        select(Briefing).where(Briefing.lead_id == lead.id)
    )
    briefing = result.scalar_one_or_none()

    assert briefing is not None, "Briefing deve existir no banco após commit do UoW"
    assert briefing.destino == "Lisboa", (
        f"Campo destino esperado 'Lisboa', obtido '{briefing.destino}'"
    )


async def test_briefing_persists_with_default_standalone_commit(db_session):
    """
    Verifica o comportamento padrão (commit=True) — chamadas directas de
    serviço fora do contexto UoW continuam a funcionar sem alterações.
    """
    lead = _make_lead()
    db_session.add(lead)
    await db_session.flush()
    await db_session.refresh(lead)

    extracted = BriefingExtracted(destino="Paris")

    briefing = await lead_service.update_briefing_from_extraction(
        db_session, lead, extracted  # commit=True por defeito
    )

    assert briefing.destino == "Paris"

    result = await db_session.execute(
        select(Briefing).where(Briefing.lead_id == lead.id)
    )
    persisted = result.scalar_one_or_none()

    assert persisted is not None
    assert persisted.destino == "Paris"


# ---------------------------------------------------------------------------
# Test 2 — interaction + send_result persist via UoW
# ---------------------------------------------------------------------------


async def test_interaction_and_send_result_persist_in_unit_of_work(db_session):
    """
    Garante que save_interacao(commit=False) + update_interacao_send_result(commit=False)
    + db.commit() final persiste a interação com status de envio correto.

    Regresso (Fix 1.4 Fase 1): sem db.refresh(interacao) após flush, o id e o
    timestamp gerados pelo banco ficavam None e update_interacao_send_result
    atualizava o objeto errado.
    """
    lead = _make_lead()
    db_session.add(lead)
    await db_session.flush()

    interacao = await lead_service.save_interacao(
        db_session,
        lead.id,
        msg_cliente="Quero ir para Lisboa",
        msg_ia="Ótimo! Conte mais sobre a viagem.",
        commit=False,
    )

    # Verify id was populated after flush (regression: was None before fix)
    assert interacao.id is not None, "id deve ser atribuído após flush"

    send_result = _make_send_result(success=True)
    await lead_service.update_interacao_send_result(
        db_session, interacao, send_result, commit=False
    )

    # Single UoW commit
    await db_session.commit()

    result = await db_session.execute(
        select(Interacao).where(Interacao.id == interacao.id)
    )
    persisted = result.scalar_one_or_none()

    assert persisted is not None, "Interação deve estar no banco após commit do UoW"
    assert persisted.mensagem_cliente == "Quero ir para Lisboa"
    assert persisted.mensagem_ia == "Ótimo! Conte mais sobre a viagem."
    assert persisted.status_envio == "sent", (
        f"status_envio esperado 'sent', obtido '{persisted.status_envio}'"
    )


async def test_failed_send_persists_failed_status(db_session):
    """Falha de envio WhatsApp deve persistir status_envio='failed'."""
    lead = _make_lead()
    db_session.add(lead)
    await db_session.flush()

    interacao = await lead_service.save_interacao(
        db_session, lead.id,
        msg_cliente="Oi",
        msg_ia="Olá!",
        commit=False,
    )

    await lead_service.update_interacao_send_result(
        db_session, interacao, _make_send_result(success=False), commit=False
    )
    await db_session.commit()

    result = await db_session.execute(
        select(Interacao).where(Interacao.id == interacao.id)
    )
    persisted = result.scalar_one_or_none()
    assert persisted is not None
    assert persisted.status_envio == "failed"


# ---------------------------------------------------------------------------
# Test 3 — savepoint absorbs duplicate checkpoint without poisoning outer tx
# ---------------------------------------------------------------------------


async def test_duplicate_checkpoint_savepoint_preserves_briefing(db_session):
    """
    Garante que activate_checkpoint(commit=False) com savepoint absorve o
    IntegrityError de checkpoint duplicado sem invalidar a transação externa,
    permitindo que o briefing (parte do mesmo UoW) seja persistido normalmente.

    Regresso (Fase 2): antes do savepoint, o IntegrityError do checkpoint
    chamava db.rollback() na sessão inteira, descartando silenciosamente o
    briefing que estava pendente na mesma transação.
    """
    from app.services.checkpoint_service import activate_checkpoint, SISTEMA
    from app.domain.entities.enums import TravelCheckpoint

    lead = _make_lead()
    db_session.add(lead)
    briefing = Briefing(lead_id=None)  # will be set after lead flush
    db_session.add(lead)
    await db_session.flush()
    await db_session.refresh(lead)

    # Pre-insert the checkpoint (simulates it was already activated previously)
    existing = TravelCheckpointRecord(
        lead_id=lead.id,
        checkpoint=TravelCheckpoint.briefing_coletado,
        ativado_por="pre_existing",
    )
    db_session.add(existing)
    await db_session.commit()

    # Now try to activate the same checkpoint again with commit=False (savepoint path).
    # Should raise HTTP 409 but NOT rollback the outer transaction.
    from fastapi import HTTPException

    with pytest.raises(HTTPException) as exc_info:
        await activate_checkpoint(
            db_session,
            lead.id,
            TravelCheckpoint.briefing_coletado,
            SISTEMA,
            commit=False,
        )

    assert exc_info.value.status_code == 409

    # The outer transaction must still be usable — add a new record and commit.
    interacao = await lead_service.save_interacao(
        db_session,
        lead.id,
        msg_cliente="Após checkpoint duplicado",
        msg_ia="Tudo certo!",
        commit=False,
    )
    await db_session.commit()

    result = await db_session.execute(
        select(Interacao).where(Interacao.id == interacao.id)
    )
    persisted = result.scalar_one_or_none()

    assert persisted is not None, (
        "Interação deve ser persistida mesmo após savepoint rollback de checkpoint duplicado"
    )
    assert persisted.mensagem_cliente == "Após checkpoint duplicado"
