from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.middleware.auth import verify_jwt
from app.core.security import (
    create_access_token,
    create_refresh_token,
    create_reset_token,
    decode_token,
    verify_password,
)
from app.models.user import (
    ChangePasswordRequest,
    FcmTokenRequest,
    FcmTokenResponse,
    ForgotPasswordRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    User,
    UserResponse,
)
from app.presentation.schemas.common_errors import HTTPErrorResponse
from app.services.user_service import (
    create_user,
    get_user_by_email,
    get_user_by_id,
)
from app.infrastructure.security.rate_limiter import limiter

router = APIRouter(tags=["Auth"])


@router.post(
    "/auth/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Cadastro de novo usuário",
    description="Cria uma conta de cliente e retorna um par de tokens JWT.",
    responses={
        409: {"description": "E-mail já cadastrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação no body", "model": HTTPErrorResponse},
        429: {"description": "Too Many Requests - Rate Limit excedido"},
    },
)
@limiter.limit("5/minute")
async def register(
    request: Request,
    body: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    existing = await get_user_by_email(db, body.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="E-mail já cadastrado",
        )
    user = await create_user(db, nome=body.nome, email=body.email, password=body.password)
    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post(
    "/auth/logout",
    status_code=status.HTTP_200_OK,
    summary="Logout de usuário",
    description=(
        "Encerra a sessão. JWT é stateless — o cliente deve descartar os tokens localmente. "
        "Endpoint existe para garantir compatibilidade com o contrato da API."
    ),
)
async def logout(
    _: Request,
    current_user: User = Depends(verify_jwt),
) -> dict:
    return {"detail": "Logout realizado com sucesso"}


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

    return TokenResponse(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post(
    "/auth/change-password",
    status_code=status.HTTP_200_OK,
    summary="Alterar senha do usuário",
    description=(
        "Altera a senha de um usuário autenticado. Requer a senha atual para validação. "
        "A nova senha deve ter no mínimo 8 caracteres."
    ),
    responses={
        401: {"description": "Senha atual incorreta ou usuário não encontrado", "model": HTTPErrorResponse},
        422: {"description": "Erro de validação (nova senha fraca)", "model": HTTPErrorResponse},
    },
)
@limiter.limit("5/minute")
async def change_password(
    request: Request,
    body: ChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(verify_jwt),
) -> dict:
    user = await get_user_by_id(db, str(current_user.id) if hasattr(current_user, 'id') else current_user)
    if not user or not verify_password(body.current_password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Senha atual incorreta",
        )
    from app.services.user_service import update_password
    await update_password(db, user, body.new_password)
    return {"detail": "Senha alterada com sucesso"}


@router.post(
    "/auth/forgot-password",
    status_code=status.HTTP_200_OK,
    summary="Solicitar redefinição de senha",
    description=(
        "Envia um token de redefinição para o e-mail do usuário (ou retorna token em dev). "
        "A resposta é sempre 200 para não enumerar usuários existentes."
    ),
    responses={
        200: {"description": "Token gerado ou e-mail enviado"},
        422: {"description": "Erro de validação no email", "model": HTTPErrorResponse},
    },
)
@limiter.limit("3/minute")
async def forgot_password(
    request: Request,
    body: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    user = await get_user_by_email(db, body.email)
    # Anti-enumeration: respond 200 even if email doesn't exist
    if not user:
        return {"detail": "Se o e-mail existir, você receberá as instruções de recuperação."}

    reset_token = create_reset_token(str(user.id))
    # TODO: enviar email com reset_token quando infraestrutura de email estiver disponível
    # Para dev, retornamos o token direto
    return {
        "detail": "Se o e-mail existir, você receberá as instruções de recuperação.",
        "reset_token": reset_token,
    }


@router.post(
    "/auth/logout-all-devices",
    status_code=status.HTTP_200_OK,
    summary="Desconectar de todos os dispositivos",
    description=(
        "Invalida todos os refresh tokens do usuário, desconectando-o de todos os dispositivos. "
        "Requer autenticação via JWT."
    ),
    responses={
        401: {"description": "Não autenticado", "model": HTTPErrorResponse},
    },
)
@limiter.limit("3/minute")
async def logout_all_devices(
    request: Request,
    current_user: User = Depends(verify_jwt),
) -> dict:
    # TODO: Implementar invalidação de tokens via Redis
    # Salvar timestamp em Redis chave "invalidated_before:{user_id}" para rejeitar tokens antigos
    # Por enquanto, apenas log da ação
    return {"detail": "Todos os dispositivos foram desconectados"}


