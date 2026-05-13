"""
AI Tools — Services Layer
==========================
OpenAI-compatible tool definitions for function calling via OpenRouter.
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
from app.models.briefing import _PERFIL_ALIASES, _ORCAMENTO_ALIASES

logger = structlog.get_logger()

# Corrige DD/MMYYYY → DD/MM/YYYY (ex: "17/092027" → "17/09/2027")
_DATE_MISSING_SLASH_RE = re.compile(r'^(\d{1,2})/(\d{2})(\d{4})$')


def _normalize_date_str(value: Any) -> Any:
    """Tenta reparar strings de data malformadas antes da validação Pydantic."""
    if not isinstance(value, str):
        return value
    v = value.strip().replace(" ", "")
    v = _DATE_MISSING_SLASH_RE.sub(r'\1/\2/\3', v)
    for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"):
        try:
            return datetime.strptime(v, fmt).strftime("%Y-%m-%d")
        except ValueError:
            pass
    return value


def _normalize_date_fields(data: dict[str, Any]) -> dict[str, Any]:
    """Normaliza data_ida e data_volta antes da validação."""
    result = dict(data)
    for field in ("data_ida", "data_volta"):
        if field in result:
            result[field] = _normalize_date_str(result[field])
    return result


def _normalize_briefing_enums(data: dict[str, Any]) -> dict[str, Any]:
    """Corrige valores de enum enviados pela IA usando os aliases globais."""
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
                "Busca contexto completo do lead no CRM pelo WhatsApp ID (wa_id). "
                "Retorna: nome, status, score, briefing preenchido e histórico."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "wa_id": {"type": "string", "description": "WhatsApp ID (ex: 5511999999999)."}
                },
                "required": ["wa_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "check_availability",
            "description": "Verifica disponibilidade para agendamento de curadoria.",
            "parameters": {
                "type": "object",
                "properties": {
                    "preferred_date": {"type": "string", "description": "Data YYYY-MM-DD."},
                    "duration_minutes": {"type": "integer", "default": 45}
                },
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "query_project_scope",
            "description": "Busca informações na base de conhecimento (RAG).",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Pergunta específica do cliente."}
                },
                "required": ["query"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "persist_lead_data",
            "description": "Salva ou atualiza dados confirmados do briefing no CRM.",
            "parameters": {
                "type": "object",
                "properties": {
                    "phone": {"type": "string", "description": "Número de telefone."},
                    "data": {
                        "type": "object",
                        "description": "Campos do briefing (apenas campos listados abaixo).",
                        "properties": {
                            "destino": {"type": "string", "description": "Destino da viagem."},
                            "data_ida": {"type": "string", "description": "Data ida YYYY-MM-DD."},
                            "data_volta": {"type": "string", "description": "Data volta YYYY-MM-DD."},
                            "qtd_pessoas": {"type": "integer", "description": "Número de viajantes."},
                            "perfil": {
                                "type": "string",
                                "enum": ["casal", "família", "solo", "grupo", "amigos"]
                            },
                            "orcamento": {
                                "type": "string",
                                "enum": ["baixo", "médio", "alto", "premium"]
                            },
                            "tem_passaporte": {"type": "boolean"},
                            "observacoes": {"type": "string"},
                        },
                        "additionalProperties": False,
                    },
                },
                "required": ["phone", "data"],
            },
        },
    },
]

# ── Implementations ──────────────────────────────────────────────────────────

async def _get_lead_context_by_wa_id(wa_id: str, db: Optional[AsyncSession]) -> str:
    if not db: return json.dumps({"exists": False, "reason": "db_unavailable"})
    try:
        from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
        from app.infrastructure.persistence.repositories.briefing_repository import BriefingRepository
        from app.services import lead_service

        repo = LeadRepository(db)
        lead = await repo.get_by_phone(wa_id)
        if not lead: return json.dumps({"exists": False, "is_new_lead": True})

        b_repo = BriefingRepository(db)
        briefing = await b_repo.get_by_lead_id(lead.id)
        briefing_data = {
            "destino": briefing.destino,
            "data_ida": str(briefing.data_ida) if briefing.data_ida else None,
            "data_volta": str(briefing.data_volta) if briefing.data_volta else None,
            "completude_pct": getattr(briefing, "completude_pct", 0),
        } if briefing else {}

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

    try:
        base = (
            datetime.strptime(preferred_date_str, "%Y-%m-%d")
            if preferred_date_str
            else datetime.now()
        )
    except (ValueError, TypeError):
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
            slots.append({
                "datetime": slot_dt.strftime("%Y-%m-%d %H:%M"),
                "duration_minutes": duration,
                "available": True,
            })
            if len(slots) >= 3:
                break

    return json.dumps({
        "status": "placeholder",
        "note": "Integração Google Calendar pendente. Slots simulados.",
        "slots": slots,
    })


async def _query_project_scope(query: str) -> str:
    try:
        context = await rag_service.retrieve_context(query, k=3)
        return context if context else "Informação não encontrada na base de conhecimento."
    except Exception as exc:
        logger.error("tool_rag_failed", error=str(exc))
        return json.dumps({"error": "rag_lookup_failed"})


async def _persist_lead_data(phone: str, data: dict[str, Any], db: Optional[AsyncSession]) -> str:
    if not db: return json.dumps({"success": False, "reason": "db_unavailable"})
    try:
        from app.services.lead_service import upsert_lead_with_resilience, update_briefing_from_extraction
        from app.models.briefing import BriefingExtracted

        lead = await upsert_lead_with_resilience(db, {"telefone": phone})
        normalized = _normalize_briefing_enums(_normalize_date_fields(data))
        briefing_in = BriefingExtracted.model_validate(normalized)
        briefing = await update_briefing_from_extraction(db, lead, briefing_in)

        scheduling_ready = briefing.completude_pct >= 60
        return json.dumps({
            "success": True,
            "completude_pct": briefing.completude_pct,
            "next_step": "offer_scheduling" if scheduling_ready else "continue_briefing"
        })
    except Exception as exc:
        await db.rollback()
        logger.error("tool_persist_failed", error=str(exc))
        return json.dumps({"success": False, "error": str(exc)})

# ── Dispatcher ───────────────────────────────────────────────────────────────

async def execute_tool(tool_name: str, tool_args: dict[str, Any], db: Optional[AsyncSession] = None) -> str:
    logger.info("tool_dispatch", tool=tool_name)
    
    if tool_name == "get_lead_context_by_wa_id":
        return await _get_lead_context_by_wa_id(tool_args["wa_id"], db)
    
    if tool_name == "query_project_scope":
        return await _query_project_scope(tool_args["query"])

    if tool_name == "persist_lead_data":
        return await _persist_lead_data(tool_args["phone"], tool_args["data"], db)

    if tool_name == "check_availability":
        return await _check_availability(tool_args)
    
    return json.dumps({"error": f"Tool {tool_name} not implemented."})