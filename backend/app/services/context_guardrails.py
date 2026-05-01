"""
RAG Context Guardrails — Filtros de segurança para documentos recuperados.

Remove ou sanitiza chunks que contenham informações proibidas
(preços, valores monetários, disponibilidade não confirmada, etc.)
antes de enviá-los ao LLM.
"""

import re
from typing import Optional, Protocol

import structlog
from langchain_core.documents import Document

logger = structlog.get_logger()

# ---------------------------------------------------------------------------
# Padrões de preço / valor monetário (case-insensitive, multiline)
# ---------------------------------------------------------------------------

_PRICE_PATTERNS = [
    # R$ 1.234,56 | R$1234,56 | R$ 1.234
    r"R\$\s*[\d.]+(?:,\d{2})?",
    # USD / US$ / $ 1,234.56
    r"US?\$\s*[\d,]+(?:\.\d{2})?",
    # € 1.234,56 | EUR 1.234
    r"€\s*[\d.]+(?:,\d{2})?",
    r"EUR\s*[\d.]+(?:,\d{2})?",
    # 1.234 reais | 1234 reais | mil reais
    r"\b[\d.]+\s*(?:mil(?:h[õo]es)?\s*)?(?:reais|dinheiro)\b",
    # parcela de R$... | entrada de R$...
    r"(?:parcela|entrada|taxa|custa)\s+(?:de\s+)?R?\$?\s*[\d.]+",
    # preço: ... | valor: ... | custo: ... seguido de número
    r"(?:pre[çc]o|valor|custo|investimento)\s*:?\s*(?:de\s+)?(?:aproximadamente\s+)?(?:R?\$?\s*)?[\d.]+",
    # número seguido de "por pessoa" com contexto monetário
    r"(?:R?\$?\s*)?[\d.]+(?:,\d{2})?\s+(?:por\s+pessoa|por\s+casal|por\s+noite)",
]

_PRICE_REGEX = re.compile(
    "|".join(f"(?:{p})" for p in _PRICE_PATTERNS),
    re.IGNORECASE | re.MULTILINE,
)

# Palavras-chave de alto risco que, mesmo sem número, indicam menção a preço
_PRICE_KEYWORDS = [
    r"\bpre[çc]o\b",
    r"\bcusta\b",
    r"\bcustam\b",
    r"\bvalor\b",
    r"\bor[çc]amento\b",
    r"\bfinanciamento\b",
    r"\bparcelamento\b",
    r"\bentrada\b",
    r"\bdesconto\b",
    r"\bpromo[çc][ãa]o\b",
    r"\boferta\b",
]

_PRICE_KEYWORD_REGEX = re.compile(
    "|".join(f"(?:{p})" for p in _PRICE_KEYWORDS),
    re.IGNORECASE,
)

# Regex combinada: detecta preço numérico OU keyword + número próximo
# Não usamos diretamente, mas como helper para contexto

# ---------------------------------------------------------------------------
# Guardrail Protocol
# ---------------------------------------------------------------------------

class Guardrail(Protocol):
    """Protocolo para guardrails de contexto."""

    def check(self, text: str) -> tuple[bool, Optional[str]]:
        """
        Verifica se o texto viola o guardrail.

        Returns:
            (violates, reason) — violates=True se violou, reason=descrição.
        """
        ...


# ---------------------------------------------------------------------------
# Implementações
# ---------------------------------------------------------------------------

class PriceGuardrail:
    """
    Bloqueia menções explícitas a preços, valores monetários e condições
    comerciais não autorizadas pela Cadife.
    """

    def __init__(self, block_keywords_only: bool = False) -> None:
        """
        Args:
            block_keywords_only: Se True, bloqueia apenas keyword + número.
                Se False (padrão), bloqueia qualquer padrão numérico monetário.
        """
        self.block_keywords_only = block_keywords_only

    def check(self, text: str) -> tuple[bool, Optional[str]]:
        # 1. Detecção de padrões numéricos monetários (alto risco)
        numeric_match = _PRICE_REGEX.search(text)
        if numeric_match:
            snippet = text[max(0, numeric_match.start() - 20):numeric_match.end() + 20]
            return True, f"Menção a valor monetário detectado: '...{snippet}...'"

        # 2. Se block_keywords_only=False, também bloqueia keywords de preço isoladas
        #    quando há números próximos (heurística simples)
        if not self.block_keywords_only:
            keyword_match = _PRICE_KEYWORD_REGEX.search(text)
            if keyword_match:
                # Verificar se há um número nas 30 chars ao redor
                start = max(0, keyword_match.start() - 30)
                end = min(len(text), keyword_match.end() + 30)
                surrounding = text[start:end]
                if re.search(r"\d", surrounding):
                    return True, f"Keyword de preço próxima a número: '...{surrounding}...'"

        return False, None


class AvailabilityGuardrail:
    """
    Bloqueia confirmações explícitas de disponibilidade de voos/hotéis/passeios.
    """

    _AVAILABILITY_PATTERNS = [
        r"\btemos\s+(?:vagas?|disponibilidade)\b",
        r"\bh[áa]\s+(?:vagas?|disponibilidade|lugares?)\b",
        r"\best[áa]\s+dispon[ií]vel\b",
        r"\bconfirmo\s+(?:sua\s+)?(?:reserva|vaga)\b",
        r"\bvoo\s+confirmado\b",
        r"\bhotel\s+confirmado\b",
        r"\bpasseio\s+confirmado\b",
    ]

    _AVAILABILITY_REGEX = re.compile(
        "|".join(f"(?:{p})" for p in _AVAILABILITY_PATTERNS),
        re.IGNORECASE,
    )

    def check(self, text: str) -> tuple[bool, Optional[str]]:
        match = self._AVAILABILITY_REGEX.search(text)
        if match:
            snippet = text[max(0, match.start() - 20):match.end() + 20]
            return True, f"Confirmação de disponibilidade detectada: '...{snippet}...'"
        return False, None


# ---------------------------------------------------------------------------
# Context Filter — orquestra múltiplos guardrails
# ---------------------------------------------------------------------------

DEFAULT_GUARDRAILS: list[Guardrail] = [
    PriceGuardrail(),
    AvailabilityGuardrail(),
]


class ContextFilter:
    """
    Aplica guardrails em uma lista de Documentos recuperados do RAG.

    Estratégias:
      - "remove": remove o chunk violador (padrão)
      - "mask": substitui o trecho violador por [REDACTED]
      - "flag": mantém o chunk mas marca como violador no metadata
    """

    def __init__(
        self,
        guardrails: Optional[list[Guardrail]] = None,
        strategy: str = "remove",
    ) -> None:
        self.guardrails = guardrails or DEFAULT_GUARDRAILS
        self.strategy = strategy
        if strategy not in ("remove", "mask", "flag"):
            raise ValueError("strategy must be one of: remove, mask, flag")

    def filter(self, docs: list[Document]) -> list[Document]:
        """
        Aplica guardrails nos documentos e retorna apenas os seguros.

        Args:
            docs: Documentos recuperados do vectorstore.

        Returns:
            Lista filtrada de Documentos seguros.
        """
        safe_docs: list[Document] = []
        violations: list[dict] = []

        for doc in docs:
            text = doc.page_content
            blocked = False
            reasons: list[str] = []

            for guardrail in self.guardrails:
                violates, reason = guardrail.check(text)
                if violates:
                    blocked = True
                    reasons.append(reason)

            if blocked:
                violations.append({
                    "source": doc.metadata.get("source", "unknown"),
                    "chunk_index": doc.metadata.get("chunk_index", -1),
                    "reasons": reasons,
                })
                if self.strategy == "remove":
                    continue
                elif self.strategy == "mask":
                    safe_docs.append(self._mask_document(doc, reasons))
                    continue
                elif self.strategy == "flag":
                    doc.metadata["guardrail_violations"] = reasons
                    safe_docs.append(doc)
                    continue

            safe_docs.append(doc)

        if violations:
            logger.warning(
                "context_guardrail_violations",
                strategy=self.strategy,
                removed=len(violations),
                total=len(docs),
                violations=violations,
            )

        return safe_docs

    def _mask_document(self, doc: Document, reasons: list[str]) -> Document:
        """Substitui trechos violadores por [REDACTED]."""
        text = doc.page_content
        for reason in reasons:
            # Tentar extrair o snippet do reason: '...snippet...'
            if "'..." in reason and "...'" in reason:
                snippet = reason.split("'...")[1].split("...'")[0]
                text = text.replace(snippet, "[REDACTED]")
        return Document(page_content=text, metadata=doc.metadata)


# ---------------------------------------------------------------------------
# Funções de conveniência
# ---------------------------------------------------------------------------

def apply_guardrails(
    docs: list[Document],
    strategy: str = "remove",
) -> list[Document]:
    """Aplica o ContextFilter padrão (preços + disponibilidade) em uma lista de docs."""
    return ContextFilter(strategy=strategy).filter(docs)
