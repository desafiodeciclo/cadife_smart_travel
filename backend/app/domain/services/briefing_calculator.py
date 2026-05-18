"""
Briefing Calculator — Domain Service
======================================
Calcula completude do briefing e outros cálculos de domínio.
"""

BRIEFING_FIELDS = [
    "destino",
    "data_ida",
    "data_volta",
    "qtd_pessoas",
    "perfil",
    "tipo_viagem",
    "preferencias",
    "orcamento",
    "tem_passaporte",
]


def calculate_completude(briefing_data: dict) -> int:
    """Calcula o percentual de completude do briefing (9 campos obrigatórios, peso uniforme)."""
    from app.infrastructure.persistence.models.briefing_model import (
        calculate_completude as _canonical,
    )

    return _canonical(briefing_data)
