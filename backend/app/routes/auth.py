from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone, timedelta

from app.core.dependencies import get_db
from app.infrastructure.security.dependencies import get_current_user, bearer_scheme
from app.infrastructure.persistence.models.revoked_token_model import RevokedTokenModel
from app.infrastructure.security.jwt import decode_token, create_reset_token
from app.core.security import (
    create_access_token,
    create_refresh_token,
    verify_password,
)
from app.models.user import (
    FcmTokenRequest,
    FcmTokenResponse,
    LoginRequest,
    RegisterRequest,
    RefreshRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    ChangePasswordRequest,
    TokenResponse,
    UserResponse,
)
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services.user_service import (
    get_user_by_email,
    get_user_by_id,
    create_user,
    update_password,
)
from app.infrastructure.security.rate_limiter import limiter
import structlog
import hashlib

logger = structlog.get_logger()

def hash_pii(email: str) -> str:
    return hashlib.sha256(email.lower().strip().encode()).hexdigest()

router = APIRouter(tags=["Auth"])


@router.post(
    "/auth/login",
    response_model=TokenResponse,
    summary="Autenticação de usuário",
    description="Autentica um usuário com e-mail e senha, retornando um par de tokens JWT (access + refresh).",
    responses={
        401: {"description": "Credenciais inválidas ou usuário inativo", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
        429: {"description": "Too Many Requests - Rate Limit excedido"},
    },
)
@limiter.limit("3/minute")
async def login(request: Request, response: Response, body: LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, body.email)
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas"
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuário inativo"
        )

    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post(
    "/auth/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Registro de novo usuário",
    description="Cria uma nova conta de usuário (cliente) e retorna um par de tokens JWT.",
    responses={
        409: {"description": "E-mail já registrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body (senha fraca, etc)", "model": HTTPErrorResponse},
        429: {"description": "Too Many Requests"},
    },
)
@limiter.limit("5/minute")
async def register(request: Request, response: Response, body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await get_user_by_email(db, body.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="email_already_registered"
        )
    
    user = await create_user(db, body, role="cliente")
    logger.info("auth_register", user_id=str(user.id), email_hash=hash_pii(body.email))
    
    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post(
    "/auth/refresh",
    response_model=TokenResponse,
    summary="Renovação de token JWT",
    description="Recebe um refresh token válido e retorna um novo par de tokens JWT.",
    responses={
        401: {"description": "Refresh token inválido, expirado ou tipo incorreto", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
    },
)
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(body.refresh_token)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado",
        )

    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido"
        )

    user = await get_user_by_id(db, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuário não encontrado"
        )
        
    # Check if refresh token was issued before a global logout
    iat = payload.get("iat")
    if iat and user.global_logout_at:
        token_issued_at = datetime.fromtimestamp(iat, tz=timezone.utc)
        if token_issued_at <= user.global_logout_at:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Sessão revogada (logout global)"
            )

    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post(
    "/auth/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Encerra a sessão atual (Logout)",
    description="Adiciona o Access Token atual na lista negra para impedir novas requisições.",
)
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    try:
        payload = decode_token(credentials.credentials)
        exp_timestamp = payload.get("exp")
        expires_at = datetime.fromtimestamp(exp_timestamp, tz=timezone.utc) if exp_timestamp else (datetime.now(timezone.utc) + timedelta(hours=1))
    except Exception:
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        
    revoked = RevokedTokenModel(
        token=credentials.credentials,
        expires_at=expires_at
    )
    db.add(revoked)
    await db.commit()
    logger.info("auth_logout", user_id=str(user.id))
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/auth/logout-all-devices",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Desconecta de todos os dispositivos",
    description="Atualiza a data de logout global do usuário, invalidando todos os tokens gerados anteriormente.",
)
async def logout_all_devices(
    user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    user.global_logout_at = datetime.now(timezone.utc).replace(microsecond=0)
    await db.commit()
    logger.info("auth_logout_all", user_id=str(user.id))
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post(
    "/auth/forgot-password",
    status_code=status.HTTP_202_ACCEPTED,
    summary="Solicita recuperação de senha",
    description="Gera um token de recuperação de senha válido por 30 minutos. Impede enumeração de usuários.",
)
@limiter.limit("3/minute")
async def forgot_password(request: Request, body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, body.email)
    if user and user.is_active:
        reset_token = create_reset_token(str(user.id))
        from app.services.email_service import send_password_reset_email
        await send_password_reset_email(body.email, reset_token)
        logger.info("auth_forgot_password_email_sent", user_id=str(user.id))
    
    # Sempre retorna sucesso para não confirmar se o e-mail existe
    return {"message": "Se o e-mail existir, um link de recuperação foi enviado."}


@router.post(
    "/auth/reset-password",
    status_code=status.HTTP_200_OK,
    summary="Redefine a senha do usuário",
    description="Recebe o token temporário e a nova senha forte. Ao redefinir, desloga o usuário de todos os aparelhos por segurança.",
    responses={
        401: {"description": "Token inválido, expirado ou sessão encerrada", "model": HTTPErrorResponse},
        422: {"description": "Senha não atende aos requisitos de força", "model": HTTPErrorResponse},
    }
)
async def reset_password(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    try:
        payload = decode_token(body.token)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido ou expirado"
        )
        
    if payload.get("type") != "reset":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido"
        )
        
    user = await get_user_by_id(db, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuário não encontrado"
        )
        
    # Verifica se o token de reset foi gerado antes de um logout global (proteção extra)
    iat_timestamp = payload.get("iat")
    if iat_timestamp and user.global_logout_at:
        iat_dt = datetime.fromtimestamp(iat_timestamp, tz=timezone.utc)
        if iat_dt < user.global_logout_at:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Token de recuperação expirado (sessão encerrada)"
            )
            
    # O update_password já chama o global_logout_at para derrubar todas as sessões ativas
    await update_password(db, user, body.new_password.get_secret_value())
    
    logger.info("auth_reset_password_success", user_id=str(user.id))
    return {"message": "Senha atualizada com sucesso"}


@router.post(
    "/auth/change-password",
    status_code=status.HTTP_200_OK,
    summary="Altera a senha do usuário logado",
    description="Exige a senha antiga para confirmar a identidade e atualiza para a nova senha forte. Ao redefinir, desloga o usuário de todos os aparelhos.",
    responses={
        400: {"description": "Senha antiga incorreta", "model": HTTPErrorResponse},
        422: {"description": "Nova senha não atende aos requisitos de força", "model": HTTPErrorResponse},
    }
)
async def change_password(
    body: ChangePasswordRequest, 
    user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not verify_password(body.current_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Senha antiga incorreta"
        )
        
    await update_password(db, user, body.new_password.get_secret_value())
    
    logger.info("auth_change_password_success", user_id=str(user.id))
    return {"message": "Senha atualizada com sucesso"}



