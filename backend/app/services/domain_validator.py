"""Camada de Validador de Domínio — Application Layer.

Classe pure Python que processa regras estritas de negócio sobre o briefing
de viagem extraído pela IA. Valida razoabilidade financeira e viabilidade
temporal antes de persistir os dados.

Se regras falharem, retorna os erros para serem injetados no histórico
do chat, instruindo a LLM a dialogar com o cliente.
"""

from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Optional

import structlog

from app.models.briefing import BriefingExtracted, OrcamentoNivel

logger = structlog.get_logger()


# ── Constantes de Regras de Negócio ──────────────────────────────────────

# Destinos internacionais de alto custo — orçamento mínimo "médio"
DESTINOS_ALTO_CUSTO: set[str] = {
    # Europa
    "europa", "frança", "paris", "itália", "italia", "roma", "milão",
    "espanha", "madrid", "barcelona", "portugal", "lisboa", "porto",
    "alemanha", "berlim", "londres", "inglaterra", "reino unido",
    "suíça", "suiça", "holanda", "amsterdam", "grécia", "grecia",
    "croácia", "croacia", "irlanda", "dublin", "escócia", "noruega",
    "suécia", "dinamarca", "áustria", "austria", "viena", "praga",
    "república tcheca", "turquia", "istambul",
    # Ásia
    "japão", "japao", "tóquio", "tokyo", "coreia do sul", "seul",
    "china", "pequim", "xangai", "tailândia", "tailandia", "bangkok",
    "singapura", "hong kong", "índia", "india", "vietnã", "vietna",
    "indonésia", "indonesia", "bali", "maldivas",
    # América do Norte
    "estados unidos", "eua", "usa", "nova york", "new york",
    "miami", "orlando", "los angeles", "las vegas", "canadá", "canada",
    "toronto", "vancouver",
    # Oceania
    "austrália", "australia", "nova zelândia", "nova zelandia",
    # África premium
    "dubai", "emirados", "abu dhabi",
}

# Destinos de custo moderado — orçamento mínimo "baixo" é aceitável
DESTINOS_CUSTO_MODERADO: set[str] = {
    "argentina", "buenos aires", "chile", "santiago", "uruguai",
    "montevidéu", "montevideu", "colômbia", "colombia", "bogotá",
    "cartagena", "peru", "lima", "cusco", "machu picchu",
    "bolívia", "bolivia", "paraguai", "equador",
}

# Duração mínima razoável para destinos internacionais (em dias)
DURACAO_MINIMA_INTERNACIONAL: int = 4

# Hierarquia de orçamento para comparação
_ORCAMENTO_NIVEL: dict[str, int] = {
    "baixo": 1,
    "médio": 2,
    "medio": 2,
    "alto": 3,
    "premium": 4,
}


@dataclass
class ValidationResult:
    """Resultado da validação de domínio."""
    is_valid: bool
    errors: list[str] = field(default_factory=list)

    def add_error(self, message: str) -> None:
        self.errors.append(message)
        self.is_valid = False


def _normalizar_destino(destino: str) -> str:
    """Normaliza o nome do destino para comparação case-insensitive."""
    return destino.strip().lower()


def _orcamento_nivel_valor(orcamento: Optional[OrcamentoNivel]) -> int:
    """Retorna o valor numérico do nível de orçamento."""
    if orcamento is None:
        return 0
    return _ORCAMENTO_NIVEL.get(orcamento.value, 0)


def _destino_eh_alto_custo(destino: str) -> bool:
    """Verifica se o destino está na lista de alto custo."""
    normalizado = _normalizar_destino(destino)
    return any(d in normalizado or normalizado in d for d in DESTINOS_ALTO_CUSTO)


def _destino_eh_internacional(destino: str) -> bool:
    """Verifica se o destino parece ser internacional (não é Brasil)."""
    normalizado = _normalizar_destino(destino)
    destinos_nacionais = {
        "brasil", "são paulo", "sao paulo", "rio de janeiro",
        "salvador", "recife", "fortaleza", "florianópolis", "florianopolis",
        "curitiba", "belo horizonte", "brasília", "brasilia", "natal",
        "maceió", "maceio", "porto alegre", "manaus", "belém", "belem",
        "gramado", "campos do jordão", "campos do jordao", "bonito",
        "fernando de noronha", "jericoacoara", "porto seguro",
        "chapada diamantina", "foz do iguaçu", "foz do iguacu",
        "lençóis maranhenses", "lencois maranhenses", "pantanal",
    }
    return not any(d in normalizado or normalizado in d for d in destinos_nacionais)


class BriefingValidator:
    """Validador de domínio para briefings de viagem.

    Processa regras estritas de negócio:
    - Razoabilidade financeira (destino x orçamento)
    - Viabilidade temporal (datas futuras, duração mínima)
    """

    def validate(self, briefing: BriefingExtracted) -> ValidationResult:
        """Executa todas as validações sobre o briefing extraído.

        Returns:
            ValidationResult com is_valid=True se todas as regras passaram,
            ou is_valid=False com lista de erros descritivos.
        """
        result = ValidationResult(is_valid=True)

        self._validar_datas(briefing, result)
        self._validar_razoabilidade_financeira(briefing, result)
        self._validar_duracao_minima(briefing, result)

        if not result.is_valid:
            logger.warning(
                "domain_validation_failed",
                destino=briefing.destino,
                orcamento=briefing.orcamento.value if briefing.orcamento else None,
                data_ida=str(briefing.data_ida) if briefing.data_ida else None,
                data_volta=str(briefing.data_volta) if briefing.data_volta else None,
                errors=result.errors,
            )
        else:
            logger.info("domain_validation_passed", destino=briefing.destino)

        return result

    def _validar_datas(self, briefing: BriefingExtracted, result: ValidationResult) -> None:
        """Valida viabilidade temporal das datas informadas."""
        hoje = date.today()

        if briefing.data_ida is not None:
            if briefing.data_ida <= hoje:
                result.add_error(
                    "A data de ida informada já passou. "
                    "Precisamos de uma data futura para organizar a viagem."
                )

        if briefing.data_volta is not None:
            if briefing.data_volta <= hoje:
                result.add_error(
                    "A data de volta informada já passou. "
                    "Precisamos de uma data futura para o retorno."
                )

        if briefing.data_ida is not None and briefing.data_volta is not None:
            if briefing.data_volta <= briefing.data_ida:
                result.add_error(
                    "A data de volta não pode ser igual ou anterior à data de ida. "
                    "Verifique as datas da viagem."
                )

    def _validar_razoabilidade_financeira(
        self, briefing: BriefingExtracted, result: ValidationResult
    ) -> None:
        """Valida se o orçamento é compatível com o destino."""
        if briefing.destino is None or briefing.orcamento is None:
            return  # Sem dados suficientes para validar

        nivel = _orcamento_nivel_valor(briefing.orcamento)

        if _destino_eh_alto_custo(briefing.destino) and nivel < 2:
            result.add_error(
                f"O destino '{briefing.destino}' é um destino internacional de alto custo. "
                "Um orçamento mais flexível seria necessário para garantir uma experiência "
                "confortável. Considere ajustar o orçamento ou explorar destinos alternativos."
            )

    def _validar_duracao_minima(
        self, briefing: BriefingExtracted, result: ValidationResult
    ) -> None:
        """Valida se a duração mínima é razoável para o destino."""
        if (
            briefing.destino is None
            or briefing.data_ida is None
            or briefing.data_volta is None
        ):
            return  # Sem dados suficientes para validar

        duracao = (briefing.data_volta - briefing.data_ida).days

        if _destino_eh_internacional(briefing.destino) and duracao < DURACAO_MINIMA_INTERNACIONAL:
            result.add_error(
                f"Para um destino internacional como '{briefing.destino}', uma viagem de "
                f"apenas {duracao} dia(s) seria muito curta para aproveitar a experiência. "
                f"Recomendamos no mínimo {DURACAO_MINIMA_INTERNACIONAL} dias."
            )
