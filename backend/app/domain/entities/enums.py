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
    indicacao = "indicação"
    telefone = "telefone"
    presencial = "presencial"
    rede_social = "rede social"
    outro = "outro"
    manual = "manual"
    offer_interest = "offer_interest"


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
    expirada = "expirada"


class PerfilViagem(str, Enum):
    """Traveler profile types (spec.md §4.2)."""

    casal = "casal"
    familia = "familia"
    solo = "solo"
    grupo = "grupo"
    amigos = "amigos"


class OrcamentoPerfil(str, Enum):
    """Budget tier classification (spec.md §4.2)."""

    baixo = "baixo"
    medio = "medio"
    alto = "alto"
    premium = "premium"


class SuitcaseCategory(str, Enum):
    """Categories for suitcase items (feat/client-suitcase-backend)."""

    documentos = "documentos"
    roupas = "roupas"
    higiene = "higiene"
    eletronicos = "eletronicos"
    saude = "saude"
    acessorios = "acessorios"
    outros = "outros"


class DestinationType(str, Enum):
    """Deterministic destination categories for suggestions."""

    praia = "praia"
    frio = "frio"
    urbano = "urbano"
    aventura = "aventura"


class DocumentoCategoria(str, Enum):
    """Document categories for travel management (spec.md §7.2)."""

    passagem = "passagem"
    voucher = "voucher"
    transfer = "transfer"
    seguro = "seguro"
    itinerario = "itinerario"
    outros = "outros"


class OfferStatus(str, Enum):
    """Offer lifecycle states based on §ETAPA-1-01."""

    draft = "draft"           # Rascunho
    published = "published"   # Publicada
    sold_out = "sold_out"     # Sem vagas
    expired = "expired"       # Vencida
    archived = "archived"     # Arquivada


class OfferCategoria(str, Enum):
    """Travel offer categories."""

    internacional = "internacional"
    nacional = "nacional"
    lua_de_mel = "lua_de_mel"
    familia = "familia"
    aventura = "aventura"
    cruzeiro = "cruzeiro"
    executivo = "executivo"
    outros = "outros"


class OcasiaoViagem(str, Enum):
    """Travel occasion / trip purpose (audit §4.1 — prevents LLM hallucination)."""

    ferias = "ferias"
    lua_de_mel = "lua_de_mel"
    aniversario = "aniversario"
    familia = "familia"
    negocios = "negocios"
    intercambio = "intercambio"
    outro = "outro"


class ItineraryItemType(str, Enum):
    """
    Itinerary item types (mirrors ItineraryItemType enum in Flutter).
    Values match the JSON strings returned by GET /leads/{id}/itinerary.
    """

    voo = "voo"
    hotel_checkin = "hotel_checkin"
    hotel_checkout = "hotel_checkout"
    passeio = "passeio"
    transferencia = "transferencia"
    refeicao = "refeicao"
    evento_customizado = "evento_customizado"
class TravelCheckpoint(str, Enum):
    """
    Ordered milestones of a travel lifecycle (feat/travel-checkpoints-progress-001).

    Activation rules:
      BRIEFING_COLETADO   — auto: score_numerico > 40 AND briefing >= 5 fields
      CURADORIA_INICIADA  — manual: consultor via POST /leads/{id}/checkpoints
      PROPOSTA_ENVIADA    — auto: Proposta.status → enviada
      PROPOSTA_APROVADA   — manual or auto: consultor or client confirmation
      VIAGEM_CONFIRMADA   — manual: consultor after lead closes
      VIAGEM_EM_ANDAMENTO — auto: daily cron on departure date
      VIAGEM_CONCLUIDA    — auto: daily cron on return date + 1 day
    """

    briefing_coletado = "BRIEFING_COLETADO"
    curadoria_iniciada = "CURADORIA_INICIADA"
    proposta_enviada = "PROPOSTA_ENVIADA"
    proposta_aprovada = "PROPOSTA_APROVADA"
    viagem_confirmada = "VIAGEM_CONFIRMADA"
    viagem_em_andamento = "VIAGEM_EM_ANDAMENTO"
    viagem_concluida = "VIAGEM_CONCLUIDA"
