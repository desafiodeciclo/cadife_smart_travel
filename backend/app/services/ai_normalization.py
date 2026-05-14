"""
AI Normalization — Normaliza aliases comuns retornados pela LLM
================================================================
Mapeia variantes acentuadas, traduzidas ou com erros de digitação
para os valores canônicos dos enums PerfilViagem e OrcamentoPerfil.
"""

import unicodedata

# Aliases comuns retornados pela LLM (acentuados, traduzidos, ou com erros).
# Mapeia variante → valor canônico do enum (sem acentos, conforme definido).
PERFIL_ALIASES: dict[str, str] = {
    "família": "familia",
    "famíla": "familia",
    "family": "familia",
    "group": "grupo",
    "couple": "casal",
    "alone": "solo",
    "friends": "amigos",
    "grupo de amigos": "amigos",
}

ORCAMENTO_ALIASES: dict[str, str] = {
    "médio": "medio",
    "medium": "medio",
    "low": "baixo",
    "high": "alto",
}


def normalize_perfil(value: object) -> object:
    """Normaliza um valor de perfil usando aliases conhecidos da LLM."""
    if isinstance(value, str):
        key = unicodedata.normalize("NFC", value.lower().strip())
        return PERFIL_ALIASES.get(key, key)
    return value


def normalize_orcamento(value: object) -> object:
    """Normaliza um valor de orçamento usando aliases conhecidos da LLM."""
    if isinstance(value, str):
        key = unicodedata.normalize("NFC", value.lower().strip())
        return ORCAMENTO_ALIASES.get(key, key)
    return value
