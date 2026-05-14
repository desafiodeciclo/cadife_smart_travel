"""
Google Calendar Service — Infrastructure/Adapters Layer
========================================================
Cria eventos de curadoria no Google Calendar com link Google Meet.
Usa service account configurada em GOOGLE_SERVICE_ACCOUNT_PATH.

Degradação graciosa: se as credenciais não estiverem configuradas,
retorna None sem lançar exceção — o agendamento é criado sem Meet link.
"""

from __future__ import annotations

import asyncio
import uuid
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, time, timedelta
from typing import Optional

import structlog

logger = structlog.get_logger()

# calendar.events é suficiente — evita acesso à configuração do calendário
_CALENDAR_SCOPES = ["https://www.googleapis.com/auth/calendar.events"]

_TZ_SAO_PAULO = "America/Sao_Paulo"

# Pool dedicado e limitado para chamadas síncronas à Google Calendar API.
# Evita saturar o ThreadPoolExecutor padrão do asyncio sob alta carga de agendamentos.
_CALENDAR_EXECUTOR = ThreadPoolExecutor(max_workers=4, thread_name_prefix="gcal")


def _build_service():
    """Constrói o cliente Google Calendar API autenticado via service account."""
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()
    path = settings.GOOGLE_SERVICE_ACCOUNT_PATH

    from pathlib import Path

    if not Path(path).exists():
        logger.warning(
            "google_service_account_not_found",
            path=path,
            note="Google Meet links desativados. Configure GOOGLE_SERVICE_ACCOUNT_PATH.",
        )
        return None

    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build

        creds = service_account.Credentials.from_service_account_file(
            path, scopes=_CALENDAR_SCOPES
        )

        if settings.GOOGLE_CALENDAR_DELEGATE_EMAIL:
            creds = creds.with_subject(settings.GOOGLE_CALENDAR_DELEGATE_EMAIL)

        return build("calendar", "v3", credentials=creds, cache_discovery=False)
    except Exception as exc:
        logger.error("google_calendar_build_failed", error=str(exc))
        return None


def _localizar_datetime(data: date, hora: time) -> datetime:
    """Combina data e hora no timezone de São Paulo (lida com horário de verão)."""
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(_TZ_SAO_PAULO)
    except ImportError:
        # Python < 3.9 — fallback com pytz se disponível, senão offset fixo
        try:
            import pytz
            tz = pytz.timezone(_TZ_SAO_PAULO)
            return tz.localize(datetime.combine(data, hora))
        except ImportError:
            from datetime import timezone
            tz = timezone(timedelta(hours=-3))
            return datetime.combine(data, hora).replace(tzinfo=tz)
    return datetime.combine(data, hora, tzinfo=tz)


async def criar_evento_curadoria(
    lead_nome: Optional[str],
    data: date,
    hora: time,
    duracao_minutos: int = 60,
) -> tuple[Optional[str], Optional[str]]:
    """
    Cria evento no Google Calendar com conferência Google Meet.

    Returns:
        Tupla (meet_link, google_event_id). Ambos None se indisponível.
    """
    return await asyncio.get_running_loop().run_in_executor(
        _CALENDAR_EXECUTOR,
        _criar_evento_sync,
        lead_nome,
        data,
        hora,
        duracao_minutos,
    )


def _criar_evento_sync(
    lead_nome: Optional[str],
    data: date,
    hora: time,
    duracao_minutos: int,
) -> tuple[Optional[str], Optional[str]]:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()
    service = _build_service()
    if not service:
        return None, None

    inicio = _localizar_datetime(data, hora)
    fim = inicio + timedelta(minutes=duracao_minutos)

    nome_display = lead_nome or "Cliente"
    event_body = {
        "summary": f"Curadoria Cadife Tour — {nome_display}",
        "description": (
            "Sessão de curadoria personalizada com consultor Cadife Tour.\n"
            f"Cliente: {nome_display}"
        ),
        "start": {"dateTime": inicio.isoformat(), "timeZone": _TZ_SAO_PAULO},
        "end": {"dateTime": fim.isoformat(), "timeZone": _TZ_SAO_PAULO},
        "conferenceData": {
            "createRequest": {
                "requestId": str(uuid.uuid4()),
                "conferenceSolutionKey": {"type": "hangoutsMeet"},
            }
        },
        "reminders": {
            "useDefault": False,
            "overrides": [
                {"method": "email", "minutes": 60},
                {"method": "popup", "minutes": 15},
            ],
        },
    }

    try:
        created = (
            service.events()
            .insert(
                calendarId=settings.GOOGLE_CALENDAR_ID,
                body=event_body,
                conferenceDataVersion=1,
                # Notifica o consultor (calendário interno), não o cliente externo
                sendUpdates="externalOnly",
            )
            .execute()
        )
        meet_link: Optional[str] = created.get("hangoutLink")
        event_id: Optional[str] = created.get("id")
        logger.info(
            "google_meet_event_created",
            event_id=event_id,
            meet_link=meet_link,
            data=str(data),
            hora=str(hora),
        )
        return meet_link, event_id
    except Exception as exc:
        logger.error("google_calendar_event_failed", error=str(exc))
        return None, None


async def cancelar_evento_curadoria(google_event_id: str) -> bool:
    """
    Cancela (exclui) o evento do Google Calendar ao cancelar agendamento.

    Returns:
        True se cancelado com sucesso, False caso contrário.
    """
    return await asyncio.get_running_loop().run_in_executor(
        _CALENDAR_EXECUTOR,
        _cancelar_evento_sync,
        google_event_id,
    )


def _cancelar_evento_sync(google_event_id: str) -> bool:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()
    service = _build_service()
    if not service:
        return False

    try:
        service.events().delete(
            calendarId=settings.GOOGLE_CALENDAR_ID,
            eventId=google_event_id,
            sendUpdates="externalOnly",
        ).execute()
        logger.info("google_calendar_event_cancelled", event_id=google_event_id)
        return True
    except Exception as exc:
        logger.error("google_calendar_cancel_failed", event_id=google_event_id, error=str(exc))
        return False


async def verificar_disponibilidade_calendar(
    data: date,
    hora: time,
    duracao_minutos: int = 60,
) -> bool:
    """
    Consulta o Google Calendar (freebusy) para verificar se o slot está livre.

    Returns:
        True se livre, False se ocupado ou se o Calendar não estiver configurado.
        Na ausência de credenciais retorna True (degrada graciosamente —
        a validação de conflito do banco continua ativa).
    """
    import asyncio

    return await asyncio.get_event_loop().run_in_executor(
        None,
        _verificar_disponibilidade_sync,
        data,
        hora,
        duracao_minutos,
    )


def _verificar_disponibilidade_sync(
    data: date,
    hora: time,
    duracao_minutos: int,
) -> bool:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()
    service = _build_service()
    if not service:
        # Sem Calendar configurado: degrada graciosamente — não bloqueia agendamento
        return True

    inicio = _localizar_datetime(data, hora)
    fim = inicio + timedelta(minutes=duracao_minutos)

    try:
        body = {
            "timeMin": inicio.isoformat(),
            "timeMax": fim.isoformat(),
            "items": [{"id": settings.GOOGLE_CALENDAR_ID}],
        }
        result = service.freebusy().query(body=body).execute()
        busy_slots = result["calendars"][settings.GOOGLE_CALENDAR_ID]["busy"]
        disponivel = len(busy_slots) == 0
        logger.info(
            "google_calendar_freebusy_checked",
            data=str(data),
            hora=str(hora),
            disponivel=disponivel,
            busy_count=len(busy_slots),
        )
        return disponivel
    except Exception as exc:
        logger.error("google_calendar_freebusy_failed", error=str(exc))
        # Em caso de erro na API, não bloqueia — o banco garante unicidade
        return True
