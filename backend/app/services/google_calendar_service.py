"""
Google Calendar Service — Services Layer
=========================================
Abstrai as chamadas à API do Google Calendar usando a Conta de Serviço configurada.

As chamadas à SDK oficial do Google são síncronas. Para não bloquear o event loop
do FastAPI, os métodos síncronos são expostos via wrappers assíncronos que utilizam
run_in_executor, delegando a execução para a thread pool padrão do asyncio.

Pré-requisitos:
  - Arquivo JSON de credenciais da conta de serviço em GOOGLE_CALENDAR_CREDENTIALS
  - Agenda compartilhada com o e-mail da conta de serviço (permissão "Make changes to events")
  - Variáveis GOOGLE_CALENDAR_CREDENTIALS e GOOGLE_CALENDAR_ID definidas no .env
"""

import asyncio
import datetime
import os
import uuid
from typing import Any, Dict, List

import structlog
from google.oauth2 import service_account
from googleapiclient.discovery import build

from app.infrastructure.config.settings import get_settings

logger = structlog.get_logger()

_CALENDAR_SCOPES = ["https://www.googleapis.com/auth/calendar"]


class GoogleCalendarService:
    """Serviço de integração com Google Calendar via Conta de Serviço."""

    @classmethod
    def _get_credentials(cls) -> service_account.Credentials:
        settings = get_settings()
        creds_path = settings.GOOGLE_CALENDAR_CREDENTIALS

        if not os.path.exists(creds_path):
            raise FileNotFoundError(
                f"Credenciais do Google Calendar não encontradas em: {creds_path}"
            )

        return service_account.Credentials.from_service_account_file(
            creds_path,
            scopes=_CALENDAR_SCOPES,
        )

    @classmethod
    def _build_service(cls):
        creds = cls._get_credentials()
        return build("calendar", "v3", credentials=creds, cache_discovery=False)

    # ── Métodos síncronos (thread-safe) ──────────────────────────────────────

    @classmethod
    def get_free_busy_slots(
        cls,
        start_time: datetime.datetime,
        end_time: datetime.datetime,
    ) -> List[Dict[str, Any]]:
        """
        Consulta a API FreeBusy do Google Calendar para a agenda configurada.
        Retorna lista de intervalos ocupados: [{"start": "...", "end": "..."}].
        """
        settings = get_settings()
        service = cls._build_service()
        calendar_id = settings.GOOGLE_CALENDAR_ID

        body = {
            "timeMin": start_time.isoformat() + "Z",
            "timeMax": end_time.isoformat() + "Z",
            "timeZone": "America/Sao_Paulo",
            "items": [{"id": calendar_id}],
        }

        logger.info(
            "gcal_query_free_busy",
            calendar_id=calendar_id,
            start=str(start_time),
            end=str(end_time),
        )

        response = service.freebusy().query(body=body).execute()
        busy_slots: List[Dict[str, Any]] = (
            response.get("calendars", {})
            .get(calendar_id, {})
            .get("busy", [])
        )
        return busy_slots

    @classmethod
    def insert_curation_event(
        cls,
        lead_name: str,
        lead_phone: str,
        start_datetime: datetime.datetime,
        duration_minutes: int = 45,
    ) -> Dict[str, Any]:
        """
        Insere um agendamento de curadoria na agenda do Google com link do Google Meet.
        Retorna dict com event_id, meet_link e html_link.
        """
        settings = get_settings()
        service = cls._build_service()
        calendar_id = settings.GOOGLE_CALENDAR_ID

        end_datetime = start_datetime + datetime.timedelta(minutes=duration_minutes)

        event_body = {
            "summary": f"Curadoria Cadife - {lead_name}",
            "description": (
                f"Reunião de curadoria personalizada para planejamento de viagem.\n"
                f"Cliente: {lead_name}\n"
                f"Telefone: {lead_phone}\n\n"
                f"Agendado automaticamente via IA AYA."
            ),
            "start": {
                "dateTime": start_datetime.isoformat(),
                "timeZone": "America/Sao_Paulo",
            },
            "end": {
                "dateTime": end_datetime.isoformat(),
                "timeZone": "America/Sao_Paulo",
            },
            "conferenceData": {
                "createRequest": {
                    "requestId": f"curadoria-{uuid.uuid4().hex[:10]}",
                    "conferenceSolutionKey": {"type": "hangoutsMeet"},
                }
            },
        }

        logger.info(
            "gcal_insert_event_request",
            calendar_id=calendar_id,
            start=str(start_datetime),
            lead_name=lead_name,
        )

        try:
            event = (
                service.events()
                .insert(
                    calendarId=calendar_id,
                    body=event_body,
                    conferenceDataVersion=1,  # obrigatório para gerar o Google Meet
                )
                .execute()
            )
            meet_link: str = event.get("hangoutLink", "")
        except Exception as exc:
            logger.error(
                "gcal_conference_creation_failed",
                calendar_id=calendar_id,
                error=str(exc),
                exc_info=True,
            )
            if "Invalid conference type value" in str(exc) or "invalidConferenceSource" in str(exc):
                logger.warning(
                    "gcal_conference_not_supported_falling_back",
                    calendar_id=calendar_id,
                    error=str(exc),
                )
                fallback_body = event_body.copy()
                fallback_body.pop("conferenceData", None)
                event = (
                    service.events()
                    .insert(
                        calendarId=calendar_id,
                        body=fallback_body,
                    )
                    .execute()
                )
                meet_link = "Disponibilizado no dia da reunião"
            else:
                raise exc

        logger.info(
            "gcal_event_created_successfully",
            event_id=event.get("id"),
            meet_link=meet_link,
        )

        return {
            "event_id": event.get("id"),
            "meet_link": meet_link,
            "html_link": event.get("htmlLink"),
        }

    # ── Wrappers assíncronos ──────────────────────────────────────────────────

    @classmethod
    async def get_free_busy_slots_async(
        cls,
        start_time: datetime.datetime,
        end_time: datetime.datetime,
    ) -> List[Dict[str, Any]]:
        """Versão assíncrona de get_free_busy_slots (run_in_executor)."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(
            None, cls.get_free_busy_slots, start_time, end_time
        )

    @classmethod
    async def insert_curation_event_async(
        cls,
        lead_name: str,
        lead_phone: str,
        start_datetime: datetime.datetime,
        duration_minutes: int = 45,
    ) -> Dict[str, Any]:
        """Versão assíncrona de insert_curation_event (run_in_executor)."""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(
            None,
            cls.insert_curation_event,
            lead_name,
            lead_phone,
            start_datetime,
            duration_minutes,
        )
