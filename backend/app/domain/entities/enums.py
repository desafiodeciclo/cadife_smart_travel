"""
Lead Domain Enums — Domain/Entities Layer
==========================================
Pure Python enums representing the Lead domain concepts from spec.md §4.1.
No framework dependencies — reusable across layers.
"""
from enum import Enum


class LeadOrigem(str, Enum):
    """Channel through which the lead entered the system (spec.md §4.1)."""
    whatsapp = "whatsapp"
    app = "app"
    web = "web"


class LeadStatus(str, Enum):
    """
    Lead lifecycle states (spec.md §8.4).
    Transitions:
      NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
      Any state → PERDIDO (after 30 days inactivity)
    """
    novo = "novo"
    em_atendimento = "em_atendimento"
    qualificado = "qualificado"
    agendado = "agendado"
    proposta = "proposta"
    fechado = "fechado"
    perdido = "perdido"


class LeadScore(str, Enum):
    """
    Lead temperature score (spec.md §8.3).
    - QUENTE: destino + datas + pessoas + orçamento all defined → immediate contact
    - MORNO: destino defined but dates/budget open → schedule curation
    - FRIO: only generic interest → nurture via WhatsApp follow-up
    """
    quente = "quente"
    morno = "morno"
    frio = "frio"


class TipoMensagem(str, Enum):
    """Message types handled by the webhook (spec.md §4.3)."""
    texto = "texto"
    audio = "audio"
    imagem = "imagem"
    documento = "documento"


class AgendamentoStatus(str, Enum):
    """Appointment lifecycle (spec.md §4.4)."""
    pendente = "pendente"
    confirmado = "confirmado"
    realizado = "realizado"
    cancelado = "cancelado"


class AgendamentoTipo(str, Enum):
    """Curation session type (spec.md §4.4)."""
    online = "online"
    presencial = "presencial"


class PropostaStatus(str, Enum):
    """Proposal lifecycle (spec.md §4.5)."""
    rascunho = "rascunho"
    enviada = "enviada"
    aprovada = "aprovada"
    recusada = "recusada"
    em_revisao = "em_revisao"


class PerfilViagem(str, Enum):
    """Traveler profile types (spec.md §4.2)."""
    casal = "casal"
    familia = "família"
    solo = "solo"
    grupo = "grupo"
    amigos = "amigos"


class OrcamentoPerfil(str, Enum):
    """Budget tier classification (spec.md §4.2)."""
    baixo = "baixo"
    medio = "médio"
    alto = "alto"
    premium = "premium"
