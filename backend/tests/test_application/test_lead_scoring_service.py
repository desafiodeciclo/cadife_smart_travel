"""
Tests — LeadScoringService
==========================
Testes unitários puros (sem banco, sem mock de I/O) para o motor de scoring.
Cada teste valida exatamente um critério ou combinação de critérios.
"""

from app.application.services.lead_scoring_service import (
    LIMIAR_MORNO,
    LIMIAR_QUENTE,
    PESO_COMPLETUDE_BRIEFING,
    PESO_DATAS_DEFINIDAS,
    PESO_DESISTENCIA,
    PESO_DESTINO_INFORMADO,
    PESO_ENGAJAMENTO_RAPIDO,
    PESO_INTERESSE_PROPOSTA,
    PESO_ORCAMENTO_ALTO,
    PESO_PASSAGEIROS_INFORMADOS,
    LeadScoringService,
    ScoringContext,
)
from app.domain.entities.enums import LeadScore, LeadStatus, OrcamentoPerfil

svc = LeadScoringService()


# ── Critérios individuais ──────────────────────────────────────────────────────


def test_completude_briefing_100_adds_points() -> None:
    ctx = ScoringContext(completude_pct=100)
    result = svc.calculate(ctx)
    assert result.criterios["completude_briefing"] == PESO_COMPLETUDE_BRIEFING


def test_completude_briefing_parcial_zero_points() -> None:
    ctx = ScoringContext(completude_pct=80)
    result = svc.calculate(ctx)
    assert result.criterios["completude_briefing"] == 0


def test_orcamento_alto_adds_points() -> None:
    ctx = ScoringContext(orcamento=OrcamentoPerfil.alto.value)
    result = svc.calculate(ctx)
    assert result.criterios["orcamento_alto"] == PESO_ORCAMENTO_ALTO


def test_orcamento_premium_adds_points() -> None:
    ctx = ScoringContext(orcamento=OrcamentoPerfil.premium.value)
    result = svc.calculate(ctx)
    assert result.criterios["orcamento_alto"] == PESO_ORCAMENTO_ALTO


def test_orcamento_medio_zero_points() -> None:
    ctx = ScoringContext(orcamento=OrcamentoPerfil.medio.value)
    result = svc.calculate(ctx)
    assert result.criterios["orcamento_alto"] == 0


def test_orcamento_baixo_zero_points() -> None:
    ctx = ScoringContext(orcamento=OrcamentoPerfil.baixo.value)
    result = svc.calculate(ctx)
    assert result.criterios["orcamento_alto"] == 0


def test_datas_definidas_adds_points() -> None:
    from datetime import date
    ctx = ScoringContext(data_ida=date(2026, 8, 1))
    result = svc.calculate(ctx)
    assert result.criterios["datas_definidas"] == PESO_DATAS_DEFINIDAS


def test_datas_ausentes_zero_points() -> None:
    ctx = ScoringContext(data_ida=None)
    result = svc.calculate(ctx)
    assert result.criterios["datas_definidas"] == 0


def test_destino_informado_adds_points() -> None:
    ctx = ScoringContext(destino="Portugal")
    result = svc.calculate(ctx)
    assert result.criterios["destino_informado"] == PESO_DESTINO_INFORMADO


def test_destino_vazio_zero_points() -> None:
    ctx = ScoringContext(destino=None)
    result = svc.calculate(ctx)
    assert result.criterios["destino_informado"] == 0


def test_passageiros_informados_adds_points() -> None:
    ctx = ScoringContext(qtd_pessoas=2)
    result = svc.calculate(ctx)
    assert result.criterios["passageiros_informados"] == PESO_PASSAGEIROS_INFORMADOS


def test_passageiros_zero_zero_points() -> None:
    ctx = ScoringContext(qtd_pessoas=None)
    result = svc.calculate(ctx)
    assert result.criterios["passageiros_informados"] == 0


def test_engajamento_rapido_adds_points() -> None:
    ctx = ScoringContext(engajamento_rapido=True)
    result = svc.calculate(ctx)
    assert result.criterios["engajamento_rapido"] == PESO_ENGAJAMENTO_RAPIDO


def test_engajamento_lento_zero_points() -> None:
    ctx = ScoringContext(engajamento_rapido=False)
    result = svc.calculate(ctx)
    assert result.criterios["engajamento_rapido"] == 0


def test_interesse_proposta_flag_adds_points() -> None:
    ctx = ScoringContext(has_proposta=True)
    result = svc.calculate(ctx)
    assert result.criterios["interesse_em_proposta"] == PESO_INTERESSE_PROPOSTA


def test_interesse_proposta_via_status_adds_points() -> None:
    ctx = ScoringContext(lead_status=LeadStatus.proposta.value)
    result = svc.calculate(ctx)
    assert result.criterios["interesse_em_proposta"] == PESO_INTERESSE_PROPOSTA


def test_interesse_fechado_via_status_adds_points() -> None:
    ctx = ScoringContext(lead_status=LeadStatus.fechado.value)
    result = svc.calculate(ctx)
    assert result.criterios["interesse_em_proposta"] == PESO_INTERESSE_PROPOSTA


def test_desistencia_detectada_subtracts_points() -> None:
    ctx = ScoringContext(desistencia_detectada=True)
    result = svc.calculate(ctx)
    assert result.criterios["desistencia_detectada"] == PESO_DESISTENCIA


def test_status_perdido_triggers_desistencia() -> None:
    ctx = ScoringContext(lead_status=LeadStatus.perdido.value)
    result = svc.calculate(ctx)
    assert result.criterios["desistencia_detectada"] == PESO_DESISTENCIA


# ── Score mínimo nunca negativo ────────────────────────────────────────────────


def test_score_never_below_zero() -> None:
    ctx = ScoringContext(desistencia_detectada=True)
    result = svc.calculate(ctx)
    assert result.score_numerico >= 0


def test_score_never_above_100() -> None:
    from datetime import date
    ctx = ScoringContext(
        completude_pct=100,
        orcamento=OrcamentoPerfil.premium.value,
        data_ida=date(2026, 8, 1),
        destino="Portugal",
        qtd_pessoas=4,
        engajamento_rapido=True,
        has_proposta=True,
    )
    result = svc.calculate(ctx)
    assert result.score_numerico <= 100


# ── Classificação (labels) ────────────────────────────────────────────────────


def test_label_frio_abaixo_limiar_morno() -> None:
    ctx = ScoringContext()  # score = 0
    result = svc.calculate(ctx)
    assert result.score_label == LeadScore.frio.value
    assert result.score_numerico < LIMIAR_MORNO


def test_label_morno_entre_limiares() -> None:
    # destino(+10) + data_ida(+10) + qtd_pessoas(+5) + orcamento_alto(+15) + engajamento(+10) = 50
    from datetime import date
    ctx = ScoringContext(
        destino="Lisboa",
        data_ida=date(2026, 9, 1),
        qtd_pessoas=2,
        orcamento=OrcamentoPerfil.alto.value,
        engajamento_rapido=True,
    )
    result = svc.calculate(ctx)
    assert LIMIAR_MORNO <= result.score_numerico < LIMIAR_QUENTE
    assert result.score_label == LeadScore.morno.value


def test_label_quente_acima_limiar_quente() -> None:
    # completude(+20) + orcamento_alto(+15) + data_ida(+10) + destino(+10)
    # + qtd_pessoas(+5) + engajamento(+10) + interesse_proposta(+20) = 90
    from datetime import date
    ctx = ScoringContext(
        completude_pct=100,
        destino="Paris",
        data_ida=date(2026, 12, 20),
        qtd_pessoas=2,
        orcamento=OrcamentoPerfil.alto.value,
        engajamento_rapido=True,
        has_proposta=True,
    )
    result = svc.calculate(ctx)
    assert result.score_numerico >= LIMIAR_QUENTE
    assert result.score_label == LeadScore.quente.value


# ── criterios_json ──────────────────────────────────────────────────────────


def test_criterios_json_is_valid_json() -> None:
    import json
    ctx = ScoringContext(destino="Tóquio")
    result = svc.calculate(ctx)
    parsed = json.loads(result.criterios_json)
    assert "destino_informado" in parsed
    assert "desistencia_detectada" in parsed


# ── context_from_lead (helper) ────────────────────────────────────────────────


def test_context_from_lead_with_briefing() -> None:
    from datetime import date
    from unittest.mock import MagicMock

    lead = MagicMock()
    lead.status = LeadStatus.em_atendimento
    lead.propostas = []

    briefing = MagicMock()
    briefing.completude_pct = 100
    briefing.destino = "Roma"
    briefing.data_ida = date(2026, 7, 15)
    briefing.qtd_pessoas = 2
    briefing.orcamento = OrcamentoPerfil.alto

    lead.briefing = briefing

    ctx = LeadScoringService.context_from_lead(lead, engajamento_rapido=True)

    assert ctx.completude_pct == 100
    assert ctx.destino == "Roma"
    assert ctx.data_ida == date(2026, 7, 15)
    assert ctx.qtd_pessoas == 2
    assert ctx.orcamento == OrcamentoPerfil.alto.value
    assert ctx.engajamento_rapido is True
    assert ctx.desistencia_detectada is False


def test_context_from_lead_without_briefing() -> None:
    from unittest.mock import MagicMock

    lead = MagicMock()
    lead.status = LeadStatus.perdido
    lead.briefing = None
    lead.propostas = []

    ctx = LeadScoringService.context_from_lead(lead)

    assert ctx.completude_pct == 0
    assert ctx.desistencia_detectada is True


def test_motivo_preserved_in_result() -> None:
    ctx = ScoringContext(motivo="recalculo_admin")
    result = svc.calculate(ctx)
    assert result.motivo == "recalculo_admin"
