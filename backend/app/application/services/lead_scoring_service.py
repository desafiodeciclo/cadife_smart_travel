"""
LeadScoringService — Application Layer
=======================================
Motor determinístico de scoring de qualificação de leads (0–100).

Regras validadas pelo PO Diego em 2026-05-11 (lead-scoring-engine-001).
A IA NUNCA gera o score: todo cálculo é baseado em campos extraídos do briefing
e sinais contextuais passados explicitamente via ScoringContext.

Pesos configuráveis como constantes de módulo — alteráveis sem tocar lógica.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Optional

from app.domain.entities.enums import LeadScore, LeadStatus, OrcamentoPerfil

# ── Pesos dos critérios (validados pelo PO em 2026-05-11) ─────────────────────
PESO_COMPLETUDE_BRIEFING = 20       # +20 se completude_pct == 100
PESO_ORCAMENTO_ALTO = 15            # +15 se orcamento in (alto, premium)
PESO_DATAS_DEFINIDAS = 10           # +10 se data_ida preenchida
PESO_DESTINO_INFORMADO = 10         # +10 se destino preenchido
PESO_PASSAGEIROS_INFORMADOS = 5     # +5  se qtd_pessoas > 0
PESO_ENGAJAMENTO_RAPIDO = 10        # +10 se última resposta do cliente < 30 min
PESO_INTERESSE_PROPOSTA = 20        # +20 se lead tem proposta ou status é proposta/fechado
PESO_DESISTENCIA = -30              # -30 se desistência detectada (status perdido ou flag)

# Limiares de classificação
LIMIAR_QUENTE = 71
LIMIAR_MORNO = 41

# Orçamentos que qualificam como "acima de R$ 5.000"
ORCAMENTOS_ALTO = {OrcamentoPerfil.alto.value, OrcamentoPerfil.premium.value}

# Statuses que indicam interesse explícito em proposta
STATUSES_COM_PROPOSTA = {
    LeadStatus.proposta.value,
    LeadStatus.fechado.value,
}


@dataclass
class ScoringContext:
    """
    Dados necessários para o cálculo do score.
    Todos os sinais contextuais são determinísticos — nenhum campo é gerado pela IA.
    """
    completude_pct: int = 0
    destino: Optional[str] = None
    data_ida: Optional[object] = None   # date ou None
    qtd_pessoas: Optional[int] = None
    orcamento: Optional[str] = None     # OrcamentoPerfil.value ou None
    lead_status: str = LeadStatus.novo.value
    has_proposta: bool = False
    engajamento_rapido: bool = False    # última msg do cliente chegou em < 30 min
    desistencia_detectada: bool = False # status == perdido ou flag explícita
    motivo: str = "auto"                # "auto" | "manual" | "recalculo_admin"


@dataclass
class ScoringResult:
    """Resultado imutável do cálculo de score."""
    score_numerico: int
    score_label: str
    criterios: dict[str, int]
    motivo: str

    @property
    def criterios_json(self) -> str:
        return json.dumps(self.criterios, ensure_ascii=False)


class LeadScoringService:
    """
    Calcula o score de qualificação de um lead de forma determinística e testável.
    Não possui dependências de I/O — pode ser testado sem banco ou mock.
    """

    def calculate(self, ctx: ScoringContext) -> ScoringResult:
        criterios: dict[str, int] = {}
        score = 0

        # ── Completude do briefing: +20 se 100% preenchido ─────────────────
        if ctx.completude_pct == 100:
            criterios["completude_briefing"] = PESO_COMPLETUDE_BRIEFING
            score += PESO_COMPLETUDE_BRIEFING
        else:
            criterios["completude_briefing"] = 0

        # ── Orçamento acima de R$ 5.000: +15 se alto ou premium ────────────
        if ctx.orcamento and ctx.orcamento in ORCAMENTOS_ALTO:
            criterios["orcamento_alto"] = PESO_ORCAMENTO_ALTO
            score += PESO_ORCAMENTO_ALTO
        else:
            criterios["orcamento_alto"] = 0

        # ── Datas definidas: +10 se data_ida preenchida ─────────────────────
        if ctx.data_ida is not None:
            criterios["datas_definidas"] = PESO_DATAS_DEFINIDAS
            score += PESO_DATAS_DEFINIDAS
        else:
            criterios["datas_definidas"] = 0

        # ── Destino específico: +10 se destino preenchido ──────────────────
        if ctx.destino:
            criterios["destino_informado"] = PESO_DESTINO_INFORMADO
            score += PESO_DESTINO_INFORMADO
        else:
            criterios["destino_informado"] = 0

        # ── Número de passageiros: +5 se qtd_pessoas informado ─────────────
        if ctx.qtd_pessoas is not None and ctx.qtd_pessoas >= 1:
            criterios["passageiros_informados"] = PESO_PASSAGEIROS_INFORMADOS
            score += PESO_PASSAGEIROS_INFORMADOS
        else:
            criterios["passageiros_informados"] = 0

        # ── Engajamento (resposta rápida < 30min): +10 ──────────────────────
        if ctx.engajamento_rapido:
            criterios["engajamento_rapido"] = PESO_ENGAJAMENTO_RAPIDO
            score += PESO_ENGAJAMENTO_RAPIDO
        else:
            criterios["engajamento_rapido"] = 0

        # ── Interesse explícito em proposta: +20 ────────────────────────────
        if ctx.has_proposta or ctx.lead_status in STATUSES_COM_PROPOSTA:
            criterios["interesse_em_proposta"] = PESO_INTERESSE_PROPOSTA
            score += PESO_INTERESSE_PROPOSTA
        else:
            criterios["interesse_em_proposta"] = 0

        # ── Desistência detectada: -30 ──────────────────────────────────────
        if ctx.desistencia_detectada or ctx.lead_status == LeadStatus.perdido.value:
            criterios["desistencia_detectada"] = PESO_DESISTENCIA
            score += PESO_DESISTENCIA
        else:
            criterios["desistencia_detectada"] = 0

        score_final = max(0, min(100, score))
        label = self._classify(score_final)

        return ScoringResult(
            score_numerico=score_final,
            score_label=label,
            criterios=criterios,
            motivo=ctx.motivo,
        )

    @staticmethod
    def _classify(score: int) -> str:
        if score >= LIMIAR_QUENTE:
            return LeadScore.quente.value
        if score >= LIMIAR_MORNO:
            return LeadScore.morno.value
        return LeadScore.frio.value

    @staticmethod
    def context_from_lead(
        lead: object,
        engajamento_rapido: bool = False,
        motivo: str = "auto",
        briefing: object | None = None,
    ) -> ScoringContext:
        """
        Constrói ScoringContext a partir de uma instância ORM Lead.
        Separado do cálculo para permitir testes com objetos simples.

        ``briefing`` pode ser passado explicitamente para evitar lazy-load em
        contexto async (greenlet_spawn). Se None, tenta obter via lead.briefing
        somente se o atributo já estiver carregado na identidade map da sessão.
        """
        # Acessa "briefing" sem disparar lazy-load: verifica se já está em memória.
        if briefing is None:
            sa_state = getattr(lead, "__sa_instance_state__", None)
            if sa_state is not None and "briefing" in sa_state.dict:
                briefing = lead.briefing  # já carregado — seguro
            # else: briefing permanece None; scoring sem dados de briefing

        status_val = getattr(lead, "status", LeadStatus.novo)
        if hasattr(status_val, "value"):
            status_val = status_val.value

        # Acessa "propostas" sem disparar lazy-load: verifica se já está em memória.
        sa_state = getattr(lead, "__sa_instance_state__", None)
        if sa_state is not None and "propostas" in sa_state.dict:
            has_proposta = bool(lead.propostas)
        else:
            has_proposta = False
        if not has_proposta:
            has_proposta = status_val in STATUSES_COM_PROPOSTA

        desistencia = status_val == LeadStatus.perdido.value

        if briefing is None:
            return ScoringContext(
                lead_status=status_val,
                has_proposta=has_proposta,
                engajamento_rapido=engajamento_rapido,
                desistencia_detectada=desistencia,
                motivo=motivo,
            )

        orcamento = getattr(briefing, "orcamento", None)
        if hasattr(orcamento, "value"):
            orcamento = orcamento.value

        return ScoringContext(
            completude_pct=getattr(briefing, "completude_pct", 0),
            destino=getattr(briefing, "destino", None),
            data_ida=getattr(briefing, "data_ida", None),
            qtd_pessoas=getattr(briefing, "qtd_pessoas", None),
            orcamento=orcamento,
            lead_status=status_val,
            has_proposta=has_proposta,
            engajamento_rapido=engajamento_rapido,
            desistencia_detectada=desistencia,
            motivo=motivo,
        )


# Singleton para reutilização (stateless, thread-safe)
lead_scoring_service = LeadScoringService()
