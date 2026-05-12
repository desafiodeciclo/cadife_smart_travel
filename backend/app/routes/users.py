from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.middleware.auth import verify_jwt
from app.models.user import UserResponse, UserProfileUpdate, FcmTokenRequest
from app.services.user_service import get_user_by_id
from app.presentation.schemas.common_errors import HTTPErrorResponse

router = APIRouter(prefix="/users", tags=["Users"])

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
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Usuário não encontrado"
        )
    return UserResponse.model_validate(user)

@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Atualização de perfil",
    description="Atualiza campos editáveis do perfil do usuário autenticado.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
    },
)
async def update_me(
    body: UserProfileUpdate,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    from app.services.user_service import get_user_by_id, update_user_profile
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Usuário não encontrado")
    
    updated = await update_user_profile(db, user, body)
    return UserResponse.model_validate(updated)

@router.post(
    "/fcm-token",
    summary="Registro de token FCM",
    description="Registra ou atualiza o token Firebase Cloud Messaging do dispositivo para notificações push.",
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def register_fcm_token(
    body: FcmTokenRequest,
    db: AsyncSession = Depends(get_db),
    user_id: str = Depends(verify_jwt),
):
    from app.services.user_service import get_user_by_id, update_fcm_token
    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=401, detail="Usuário não encontrado")
        
    await update_fcm_token(db, user, body.fcm_token)
    return {"message": "Token FCM registrado com sucesso"}
