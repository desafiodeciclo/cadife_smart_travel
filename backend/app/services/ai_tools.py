"""
AI Tools — Services Layer
==========================
OpenAI-compatible tool definitions for function calling via OpenRouter.
These tools give the LLM controlled, read-only access to live data so it can
answer client questions without hallucinating.

Available tools:
  query_project_scope(query)   — RAG search in the Cadife knowledge base
  check_existing_lead(phone)   — lead lookup (name, status, score)
  persist_lead_data(phone, data) — upsert key briefing fields from conversation

Design notes:
  - Tool schemas follow the OpenAI function-calling JSON format, which OpenRouter
    forwards verbatim to the underlying model.
  - execute_tool() is the single dispatch entry point — the AI layer calls it
    after the model returns a tool_call response, passing back the result as a
    tool message before the next completion.
  - DB-bound tools (check_existing_lead, persist_lead_data) accept an optional
    AsyncSession; pass None in tests or when DB is unavailable — they degrade
    gracefully.
"""

from __future__ import annotations

import json
import re
from datetime import datetime
from typing import Any, Optional

import httpx
import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.services import rag_service

logger = structlog.get_logger()

from app.services.ai_normalization import (
    ORCAMENTO_ALIASES as _ORCAMENTO_ALIASES,
    PERFIL_ALIASES as _PERFIL_ALIASES,
)

# Corrige DD/MMYYYY → DD/MM/YYYY (ex: "17/092027" → "17/09/2027")
_DATE_MISSING_SLASH_RE = re.compile(r'^(\d{1,2})/(\d{2})(\d{4})$')


def _normalize_date_str(value: Any) -> Any:
    """Tenta reparar strings de data malformadas antes da validação Pydantic."""
    if not isinstance(value, str):
        return value
    v = value.strip().replace(" ", "")
    # Corrige barra ausente entre mês e ano: 17/092027 → 17/09/2027
    v = _DATE_MISSING_SLASH_RE.sub(r'\1/\2/\3', v)
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"):
        try:
            return datetime.strptime(v, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    return value  # retorna original; Pydantic vai rejeitar e logar o erro


def _normalize_date_fields(data: dict[str, Any]) -> dict[str, Any]:
    """Normaliza data_ida e data_volta antes da validação do BriefingExtracted."""
    result = dict(data)
    for field in ("data_ida", "data_volta"):
        if field in result:
            result[field] = _normalize_date_str(result[field])
    return result


def _normalize_briefing_enums(data: dict[str, Any]) -> dict[str, Any]:
    """Corrige valores de enum enviados pela IA sem acento ou em inglês."""
    result = dict(data)
    if isinstance(result.get("perfil"), str):
        result["perfil"] = _PERFIL_ALIASES.get(result["perfil"].lower(), result["perfil"])
    if isinstance(result.get("orcamento"), str):
        result["orcamento"] = _ORCAMENTO_ALIASES.get(
            result["orcamento"].lower(), result["orcamento"]
        )
    return result


_OPENROUTER_BASE = "https://openrouter.ai/api/v1"
_OPENROUTER_HEADERS = {
    "HTTP-Referer": "https://cadifetour.com",
    "X-Title": "Cadife Smart Travel",
}

# ── Tool Schemas (OpenAI function-calling format) ────────────────────────────

TOOL_SCHEMAS: list[dict[str, Any]] = [
    {
        "type": "function",
        "function": {
            "name": "get_lead_context_by_wa_id",
            "description": (
                "Busca contexto completo do lead no CRM PostgreSQL pelo WhatsApp ID (wa_id). "
                "Retorna: nome, status atual, score, campos do briefing já preenchidos e as "
                "últimas 5 interações. Use SEMPRE no início de cada atendimento para saber "
                "quais campos já foram coletados e evitar perguntas repetidas."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "wa_id": {
                        "type": "string",
                        "description": (
                            "WhatsApp ID do cliente — número de telefone em formato "
                            "internacional sem '+' (ex: 5511999999999)."
                        ),
                    }
                },
                "required": ["wa_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "check_availability",
            "description": (
                "Verifica disponibilidade de horários para curadoria com um consultor Cadife. "
                "Retorna até 3 slots disponíveis nos próximos dias úteis. "
                "Use quando o briefing estiver completo (completude ≥ 60%) e for hora de "
                "oferecer agendamento ao cliente. "
                "NOTA: integração Google Calendar pendente — retorna slots simulados por ora."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "preferred_date": {
                        "type": "string",
                        "description": "Data preferida pelo cliente no formato YYYY-MM-DD (opcional).",
                    },
                    "duration_minutes": {
                        "type": "integer",
                        "description": "Duração da curadoria em minutos. Padrão: 45.",
                        "default": 45,
                    },
                },
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "query_project_scope",
            "description": (
                "Busca informações sobre serviços, destinos, documentação, FAQ, regras de "
                "atendimento e processos da Cadife Tour na base de conhecimento. "
                "Use sempre que o cliente perguntar sobre a agência, passaporte, visto, "
                "tipos de viagem ou dúvidas gerais sobre o serviço."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Pergunta ou tópico a buscar. Seja específico.",
                    }
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "check_existing_lead",
            "description": (
                "Verifica se um cliente já existe no sistema pelo número de telefone. "
                "Retorna nome, status atual e score (quente/morno/frio) se existir. "
                "Use no início da conversa para personalizar a saudação e o atendimento."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "phone": {
                        "type": "string",
                        "description": "Número de telefone do cliente em formato internacional (ex: 5511999999999).",
                    }
                },
                "required": ["phone"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "persist_lead_data",
            "description": (
                "Salva ou atualiza dados do briefing do cliente no CRM. "
                "Use ao confirmar informações chave: destino, datas, número de pessoas, orçamento. "
                "Não use para dados incertos — só persista o que o cliente confirmou explicitamente."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "phone": {
                        "type": "string",
                        "description": "Número de telefone do cliente.",
                    },
                    "data": {
                        "type": "object",
                        "description": "Campos do briefing a atualizar (apenas campos listados abaixo são aceitos).",
                        "properties": {
                            "destino": {"type": "string", "description": "Cidade, país ou região de destino."},
                            "data_ida": {"type": "string", "description": "Data de ida no formato YYYY-MM-DD."},
                            "data_volta": {"type": "string", "description": "Data de volta no formato YYYY-MM-DD."},
                            "qtd_pessoas": {"type": "integer", "description": "Número total de viajantes."},
                            "perfil": {
                                "type": "string",
                                "enum": ["casal", "familia", "solo", "grupo", "amigos"],
                                "description": "Perfil do grupo viajante.",
                            },
                            "orcamento": {
                                "type": "string",
                                "enum": ["baixo", "medio", "alto", "premium"],
                                "description": "Nível de orçamento do cliente.",
                            },
                            "tem_passaporte": {"type": "boolean", "description": "Cliente possui passaporte válido."},
                            "observacoes": {"type": "string", "description": "Notas adicionais ou pedidos especiais."},
                        },
                        "additionalProperties": False,
                    },
                },
                "required": ["phone", "data"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "generate_travel_image",
            "description": (
                "Gera uma imagem inspiracional do destino de viagem usando IA (recraft-v4). "
                "Use ao final do briefing para encantar o cliente com uma prévia visual da experiência. "
                "Retorna URL da imagem gerada para compartilhar no WhatsApp."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "destino": {
                        "type": "string",
                        "description": "Destino da viagem (ex: Lisboa, Portugal; Cancún, México).",
                    },
                    "perfil": {
                        "type": "string",
                        "description": "Perfil do viajante: casal, família, solo, grupo, amigos.",
                    },
                    "estilo": {
                        "type": "string",
                        "description": "Estilo da imagem: luxo, aventura, romântico, família, cultural.",
                        "default": "luxo",
                    },
                },
                "required": ["destino"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "query_published_offers",
            "description": (
                "Busca ofertas de viagem publicadas na vitrine da Cadife. "
                "Retorna: título, destino, preço final, duração e destaques. "
                "Use para sugerir pacotes prontos quando o perfil do cliente bater "
                "com alguma oferta ativa ou quando ele pedir sugestões de pacotes econômicos."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "destination": {
                        "type": "string",
                        "description": "Cidade ou país para filtrar (opcional).",
                    },
                    "max_price": {
                        "type": "number",
                        "description": "Preço máximo em BRL (opcional).",
                    }
                },
                "required": [],
            },
        },
    },
]


# ── Tool Implementations ──────────────────────────────────────────────────────


async def _get_lead_context_by_wa_id(
    wa_id: str, db: Optional[AsyncSession]
) -> str:
    """
    Consulta PostgreSQL pelo wa_id (= número de telefone WhatsApp).
    Retorna status do lead, campos do briefing preenchidos e histórico recente.
    """
    if not db:
        return json.dumps({"exists": False, "reason": "db_unavailable"})
    try:
        from app.infrastructure.persistence.repositories.lead_repository import (
            LeadRepository,
        )
        from app.infrastructure.persistence.repositories.briefing_repository import (
            BriefingRepository,
        )
        from app.services import lead_service

        repo = LeadRepository(db)
        lead = await repo.get_by_phone(wa_id)

        if not lead:
            return json.dumps({"exists": False, "is_new_lead": True})

        # Briefing fields
        briefing_data: dict[str, Any] = {}
        try:
            b_repo = BriefingRepository(db)
            briefing = await b_repo.get_by_lead_id(lead.id)
            if briefing:
                briefing_data = {
                    "destino": briefing.destino,
                    "data_ida": str(briefing.data_ida) if briefing.data_ida else None,
                    "data_volta": str(briefing.data_volta) if briefing.data_volta else None,
                    "qtd_pessoas": briefing.qtd_pessoas,
                    "perfil": briefing.perfil.value if briefing.perfil else None,
                    "orcamento": briefing.orcamento.value if briefing.orcamento else None,
                    "tem_passaporte": briefing.tem_passaporte,
                    "completude_pct": getattr(briefing, "completude_pct", None),
                }
        except Exception as exc:
            logger.warning("briefing_lookup_failed", wa_id=wa_id, error=str(exc))

        # Últimas 5 interações para contexto
        interacoes = await lead_service.get_recent_interacoes(db, lead.id, limit=5)
        history = [
            {
                "from": "cliente" if row.get("mensagem_cliente") else "aya",
                "text": row.get("mensagem_cliente") or row.get("mensagem_ia", ""),
            }
            for row in interacoes
            if row.get("mensagem_cliente") or row.get("mensagem_ia")
        ]

        return json.dumps(
            {
                "exists": True,
                "is_new_lead": False,
                "lead_id": str(lead.id),
                "nome": lead.nome,
                "status": lead.status.value if lead.status else None,
                "score": lead.score.value if lead.score else None,
                "briefing": briefing_data,
                "recent_history": history,
            }
        )
    except Exception as exc:
        logger.error("tool_get_lead_context_failed", wa_id=wa_id, error=str(exc))
        return json.dumps({"exists": False, "error": "crm_lookup_failed"})


async def _check_availability(args: dict[str, Any]) -> str:
    """
    Placeholder para integração com Google Calendar.
    Retorna slots simulados até GOOGLE_CALENDAR_CREDENTIALS estiver configurado.

    TODO: substituir pela chamada real à Google Calendar API quando
    as credenciais estiverem disponíveis em settings.GOOGLE_CALENDAR_CREDENTIALS.
    """
    from datetime import datetime, timedelta

    duration = int(args.get("duration_minutes", 45))
    preferred_date_str: Optional[str] = args.get("preferred_date")

    # Gera até 3 slots em dias úteis a partir de amanhã (ou da data preferida)
    try:
        base = (
            datetime.strptime(preferred_date_str, "%Y-%m-%d")
            if preferred_date_str
            else datetime.now()
        )
    except ValueError:
        base = datetime.now()

    slots = []
    day_offset = 1
    while len(slots) < 3 and day_offset <= 14:
        candidate = base + timedelta(days=day_offset)
        day_offset += 1
        if candidate.weekday() > 4:  # pula fim de semana
            continue
        for hour in [9, 11, 14, 16]:
            slot_dt = candidate.replace(hour=hour, minute=0, second=0, microsecond=0)
            slots.append(
                {
                    "datetime": slot_dt.strftime("%Y-%m-%d %H:%M"),
                    "duration_minutes": duration,
                    "available": True,
                }
            )
            if len(slots) >= 3:
                break

    return json.dumps(
        {
            "status": "placeholder",
            "note": (
                "Integração Google Calendar pendente. "
                "Slots simulados para dias úteis (09h–16h, Seg–Sex)."
            ),
            "slots": slots,
        }
    )


async def _query_project_scope(query: str) -> str:
    try:
        context = rag_service.retrieve_context(query, k=3)
        return (
            context if context else "Informação não encontrada na base de conhecimento."
        )
    except Exception as exc:
        logger.error("tool_query_project_scope_failed", error=str(exc))
        return "Erro ao consultar a base de conhecimento."


async def _check_existing_lead(phone: str, db: Optional[AsyncSession]) -> str:
    if not db:
        return json.dumps({"exists": False, "reason": "db_unavailable"})
    try:
        from app.infrastructure.persistence.repositories.lead_repository import (
            LeadRepository,
        )

        repo = LeadRepository(db)
        lead = await repo.get_by_phone(phone)
        if lead:
            return json.dumps(
                {
                    "exists": True,
                    "name": lead.nome,
                    "status": lead.status.value if lead.status else None,
                    "score": lead.score.value if lead.score else None,
                    "lead_id": str(lead.id),
                }
            )
        return json.dumps({"exists": False})
    except Exception as exc:
        logger.error("tool_check_existing_lead_failed", error=str(exc))
        return json.dumps({"exists": False, "error": "lookup_failed"})


# Campos permitidos na tool persist_lead_data — defesa em profundidade
_ALLOWED_PERSIST_FIELDS: frozenset[str] = frozenset({
    "destino", "data_ida", "data_volta", "qtd_pessoas",
    "perfil", "orcamento", "tem_passaporte", "observacoes",
})

# Comprimento máximo para campos de texto livre (defesa contra context stuffing)
_MAX_FIELD_LENGTH = 500


async def _persist_lead_data(
    phone: str,
    data: dict[str, Any],
    db: Optional[AsyncSession],
) -> str:
    if not db:
        return json.dumps({"success": False, "reason": "db_unavailable"})
    try:
        from app.services.lead_service import upsert_lead_with_resilience
        from app.presentation.schemas.briefing_schema import BriefingExtracted

        # Whitelist: remove campos não reconhecidos antes de qualquer persistência
        sanitized: dict[str, Any] = {}
        for key, value in data.items():
            if key not in _ALLOWED_PERSIST_FIELDS:
                logger.warning("persist_unknown_field_blocked", field=key, phone=phone)
                continue
            # Trunca strings longas demais
            if isinstance(value, str) and len(value) > _MAX_FIELD_LENGTH:
                value = value[:_MAX_FIELD_LENGTH]
            sanitized[key] = value

        if not sanitized:
            return json.dumps({"success": False, "reason": "no_valid_fields"})

        lead = await upsert_lead_with_resilience(db, {"telefone": phone})

        from app.services.lead_service import update_briefing_from_extraction

        normalized = _normalize_briefing_enums(_normalize_date_fields(sanitized))
        briefing_in = BriefingExtracted.model_validate(normalized)
        briefing = await update_briefing_from_extraction(db, lead, briefing_in)

        scheduling_required = briefing.completude_pct >= 60
        return json.dumps(
            {
                "success": True,
                "lead_id": str(lead.id),
                "completude_pct": briefing.completude_pct,
                "next_step": "offer_scheduling" if scheduling_required else "continue_briefing",
                "instruction": (
                    "Briefing completo. Chame check_availability AGORA e convide o cliente para agendar a curadoria."
                    if scheduling_required
                    else None
                ),
            }
        )
    except Exception as exc:
        # Garante que a sessão volta a um estado limpo — evita PendingRollbackError
        # em chamadas subsequentes que compartilham o mesmo AsyncSession.
        try:
            await db.rollback()
        except Exception:
            pass
        logger.error("tool_persist_lead_data_failed", error=str(exc))
        return json.dumps({"success": False, "error": "persist_failed"})


_TRAVEL_IMAGE_STYLE_PROMPTS: dict[str, str] = {
    "luxo": "luxury travel photography, 5-star resort, golden hour lighting, cinematic",
    "aventura": "adventure travel photography, dramatic landscapes, natural light, epic",
    "romântico": "romantic couple travel, sunset, dreamy atmosphere, soft lighting",
    "família": "happy family vacation, bright colors, joyful, sunny day",
    "cultural": "cultural heritage travel, architectural beauty, warm tones, artistic",
}


async def _generate_travel_image(
    destino: str,
    perfil: Optional[str] = None,
    estilo: str = "luxo",
) -> str:
    """
    Gera imagem inspiracional do destino via recraft-v4 no OpenRouter.

    Usa /images/generations (compatível com OpenAI DALL-E API).
    Fallback gracioso se o modelo não estiver disponível no OpenRouter.
    """
    from app.infrastructure.config.settings import get_settings
    settings = get_settings()

    if not settings.OPENROUTER_API_KEY:
        return json.dumps({"success": False, "reason": "api_key_not_configured"})

    style_suffix = _TRAVEL_IMAGE_STYLE_PROMPTS.get(estilo, _TRAVEL_IMAGE_STYLE_PROMPTS["luxo"])
    perfil_hint = f", {perfil} travel" if perfil and perfil not in ("solo",) else ""
    prompt = (
        f"Beautiful travel destination {destino}{perfil_hint}, "
        f"{style_suffix}, travel agency promotional image, high quality"
    )

    payload = {
        "model": settings.OPENROUTER_IMAGE_GEN_MODEL,
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024",
    }
    auth_headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        **_OPENROUTER_HEADERS,
    }

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            resp = await client.post(
                f"{_OPENROUTER_BASE}/images/generations",
                json=payload,
                headers=auth_headers,
            )
            resp.raise_for_status()
            data = resp.json()
            image_url = data["data"][0].get("url", "")

        logger.info(
            "travel_image_generated",
            destino=destino,
            estilo=estilo,
            model=settings.OPENROUTER_IMAGE_GEN_MODEL,
        )
        return json.dumps(
            {
                "success": True,
                "url": image_url,
                "destino": destino,
                "message": (
                    f"Imagem inspiracional de {destino} gerada com sucesso! "
                    "Compartilhe este link com o cliente para despertar o interesse."
                ),
            }
        )
    except httpx.HTTPStatusError as exc:
        logger.warning(
            "travel_image_generation_failed",
            destino=destino,
            model=settings.OPENROUTER_IMAGE_GEN_MODEL,
            status=exc.response.status_code,
            body=exc.response.text[:200],
        )
        return json.dumps(
            {
                "success": False,
                "reason": "image_generation_unavailable",
                "instruction": (
                    "Modelo de imagem indisponível. Continue o atendimento normalmente "
                    "e ofereça o agendamento da curadoria."
                ),
            }
        )
    except Exception as exc:
        logger.error("travel_image_unexpected_error", destino=destino, error=str(exc))
        return json.dumps({"success": False, "reason": "unexpected_error"})


async def _query_published_offers(
    db: Optional[AsyncSession],
    destination: Optional[str] = None,
    max_price: Optional[float] = None,
) -> str:
    if not db:
        return json.dumps({"success": False, "reason": "db_unavailable"})
    try:
        from app.services.offer_service import list_offers
        
        offers, total = await list_offers(
            db,
            destination=destination,
            max_price=max_price,
            limit=5
        )
        
        if not offers:
            return "Nenhuma oferta publicada encontrada para estes filtros."
            
        result = []
        for o in offers:
            result.append({
                "id": str(o.id),
                "titulo": o.title,
                "destino": o.destination,
                "preco": float(o.final_price),
                "moeda": o.currency,
                "duracao": f"{o.duration_days} dias",
                "saida": o.departure_date.strftime("%d/%m/%Y"),
                "destaques": o.highlights[:3]
            })
            
        return json.dumps({"success": True, "total": total, "offers": result}, ensure_ascii=False)
    except Exception as exc:
        logger.error("tool_query_offers_failed", error=str(exc))
        return json.dumps({"success": False, "error": "offers_lookup_failed"})


# ── Dispatcher ────────────────────────────────────────────────────────────────


async def execute_tool(
    tool_name: str,
    tool_args: dict[str, Any],
    db: Optional[AsyncSession] = None,
) -> str:
    """Dispatch a tool call by name and return its result as a string.

    Called by the AI layer after the model returns a tool_calls response,
    before sending the tool result back for the next completion turn.
    """
    logger.info("tool_dispatch", tool=tool_name, arg_keys=list(tool_args.keys()))

    if tool_name == "get_lead_context_by_wa_id":
        return await _get_lead_context_by_wa_id(tool_args["wa_id"], db)

    if tool_name == "check_availability":
        return await _check_availability(tool_args)

    if tool_name == "query_project_scope":
        return await _query_project_scope(tool_args["query"])

    if tool_name == "check_existing_lead":
        return await _check_existing_lead(tool_args["phone"], db)

    if tool_name == "persist_lead_data":
        return await _persist_lead_data(tool_args["phone"], tool_args["data"], db)

    if tool_name == "generate_travel_image":
        return await _generate_travel_image(
            destino=tool_args["destino"],
            perfil=tool_args.get("perfil"),
            estilo=tool_args.get("estilo", "luxo"),
        )

    if tool_name == "query_published_offers":
        return await _query_published_offers(
            db,
            destination=tool_args.get("destination"),
            max_price=tool_args.get("max_price"),
        )

    logger.warning("tool_unknown", tool=tool_name)
    return json.dumps({"error": f"Tool '{tool_name}' not implemented."})
