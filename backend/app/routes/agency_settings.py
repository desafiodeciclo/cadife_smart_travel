"""
Agency Settings + Templates routes (parity gap §3.7 / PRD).

Endpoints:
  GET    /agency/settings                           — load (auto-seeds default)
  PUT    /agency/settings                           — admin only
  POST   /agency/settings/templates                 — admin only
  PATCH  /agency/settings/templates/{id}            — admin only
  DELETE /agency/settings/templates/{id}            — admin only

Cache:
  - GET caches result in Redis (TTL 5min) under `agency:settings:default`.
  - PUT and template mutations invalidate that key + publish an event so
    `/agenda/disponibilidade` recalculates if its cache happens to be hot.
"""

from __future__ import annotations

import json
import uuid

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.infrastructure.persistence.models.agency_settings_model import (
    SINGLETON_AGENCY_ID,
)
from app.infrastructure.security.dependencies import RequiresRole
from app.models.user import User
from app.presentation.schemas.agency_settings_schema import (
    AgencySettingsResponse,
    AgencySettingsUpdateRequest,
    HorarioFuncionamento,
    MessageTemplateCreate,
    MessageTemplateDTO,
    MessageTemplateUpdate,
    NotificacoesPrefs,
)
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services import agency_settings_service

logger = structlog.get_logger()
router = APIRouter(
    prefix="/agency",
    tags=["Agency Settings"],
    dependencies=[Depends(RequiresRole("consultor", "admin"))],
)


_CACHE_KEY = "agency:settings:default"
_CACHE_TTL = 300  # 5 minutes


async def _try_redis():
    try:
        from app.infrastructure.cache.redis_client import get_redis

        return get_redis()
    except Exception:  # pragma: no cover
        return None


async def _build_response(db: AsyncSession) -> AgencySettingsResponse:
    settings = await agency_settings_service.get_or_create_settings(db)
    templates = await agency_settings_service.list_active_templates(db)
    return AgencySettingsResponse(
        horario_funcionamento=HorarioFuncionamento.model_validate(
            settings.horario_funcionamento
        ),
        notificacoes_prefs=NotificacoesPrefs.model_validate(
            settings.notificacoes_prefs
        ),
        templates=[MessageTemplateDTO.model_validate(t) for t in templates],
        updated_at=settings.updated_at,
    )


async def _invalidate_caches() -> None:
    """Drop settings cache and publish disponibilidade-invalidate event."""
    redis = await _try_redis()
    if redis is None:
        return
    try:
        await redis.delete(_CACHE_KEY)
        # Best-effort — agenda service listens for this; no-op if no subscriber.
        if hasattr(redis, "publish"):
            await redis.publish(
                "agenda:disponibilidade:invalidate", str(SINGLETON_AGENCY_ID)
            )
    except Exception as exc:  # pragma: no cover
        logger.warning("agency_settings_cache_invalidate_failed", error=str(exc))


def _require_admin(user: User) -> None:
    if str(user.perfil) != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="apenas_admin_pode_alterar_settings",
        )


# ── GET ────────────────────────────────────────────────────────────────────


@router.get(
    "/settings",
    response_model=AgencySettingsResponse,
    summary="Configurações da agência (singleton)",
    description=(
        "Retorna horário de atendimento, preferências de notificação e templates ativos. "
        "Cache Redis 5min; criado automaticamente com defaults da spec §8.1 se ainda não existir."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
    },
)
async def get_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgencySettingsResponse:
    redis = await _try_redis()
    if redis is not None:
        try:
            cached = await redis.get(_CACHE_KEY)
            if cached:
                return AgencySettingsResponse.model_validate(json.loads(cached))
        except Exception as exc:  # pragma: no cover
            logger.warning("agency_settings_cache_read_failed", error=str(exc))

    response = await _build_response(db)

    if redis is not None:
        try:
            await redis.setex(_CACHE_KEY, _CACHE_TTL, response.model_dump_json())
        except Exception as exc:  # pragma: no cover
            logger.warning("agency_settings_cache_write_failed", error=str(exc))
    return response


# ── PUT ────────────────────────────────────────────────────────────────────


@router.put(
    "/settings",
    response_model=AgencySettingsResponse,
    summary="Atualizar configurações da agência",
    description=(
        "Atualiza horário e/ou preferências de notificação. Apenas admin. "
        "Invalida cache e dispara recálculo de /agenda/disponibilidade."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Apenas admin", "model": HTTPErrorResponse},
        422: {"description": "Horário inválido", "model": HTTPErrorResponse},
    },
)
async def update_settings(
    payload: AgencySettingsUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AgencySettingsResponse:
    _require_admin(current_user)
    await agency_settings_service.update_settings(
        db, payload, updated_by=current_user.id
    )
    await _invalidate_caches()
    return await _build_response(db)


# ── Templates ──────────────────────────────────────────────────────────────


@router.post(
    "/settings/templates",
    response_model=MessageTemplateDTO,
    status_code=status.HTTP_201_CREATED,
    summary="Criar template de mensagem",
    description=(
        "Cria template com placeholders validados contra whitelist "
        "{nome, destino, data_ida, data_volta, consultor_nome, agency_nome}."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Apenas admin", "model": HTTPErrorResponse},
        422: {"description": "Placeholders ou variaveis inválidos", "model": HTTPErrorResponse},
    },
)
async def create_template(
    payload: MessageTemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageTemplateDTO:
    _require_admin(current_user)
    template = await agency_settings_service.create_template(
        db, payload, created_by=current_user.id
    )
    await _invalidate_caches()
    return MessageTemplateDTO.model_validate(template)


@router.patch(
    "/settings/templates/{template_id}",
    response_model=MessageTemplateDTO,
    summary="Atualizar template (parcial)",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Apenas admin", "model": HTTPErrorResponse},
        404: {"description": "Template não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Placeholders inválidos", "model": HTTPErrorResponse},
    },
)
async def update_template(
    template_id: uuid.UUID,
    payload: MessageTemplateUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageTemplateDTO:
    _require_admin(current_user)
    template = await agency_settings_service.get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(404, "template_not_found")
    template = await agency_settings_service.update_template(db, template, payload)
    await _invalidate_caches()
    return MessageTemplateDTO.model_validate(template)


@router.delete(
    "/settings/templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-delete de template",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Apenas admin", "model": HTTPErrorResponse},
        404: {"description": "Template não encontrado", "model": HTTPErrorResponse},
    },
)
async def delete_template(
    template_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_admin(current_user)
    template = await agency_settings_service.get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(404, "template_not_found")
    await agency_settings_service.soft_delete_template(
        db, template, deleted_by=current_user.id
    )
    await _invalidate_caches()
