from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.middleware.auth import verify_jwt
from app.models.user import UserProfileUpdate, FcmTokenRequest
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.schemas.user import UserResponse, UserRole
from fastapi import File, UploadFile
import os
import uuid
import bleach
import asyncio
from PIL import Image
from io import BytesIO
from pydantic import Field
from datetime import datetime, date
from app.services.user_service import get_user_by_id, update_user_profile, update_fcm_token, update_user_avatar, update_password
from app.services.metrics_service import consultor_metrics
from app.services.sale_goal_service import list_recent
from app.presentation.schemas.consultor_profile_schema import (
    BioUpdateRequest,
    ConsultorMetricsResponse,
    SaleGoalsListResponse,
)
from fastapi import Query

router = APIRouter(prefix="/users", tags=["Users"])

_ROLE_MAP = {
    "cliente": UserRole.CLIENT,
    "admin": UserRole.ADMIN,
    "consultant": UserRole.CONSULTANT,
    "consultor": UserRole.CONSULTANT,
}


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Perfil do usuário autenticado",
    description="Retorna os dados do usuário logado com base no JWT enviado no header Authorization.",
    responses={
        401: {"description": "Token inválido ou expirado", "model": HTTPErrorResponse},
        404: {"description": "Usuário não encontrado", "model": HTTPErrorResponse},
    },
)
async def get_me(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt)
):
    """
    Obtém as informações do usuário autenticado atual.
    """
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Usuário não encontrado"
        )
    return UserResponse(
        id=str(user.id),
        name=user.nome,
        email=user.email,
        role=_ROLE_MAP.get(user.perfil, UserRole.CLIENT),
        avatar_url=user.avatar_url,
        bio=user.bio
    )

class FcmTokenResponse(BaseModel):
    message: str

@router.post(
    "/fcm-token",
    response_model=FcmTokenResponse,
    summary="Registro de token FCM",
    description="Registra ou atualiza o token Firebase Cloud Messaging do dispositivo para notificações push.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        404: {"description": "Usuário não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def register_fcm_token(
    body: FcmTokenRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
        
    await update_fcm_token(db, user, body.fcm_token)
    return FcmTokenResponse(message="Token FCM registrado com sucesso")

