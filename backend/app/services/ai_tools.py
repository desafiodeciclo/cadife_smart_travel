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
from typing import Any, Optional

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.services import rag_service

logger = structlog.get_logger()


# ── Tool Schemas (OpenAI function-calling format) ────────────────────────────

TOOL_SCHEMAS: list[dict[str, Any]] = [
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
                        "description": (
                            "Campos do briefing a atualizar. Campos suportados: "
                            "destino (str), data_ida (YYYY-MM-DD), data_volta (YYYY-MM-DD), "
                            "qtd_pessoas (int), perfil (casal|familia|solo|grupo|amigos), "
                            "orcamento (baixo|medio|alto|premium), tem_passaporte (bool), "
                            "observacoes (str)."
                        ),
                        "additionalProperties": True,
                    },
                },
                "required": ["phone", "data"],
            },
        },
    },
]


# ── Tool Implementations ──────────────────────────────────────────────────────


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


async def _persist_lead_data(
    phone: str,
    data: dict[str, Any],
    db: Optional[AsyncSession],
) -> str:
    if not db:
        return json.dumps({"success": False, "reason": "db_unavailable"})
    try:
        from app.services.lead_service import upsert_lead_with_resilience
        from app.models.briefing import BriefingExtracted

        lead = await upsert_lead_with_resilience(db, {"telefone": phone})

        from app.services.lead_service import update_briefing_from_extraction

        briefing_in = BriefingExtracted.model_validate(data)
        briefing = await update_briefing_from_extraction(db, lead, briefing_in)

        return json.dumps(
            {
                "success": True,
                "lead_id": str(lead.id),
                "completude_pct": briefing.completude_pct,
            }
        )
    except Exception as exc:
        logger.error("tool_persist_lead_data_failed", error=str(exc))
        return json.dumps({"success": False, "error": "persist_failed"})


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

    if tool_name == "query_project_scope":
        return await _query_project_scope(tool_args["query"])

    if tool_name == "check_existing_lead":
        return await _check_existing_lead(tool_args["phone"], db)

    if tool_name == "persist_lead_data":
        return await _persist_lead_data(tool_args["phone"], tool_args["data"], db)

    logger.warning("tool_unknown", tool=tool_name)
    return json.dumps({"error": f"Tool '{tool_name}' not implemented."})
