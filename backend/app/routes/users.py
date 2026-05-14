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
from app.services.metrics_service import get_consultor_metrics
from app.services.sale_goal_service import get_user_goals
from fastapi import Query

router = APIRouter(prefix="/users", tags=["Users"])

_ROLE_MAP = {
    "cliente": UserRole.CLIENT,
    "admin": UserRole.ADMIN,
    "consultant": UserRole.CONSULTANT,
    "consultor": UserRole.CONSULTANT,
}

class ConsultorMetricsResponse(BaseModel):
    leads_total: int
    leads_qualificados: int
    propostas_enviadas: int
    vendas_fechadas: int
    taxa_conversao: float
    gerado_em: datetime

class SaleGoalResponse(BaseModel):
    period_year: int
    period_month: int
    target: int
    achieved: int

class SaleGoalsListResponse(BaseModel):
    goals: list[SaleGoalResponse]

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
        role=_ROLE_MAP.get(user.perfil, UserRole.CONSULTANT),
        avatar_url=user.avatar_url,
        bio=user.bio
    )

@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Atualização de perfil",
    description="Atualiza campos editáveis do perfil do usuário autenticado.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        404: {"description": "Usuário não encontrado", "model": HTTPErrorResponse},
    },
)
async def update_me(
    body: UserProfileUpdate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
    
    updated = await update_user_profile(db, user, body)
    return UserResponse.model_validate(updated)

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

class BioUpdateRequest(BaseModel):
    bio: str = Field(..., min_length=1, max_length=500)

@router.patch(
    "/me/bio",
    response_model=UserResponse,
    summary="Atualização de biografia",
    description="Atualiza e sanitiza a biografia do usuário.",
)
async def update_bio(
    body: BioUpdateRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
    
    # Sanitização: remove tags HTML
    sanitized_bio = bleach.clean(body.bio, tags=[], strip=True).strip()
    
    user.bio = sanitized_bio
    await db.commit()
    await db.refresh(user)
    
    return UserResponse(
        id=str(user.id),
        name=user.nome,
        email=user.email,
        role=_ROLE_MAP.get(user.perfil, UserRole.CONSULTANT),
        avatar_url=user.avatar_url,
        bio=user.bio
    )

def _process_image(data: bytes) -> bytes:
    """Resize image to 512x512 thumbnail."""
    img = Image.open(BytesIO(data))
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")
    img.thumbnail((512, 512))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return buf.getvalue()

@router.patch(
    "/me/profile-photo",
    response_model=UserResponse,
    summary="Atualização de foto de perfil",
    description="Recebe um arquivo de imagem, redimensiona para 512x512 e atualiza o avatar.",
)
async def update_profile_photo(
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
    
    if not photo.content_type or not photo.content_type.startswith("image/"):
        raise HTTPException(status_code=415, detail="Apenas imagens são permitidas")

    # Read and validate size
    content = await photo.read()
    if len(content) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Tamanho máximo de 5MB")

    # Resize in thread to avoid blocking
    try:
        resized_data = await asyncio.to_thread(_process_image, content)
    except Exception:
        raise HTTPException(status_code=422, detail="Erro ao processar imagem")

    # Mock upload logic: in real app, save resized_data to S3/Cloudinary
    new_filename = f"{uuid.uuid4()}.jpg"
    mock_url = f"https://api.cadife.com/static/avatars/{new_filename}"
    
    updated = await update_user_avatar(db, user, mock_url)
    
    return UserResponse(
        id=str(updated.id),
        name=updated.nome,
        email=updated.email,
        role=_ROLE_MAP.get(updated.perfil, UserRole.CONSULTANT),
        avatar_url=updated.avatar_url,
        bio=updated.bio
    )

@router.get(
    "/me/metrics",
    response_model=ConsultorMetricsResponse,
    summary="Métricas do consultor",
    description="Agrega KPIs de leads e conversão do consultor logado.",
)
async def my_metrics(
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    # Optional: check if user is consultant or admin
    
    metrics = await get_consultor_metrics(db, user.id)
    return ConsultorMetricsResponse(**metrics)

@router.get(
    "/me/goals",
    response_model=SaleGoalsListResponse,
    summary="Metas do consultor",
    description="Retorna as metas de vendas e progresso dos últimos N meses.",
)
async def my_goals(
    months: int = Query(3, ge=1, le=12),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
        
    goals = await get_user_goals(db, user.id, months)
    return SaleGoalsListResponse(goals=goals)

