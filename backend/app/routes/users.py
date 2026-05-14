from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.middleware.auth import verify_jwt
from app.models.user import UserProfileUpdate, FcmTokenRequest
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.schemas.user import UserResponse, UserRole
from app.services.user_service import get_user_by_id, update_user_profile, update_fcm_token, update_user_avatar
from fastapi import File, UploadFile
import os
import uuid
import aiofiles

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

@router.patch(
    "/me/bio",
    response_model=UserResponse,
    summary="Atualização de biografia",
    description="Atualiza apenas a biografia do usuário.",
)
async def update_bio(
    body: dict,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
    
    bio = body.get("bio")
    if bio is None:
        raise HTTPException(status_code=422, detail="Campo bio é obrigatório")
        
    user.bio = bio
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

@router.patch(
    "/me/profile-photo",
    response_model=UserResponse,
    summary="Atualização de foto de perfil",
    description="Recebe um arquivo de imagem e atualiza o avatar do usuário.",
)
async def update_profile_photo(
    photo: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado")
    
    # Mock upload logic: Save to a local folder or cloud storage
    # For now, let's just simulate a URL
    file_ext = os.path.splitext(photo.filename)[1]
    new_filename = f"{uuid.uuid4()}{file_ext}"
    
    # In a real app, we would save the file here
    # For now, we'll just return a mock URL
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
