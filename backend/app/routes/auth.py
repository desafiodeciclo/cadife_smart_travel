from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.middleware.auth import verify_jwt
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
)
from app.models.user import (
    FcmTokenRequest,
    FcmTokenResponse,
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



