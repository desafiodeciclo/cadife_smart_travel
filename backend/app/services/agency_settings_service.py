"""
Agency Settings + Message Template service.

Provides:
  - get_or_create_settings(): returns the singleton settings row, seeding
    defaults on first call.
  - update_settings(): persists horario / notificacoes prefs and triggers
    cache invalidation for agenda disponibilidade.
  - list_active_templates() / create_template() / update_template() /
    soft_delete_template(): CRUD for message templates with placeholder
    whitelist enforcement (already validated by Pydantic schemas).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from typing import Optional

import structlog
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.infrastructure.persistence.models.agency_settings_model import (
    AgencySettingsModel,
    MessageTemplateModel,
    SINGLETON_AGENCY_ID,
)
from app.presentation.schemas.agency_settings_schema import (
    AgencySettingsUpdateRequest,
    HorarioFuncionamento,
    MessageTemplateCreate,
    MessageTemplateUpdate,
    NotificacoesPrefs,
)

logger = structlog.get_logger()


DEFAULT_HORARIO = {
    "dias": [1, 2, 3, 4, 5],
    "inicio": "09:00",
    "fim": "16:00",
}
DEFAULT_NOTIFICACOES = {
    "leads_qualificados": True,
    "novos_leads": True,
    "propostas_aprovadas": True,
    "agendamentos_confirmados": True,
}


# ── Settings ────────────────────────────────────────────────────────────────


async def get_or_create_settings(
    db: AsyncSession, agency_id: uuid.UUID = SINGLETON_AGENCY_ID
) -> AgencySettingsModel:
    """Returns the settings row for an agency, creating a default one if missing."""
    stmt = select(AgencySettingsModel).where(AgencySettingsModel.agency_id == agency_id)
    settings = (await db.execute(stmt)).scalar_one_or_none()
    if settings:
        return settings

    settings = AgencySettingsModel(
        agency_id=agency_id,
        horario_funcionamento=DEFAULT_HORARIO,
        notificacoes_prefs=DEFAULT_NOTIFICACOES,
    )
    db.add(settings)
    await db.commit()
    await db.refresh(settings)
    logger.info(
        "agency_settings_created_default", agency_id=str(agency_id)
    )
    return settings


async def update_settings(
    db: AsyncSession,
    payload: AgencySettingsUpdateRequest,
    updated_by: uuid.UUID,
    agency_id: uuid.UUID = SINGLETON_AGENCY_ID,
) -> AgencySettingsModel:
    """Updates settings; caller is responsible for cache invalidation."""
    settings = await get_or_create_settings(db, agency_id)

    if payload.horario_funcionamento is not None:
        settings.horario_funcionamento = payload.horario_funcionamento.model_dump()
    if payload.notificacoes_prefs is not None:
        settings.notificacoes_prefs = payload.notificacoes_prefs.model_dump()
    settings.updated_at = datetime.now(timezone.utc)
    settings.updated_by = updated_by

    await db.commit()
    await db.refresh(settings)
    logger.info(
        "agency_settings_updated",
        agency_id=str(agency_id),
        updated_by=str(updated_by),
        changed_horario=payload.horario_funcionamento is not None,
        changed_notificacoes=payload.notificacoes_prefs is not None,
    )
    return settings


# ── Message Templates ───────────────────────────────────────────────────────


async def list_active_templates(
    db: AsyncSession, agency_id: uuid.UUID = SINGLETON_AGENCY_ID
) -> list[MessageTemplateModel]:
    stmt = (
        select(MessageTemplateModel)
        .where(
            MessageTemplateModel.agency_id == agency_id,
            MessageTemplateModel.deletado_em.is_(None),
        )
        .order_by(MessageTemplateModel.categoria, MessageTemplateModel.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def get_template_by_id(
    db: AsyncSession, template_id: uuid.UUID
) -> Optional[MessageTemplateModel]:
    stmt = select(MessageTemplateModel).where(
        MessageTemplateModel.id == template_id,
        MessageTemplateModel.deletado_em.is_(None),
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def create_template(
    db: AsyncSession,
    payload: MessageTemplateCreate,
    created_by: uuid.UUID,
    agency_id: uuid.UUID = SINGLETON_AGENCY_ID,
) -> MessageTemplateModel:
    template = MessageTemplateModel(
        agency_id=agency_id,
        nome=payload.nome,
        categoria=payload.categoria,
        conteudo=payload.conteudo,
        variaveis=payload.variaveis,
        ativo=True,
        created_by=created_by,
    )
    db.add(template)
    await db.commit()
    await db.refresh(template)
    logger.info(
        "template_created",
        template_id=str(template.id),
        categoria=payload.categoria,
        created_by=str(created_by),
    )
    return template


async def update_template(
    db: AsyncSession,
    template: MessageTemplateModel,
    payload: MessageTemplateUpdate,
) -> MessageTemplateModel:
    data = payload.model_dump(exclude_none=True)
    for field, value in data.items():
        setattr(template, field, value)
    await db.commit()
    await db.refresh(template)
    logger.info(
        "template_updated", template_id=str(template.id), fields=list(data.keys())
    )
    return template


async def soft_delete_template(
    db: AsyncSession, template: MessageTemplateModel, deleted_by: uuid.UUID
) -> None:
    template.deletado_em = datetime.now(timezone.utc)
    template.ativo = False
    await db.commit()
    logger.info(
        "template_deleted",
        template_id=str(template.id),
        deleted_by=str(deleted_by),
    )
