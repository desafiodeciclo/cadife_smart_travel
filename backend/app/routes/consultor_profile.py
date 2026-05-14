"""
Consultor Profile routes — bio, photo, metrics, goals.

Implements PRD `docs/prd/PRD-agency-settings-and-consultor-profile.md` §3.2.

Endpoints:
  PATCH /users/me/bio                              — update bio (≤500 chars)
  PATCH /users/me/profile-photo                    — multipart upload, 512x512 resize
  GET   /users/me/metrics                          — KPI aggregation (cached)
  GET   /users/me/goals?months=N                   — list monthly targets
  PUT   /users/me/goals/{year}/{month}             — admin sets target

NOTE: handlers live under `/users/me/...` but are registered as a separate
router so they can be tested in isolation and rolled out independently from
the legacy `routes/auth.py`.
"""

from __future__ import annotations

import asyncio
import io
import uuid

import structlog
from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Path,
    Query,
    UploadFile,
    status,
)
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user, get_db
from app.infrastructure.security.dependencies import RequiresRole
from app.models.user import User
from app.presentation.schemas.user_schema import UserResponse
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.presentation.schemas.consultor_profile_schema import (
    BioUpdateRequest,
    ConsultorMetricsResponse,
    SaleGoalResponse,
    SaleGoalUpdateRequest,
    SaleGoalsListResponse,
)
from app.services import metrics_service, sale_goal_service, user_service

logger = structlog.get_logger()
router = APIRouter(
    prefix="/users",
    tags=["Consultor Profile"],
    dependencies=[Depends(RequiresRole("consultor", "admin", "agencia", "cliente"))],
)


MAX_PHOTO_BYTES = 5 * 1024 * 1024  # 5 MB


# ── Helpers ────────────────────────────────────────────────────────────────


def _resize_to_512(data: bytes) -> bytes:
    """Synchronous PIL resize. Called via asyncio.to_thread to keep loop free."""
    from PIL import Image  # lazy import — Pillow already in requirements

    with Image.open(io.BytesIO(data)) as img:
        img = img.convert("RGB")
        img.thumbnail((512, 512))
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=85, optimize=True)
        return buf.getvalue()


def _require_consultor_or_admin(user: User) -> None:
    if str(user.perfil) not in ("consultor", "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="endpoint_apenas_para_consultor_ou_admin",
        )


def _require_admin(user: User) -> None:
    if str(user.perfil) != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="apenas_admin"
        )


# ── Bio ────────────────────────────────────────────────────────────────────


@router.patch(
    "/me/bio",
    response_model=UserResponse,
    summary="Atualizar bio do consultor",
    description="Atualiza apenas o campo bio (≤500 chars; HTML é removido).",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        422: {"description": "Bio inválida", "model": HTTPErrorResponse},
    },
)
async def update_my_bio(
    payload: BioUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    _require_consultor_or_admin(current_user)
    updated = await user_service.update_bio(db, current_user, payload.bio)
    logger.info(
        "user_bio_updated",
        user_id=str(current_user.id),
        bio_len=len(payload.bio),
    )
    return UserResponse.model_validate(updated)


# ── Profile photo ──────────────────────────────────────────────────────────


@router.patch(
    "/me/profile-photo",
    response_model=UserResponse,
    summary="Upload de foto de perfil",
    description=(
        "Aceita multipart com arquivo de imagem (≤5MB). Imagem é redimensionada "
        "para 512×512 com aspect-fit antes de ir para o S3. Sobrescreve a foto anterior."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Sem permissão", "model": HTTPErrorResponse},
        413: {"description": "Arquivo maior que 5MB", "model": HTTPErrorResponse},
        415: {"description": "Tipo de arquivo não suportado", "model": HTTPErrorResponse},
        422: {"description": "Imagem corrompida", "model": HTTPErrorResponse},
    },
)
async def update_my_profile_photo(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserResponse:
    _require_consultor_or_admin(current_user)

    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="apenas_imagens_aceitas",
        )

    data = await file.read()
    if len(data) > MAX_PHOTO_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="arquivo_excede_5mb",
        )

    try:
        resized = await asyncio.to_thread(_resize_to_512, data)
    except Exception as exc:
        logger.warning(
            "profile_photo_resize_failed",
            user_id=str(current_user.id),
            error=str(exc),
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="imagem_invalida_ou_corrompida",
        )

    # Lazy import + lazy instantiate (avoids forcing aioboto3 in tests)
    from app.infrastructure.adapters.storage.s3_adapter import S3StorageAdapter

    s3 = S3StorageAdapter()
    object_key = f"avatars/{current_user.id}.jpg"
    success = await s3.upload_file(
        file_content=resized,
        object_key=object_key,
        content_type="image/jpeg",
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="falha_no_upload_s3",
        )

    # Public URL — services that need a presigned read can derive from object_key.
    url = f"{s3.endpoint_url or 'https://s3.amazonaws.com'}/{s3.bucket_name}/{object_key}"
    updated = await user_service.update_avatar_url(db, current_user, url)

    logger.info("user_avatar_uploaded", user_id=str(current_user.id), bytes=len(resized))
    return UserResponse.model_validate(updated)


# ── Metrics ────────────────────────────────────────────────────────────────


@router.get(
    "/me/metrics",
    response_model=ConsultorMetricsResponse,
    summary="Métricas (KPIs) do consultor logado",
    description=(
        "Agregação de leads (total, qualificados, fechados), propostas enviadas e "
        "taxa de conversão. Cache Redis 5min."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Endpoint apenas para consultor/admin", "model": HTTPErrorResponse},
    },
)
async def my_metrics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ConsultorMetricsResponse:
    _require_consultor_or_admin(current_user)
    return await metrics_service.consultor_metrics(db, current_user.id)


# ── Goals ──────────────────────────────────────────────────────────────────


@router.get(
    "/me/goals",
    response_model=SaleGoalsListResponse,
    summary="Metas mensais do consultor",
    description=(
        "Lista metas de venda dos últimos N meses (default 3). Meses sem registro "
        "retornam target=0, achieved=0 (backfill)."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Endpoint apenas para consultor/admin", "model": HTTPErrorResponse},
        422: {"description": "Parâmetro months inválido", "model": HTTPErrorResponse},
    },
)
async def my_goals(
    months: int = Query(3, ge=1, le=12),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SaleGoalsListResponse:
    _require_consultor_or_admin(current_user)
    return await sale_goal_service.list_recent(db, current_user.id, months=months)


@router.put(
    "/me/goals/{year}/{month}",
    response_model=SaleGoalResponse,
    summary="Define meta mensal (admin only)",
    description="Apenas admin. Idempotente. Cria ou atualiza target sem mexer em achieved.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        403: {"description": "Apenas admin", "model": HTTPErrorResponse},
        422: {"description": "Parâmetros inválidos", "model": HTTPErrorResponse},
    },
)
async def upsert_my_goal_target(
    payload: SaleGoalUpdateRequest,
    year: int = Path(..., ge=2024, le=2100),
    month: int = Path(..., ge=1, le=12),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SaleGoalResponse:
    _require_admin(current_user)
    row = await sale_goal_service.upsert_target(
        db,
        user_id=current_user.id,
        period_year=year,
        period_month=month,
        target=payload.target,
    )
    return SaleGoalResponse.model_validate(row)
