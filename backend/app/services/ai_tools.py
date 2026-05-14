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

from app.models.briefing import _PERFIL_ALIASES, _ORCAMENTO_ALIASES

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
                "Retorna até 3 slots disponíveis nos próximos dias úteis consultando a agenda real. "
                "Use quando o briefing estiver completo (completude ≥ 60%) e for hora de "
                "oferecer agendamento ao cliente."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "preferred_date": {
                        "type": "string",
                        "description": "Data preferida pelo cliente no formato YYYY-MM-DD (opcional).",
                    },
                },
                "required": [],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "confirm_scheduling",
            "description": (
                "Confirma o agendamento de curadoria escolhido pelo cliente. "
                "Use SOMENTE quando o cliente tiver confirmado explicitamente um dos slots "
                "oferecidos pelo check_availability (ex: 'quero o dia 15 às 10h', 'opção 2'). "
                "Cria o agendamento no sistema, gera o link do Google Meet e retorna a mensagem "
                "de confirmação com o link para enviar ao cliente."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "wa_id": {
                        "type": "string",
                        "description": "WhatsApp ID do cliente (número em formato internacional sem '+').",
                    },
                    "data_curadoria": {
                        "type": "string",
                        "description": "Data confirmada no formato YYYY-MM-DD.",
                    },
                    "hora_curadoria": {
                        "type": "string",
                        "description": "Hora confirmada no formato HH:MM (ex: '09:00', '14:00').",
                    },
                },
                "required": ["wa_id", "data_curadoria", "hora_curadoria"],
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
                            "ocasiao": {
                                "type": "string",
                                "enum": [
                                    "lua_de_mel", "aniversario", "ferias", "negocios",
                                    "intercambio", "formatura", "familia", "outro",
                                ],
                                "description": "Ocasião especial da viagem — NUNCA inferir, apenas salvar o que o cliente informou explicitamente.",
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
                    "perfil": briefing.perfil,
                    "orcamento": briefing.orcamento,
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


async def _check_availability(args: dict[str, Any], db: Optional[Any]) -> str:
    """
    Consulta a agenda real (PostgreSQL) e retorna até 3 slots disponíveis.
    Se o DB não estiver disponível, gera slots conservadores sem verificar conflitos.
    """
    from datetime import date as _date, timedelta

    preferred_date_str: Optional[str] = args.get("preferred_date")

    if db is not None:
        # Caminho principal: consulta slots reais no banco de dados
        try:
            from app.services.curadoria_service import get_proximos_slots_disponiveis

            slots_raw = await get_proximos_slots_disponiveis(db, quantidade=3)
            slots = [
                {"date": str(s["data"]), "time": s["hora"], "available": True}
                for s in slots_raw
            ]
            return json.dumps({"status": "ok", "slots": slots})
        except Exception as exc:
            logger.error("check_availability_db_failed", error=str(exc))

    # Fallback sem DB: slots conservadores a partir de amanhã (ou data preferida)
    try:
        base = (
            _date.fromisoformat(preferred_date_str)
            if preferred_date_str
            else _date.today()
        )
    except ValueError:
        base = _date.today()

    slots = []
    offset = 1
    while len(slots) < 3 and offset <= 14:
        candidate = base + timedelta(days=offset)
        offset += 1
        if candidate.weekday() >= 5:
            continue
        for hour in ["09:00", "11:00", "14:00"]:
            slots.append({"date": str(candidate), "time": hour, "available": True})
            if len(slots) >= 3:
                break

    return json.dumps({"status": "fallback", "slots": slots})


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
    "perfil", "ocasiao", "orcamento", "tem_passaporte", "observacoes",
})

# Campos que devem ser salvos diretamente no Lead (não no Briefing)
_LEAD_DIRECT_FIELDS: frozenset[str] = frozenset({"nome"})

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
        from app.models.briefing import BriefingExtracted

        # Whitelist: separa campos do Lead dos campos do Briefing
        sanitized: dict[str, Any] = {}
        lead_updates: dict[str, Any] = {}
        for key, value in data.items():
            if key in _LEAD_DIRECT_FIELDS:
                if isinstance(value, str) and value.strip():
                    lead_updates[key] = value.strip()[:_MAX_FIELD_LENGTH]
                continue
            if key not in _ALLOWED_PERSIST_FIELDS:
                logger.warning("persist_unknown_field_blocked", field=key, phone=phone)
                continue
            # Trunca strings longas demais
            if isinstance(value, str) and len(value) > _MAX_FIELD_LENGTH:
                value = value[:_MAX_FIELD_LENGTH]
            sanitized[key] = value

        if not sanitized and not lead_updates:
            return json.dumps({"success": False, "reason": "no_valid_fields"})

        lead = await upsert_lead_with_resilience(db, {"telefone": phone})

        # Atualiza campos diretos do lead (ex: nome informado explicitamente pelo cliente)
        if lead_updates:
            for field, value in lead_updates.items():
                # Só atualiza se o campo ainda está vazio (não sobrescreve dados existentes)
                if not getattr(lead, field, None):
                    setattr(lead, field, value)
            await db.commit()
            await db.refresh(lead)
            logger.info("lead_direct_fields_updated", lead_id=str(lead.id), fields=list(lead_updates.keys()))

        if not sanitized:
            # Apenas campos diretos do lead foram atualizados (ex: somente nome)
            return json.dumps({"success": True, "lead_id": str(lead.id), "completude_pct": None})

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


async def _confirm_scheduling(
    wa_id: str,
    data_curadoria: str,
    hora_curadoria: str,
    db: Optional[Any],
) -> str:
    """
    Confirma o agendamento escolhido pelo cliente:
      1. Valida lead e slot
      2. Cria registro em agendamentos
      3. Gera link Google Meet via Google Calendar
      4. Persiste meet_link e atualiza status do lead para AGENDADO
    """
    if not db:
        return json.dumps({"success": False, "reason": "db_unavailable"})

    from datetime import date as _date, time as _time

    try:
        data_obj = _date.fromisoformat(data_curadoria)
        hora_parts = hora_curadoria.split(":")
        hora_obj = _time(int(hora_parts[0]), int(hora_parts[1]))
    except (ValueError, IndexError):
        return json.dumps({"success": False, "reason": "invalid_date_or_time"})

    try:
        from app.infrastructure.persistence.repositories.lead_repository import LeadRepository
        from app.domain.entities.enums import AgendamentoStatus, AgendamentoTipo, LeadStatus
        from app.models.agendamento import Agendamento
        from app.services import lead_service
        from app.services.curadoria_service import get_proximos_slots_disponiveis
        from app.services.google_calendar_service import criar_evento_curadoria
        from sqlalchemy.exc import IntegrityError

        repo = LeadRepository(db)
        lead = await repo.get_by_phone(wa_id)
        if not lead:
            return json.dumps({"success": False, "reason": "lead_not_found"})

        # Verifica se o slot ainda está disponível
        slots = await get_proximos_slots_disponiveis(db, quantidade=10)
        slot_ok = any(
            str(s["data"]) == data_curadoria and s["hora"] == hora_curadoria
            for s in slots
        )
        if not slot_ok:
            return json.dumps({
                "success": False,
                "reason": "slot_unavailable",
                "message": "Este horário não está mais disponível. Vou verificar outras opções para você.",
            })

        # Cria o agendamento
        agendamento = Agendamento(
            lead_id=lead.id,
            data=data_obj,
            hora=hora_obj,
            tipo=AgendamentoTipo.online,
        )
        db.add(agendamento)
        try:
            await db.commit()
            await db.refresh(agendamento)
        except IntegrityError:
            await db.rollback()
            return json.dumps({"success": False, "reason": "slot_conflict"})

        # Gera link Google Meet e persiste event_id para cancelamento futuro (best-effort)
        meet_link, google_event_id = await criar_evento_curadoria(
            lead_nome=lead.nome,
            data=data_obj,
            hora=hora_obj,
        )
        if meet_link or google_event_id:
            agendamento.meet_link = meet_link
            agendamento.google_event_id = google_event_id
            await db.commit()

        # Atualiza status do lead para AGENDADO
        await lead_service.update_lead_status(db, lead, LeadStatus.agendado)

        data_fmt = data_obj.strftime("%d/%m/%Y")
        hora_fmt = hora_curadoria

        if meet_link:
            mensagem = (
                f"Perfeito! Sua curadoria está confirmada para *{data_fmt} às {hora_fmt}*. 🎉\n\n"
                f"Aqui está o link da sua reunião Google Meet:\n{meet_link}\n\n"
                f"Nosso consultor estará esperando por você. Até lá! ✈️"
            )
        else:
            mensagem = (
                f"Perfeito! Sua curadoria está confirmada para *{data_fmt} às {hora_fmt}*. 🎉\n\n"
                f"Em breve você receberá o link da videoconferência por aqui. "
                f"Nosso consultor estará esperando por você. Até lá! ✈️"
            )

        logger.info(
            "scheduling_confirmed_via_tool",
            lead_id=str(lead.id),
            data=data_curadoria,
            hora=hora_curadoria,
            meet_link=meet_link,
            google_event_id=google_event_id,
        )

        # Publica evento Kafka para downstream (FCM ao consultor, analytics, CRM sync)
        try:
            from datetime import datetime, timezone as _tz
            from app.services.kafka_producer import produce as _kafka_produce, TOPICS
            await _kafka_produce(
                topic=TOPICS.AGENDAMENTOS_CONFIRMADOS,
                key=str(lead.id),
                value={
                    "agendamento_id": str(agendamento.id),
                    "lead_id": str(lead.id),
                    "lead_nome": lead.nome,
                    "phone": wa_id,
                    "data": data_curadoria,
                    "hora": hora_curadoria,
                    "meet_link": meet_link,
                    "google_event_id": google_event_id,
                    "timestamp": datetime.now(_tz.utc).isoformat(),
                },
            )
        except Exception as _kafka_exc:
            # Kafka nunca deve reverter uma confirmação já persistida no DB
            logger.warning("agendamento_kafka_publish_failed", error=str(_kafka_exc))

        return json.dumps({
            "success": True,
            "agendamento_id": str(agendamento.id),
            "meet_link": meet_link,
            "message": mensagem,
        })

    except Exception as exc:
        try:
            await db.rollback()
        except Exception:
            pass
        logger.error("confirm_scheduling_failed", wa_id=wa_id, error=str(exc))
        return json.dumps({"success": False, "reason": "unexpected_error"})


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
        return await _check_availability(tool_args, db)

    if tool_name == "confirm_scheduling":
        return await _confirm_scheduling(
            wa_id=tool_args["wa_id"],
            data_curadoria=tool_args["data_curadoria"],
            hora_curadoria=tool_args["hora_curadoria"],
            db=db,
        )

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

    logger.warning("tool_unknown", tool=tool_name)
    return json.dumps({"error": f"Tool '{tool_name}' not implemented."})
