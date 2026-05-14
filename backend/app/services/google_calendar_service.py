"""
Google Calendar Service — Infrastructure/Adapters Layer
========================================================
Cria eventos de curadoria no Google Calendar com link Google Meet.
Usa service account configurada em GOOGLE_SERVICE_ACCOUNT_PATH.

Degradação graciosa: se as credenciais não estiverem configuradas,
retorna None sem lançar exceção — o agendamento é criado sem Meet link.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, time, timedelta, timezone
from typing import Optional

import structlog

logger = structlog.get_logger()

_CALENDAR_SCOPES = ["https://www.googleapis.com/auth/calendar"]


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


async def criar_evento_curadoria(
    lead_nome: Optional[str],
    data: date,
    hora: time,
    duracao_minutos: int = 60,
) -> Optional[str]:
    """
    Cria evento no Google Calendar com conferência Google Meet.

    Returns:
        URL do Google Meet (hangoutLink) ou None se indisponível.
    """
    import asyncio

    return await asyncio.get_event_loop().run_in_executor(
        None,
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
) -> Optional[str]:
    from app.infrastructure.config.settings import get_settings

    settings = get_settings()
    service = _build_service()
    if not service:
        return None

    tz_offset = timezone(timedelta(hours=-3))  # BRT (America/Sao_Paulo)
    inicio = datetime.combine(data, hora).replace(tzinfo=tz_offset)
    fim = inicio + timedelta(minutes=duracao_minutos)

    nome_display = lead_nome or "Cliente"
    event_body = {
        "summary": f"Curadoria Cadife Tour — {nome_display}",
        "description": (
            "Sessão de curadoria personalizada com consultor Cadife Tour.\n"
            f"Cliente: {nome_display}"
        ),
        "start": {"dateTime": inicio.isoformat(), "timeZone": "America/Sao_Paulo"},
        "end": {"dateTime": fim.isoformat(), "timeZone": "America/Sao_Paulo"},
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
                sendUpdates="none",
            )
            .execute()
        )
        meet_link: Optional[str] = created.get("hangoutLink")
        logger.info(
            "google_meet_event_created",
            event_id=created.get("id"),
            meet_link=meet_link,
            data=str(data),
            hora=str(hora),
        )
        return meet_link
    except Exception as exc:
        logger.error("google_calendar_event_failed", error=str(exc))
        return None
