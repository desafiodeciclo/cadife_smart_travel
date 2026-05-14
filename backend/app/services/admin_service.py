"""
Admin Service — Business logic for admin user management.
============================================================
Handles CRUD of consultants, lead reassignment, welcome emails,
and structured audit logging.
"""

import secrets
import uuid
from typing import Optional

import structlog
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.infrastructure.config.settings import get_settings
from app.models.admin import AdminUserMetrics
from app.models.lead import Lead
from app.models.user import User, UserPerfil
from app.services.fcm_service import send_push_notification

logger = structlog.get_logger()


def _generate_temp_password(length: int = 12) -> str:
    """Generate a secure temporary password."""
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return "".join(secrets.choice(alphabet) for _ in range(length))


async def _send_welcome_email(
    to_email: str,
    nome: str,
    temp_password: str,
) -> bool:
    """
    Send welcome email with temporary credentials.
    Falls back to logging if SMTP is not configured.
    """
    settings = get_settings()
    # For MVP we log the credentials; in production this integrates with SendGrid/AWS SES.
    logger.info(
        "welcome_email_dispatched",
        to=to_email,
        nome=nome,
        temp_password=temp_password,
        note="Integrate with transactional email provider (SendGrid/SES) for production",
    )
    # Attempt SMTP if host is configured
    smtp_host = getattr(settings, "SMTP_HOST", None)
    if not smtp_host:
        return True  # logged successfully as fallback

    try:
        import aiosmtplib
        from email.message import EmailMessage

        msg = EmailMessage()
        msg["From"] = getattr(settings, "SMTP_FROM", "noreply@cadifetour.com.br")
        msg["To"] = to_email
        msg["Subject"] = "Bem-vindo à Cadife Tour — Suas credenciais de acesso"
        msg.set_content(
            f"Olá {nome},\n\n"
            f"Sua conta de consultor foi criada na plataforma Cadife Smart Travel.\n"
            f"E-mail: {to_email}\n"
            f"Senha temporária: {temp_password}\n\n"
            f"Por segurança, altere sua senha no primeiro acesso.\n\n"
            f"Equipe Cadife Tour"
        )

        await aiosmtplib.send(
            msg,
            hostname=smtp_host,
            port=getattr(settings, "SMTP_PORT", 587),
            username=getattr(settings, "SMTP_USER", None),
            password=getattr(settings, "SMTP_PASSWORD", None),
            start_tls=True,
        )
        logger.info("welcome_email_sent_smtp", to=to_email)
        return True
    except Exception as exc:
        logger.error("welcome_email_smtp_failed", to=to_email, error=str(exc))
        return False


async def create_consultor(
    db: AsyncSession,
    nome: str,
    email: str,
    telefone: Optional[str],
    role: UserPerfil = UserPerfil.consultor,
) -> tuple[User, str]:
    """
    Create a new consultant user with a temporary password.
    Returns the created user and the plain temporary password.
    """
    if role not in (UserPerfil.consultor, UserPerfil.agencia):
        raise ValueError("Role deve ser 'consultor' ou 'agencia'")

    # Check duplicate email
    existing = await db.execute(select(User).where(User.email == email))
    if existing.scalar_one_or_none():
        raise ValueError(f"DUPLICATE_EMAIL:{email}")

    temp_password = _generate_temp_password()
    hashed = hash_password(temp_password)

    user = User(
        nome=nome,
        email=email,
        telefone=telefone,
        hashed_password=hashed,
        perfil=role,
        is_active=True,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    logger.info(
        "admin_user_created",
        admin_action="create_consultor",
        user_id=str(user.id),
        email=email,
        role=role.value,
    )

    await _send_welcome_email(email, nome, temp_password)
    return user, temp_password


async def list_consultores(
    db: AsyncSession,
) -> list[dict]:
    """
    List all users with consultant-like roles (consultor, agencia, admin)
    together with lead metrics.
    """
    result = await db.execute(
        select(User).where(
            User.perfil.in_([UserPerfil.consultor, UserPerfil.agencia, UserPerfil.admin])
        )
    )
    users = list(result.scalars().all())

    # Aggregate metrics per consultant
    metrics_map: dict[uuid.UUID, AdminUserMetrics] = {}
    for user in users:
        total_stmt = (
            select(func.count())
            .select_from(Lead)
            .where(Lead.consultor_id == user.id, Lead.is_archived.is_(False))
        )
        active_stmt = total_stmt.where(Lead.status != "fechado")
        closed_stmt = total_stmt.where(Lead.status == "fechado")

        total = (await db.execute(total_stmt)).scalar_one()
        active = (await db.execute(active_stmt)).scalar_one()
        closed = (await db.execute(closed_stmt)).scalar_one()

        metrics_map[user.id] = AdminUserMetrics(
            total_leads=total,
            active_leads=active,
            closed_leads=closed,
        )

    return [{"user": u, "metrics": metrics_map.get(u.id, AdminUserMetrics())} for u in users]


async def update_consultor(
    db: AsyncSession,
    user: User,
    nome: Optional[str] = None,
    email: Optional[str] = None,
    telefone: Optional[str] = None,
    is_active: Optional[bool] = None,
) -> User:
    """Update consultant data or deactivate account."""
    if nome is not None:
        user.nome = nome
    if email is not None:
        user.email = email
    if telefone is not None:
        user.telefone = telefone
    if is_active is not None:
        user.is_active = is_active

    await db.commit()
    await db.refresh(user)

    logger.info(
        "admin_user_updated",
        admin_action="update_consultor",
        user_id=str(user.id),
        email=user.email,
        is_active=user.is_active,
    )
    return user


async def soft_delete_consultor(
    db: AsyncSession,
    user: User,
    reassign_to_id: Optional[uuid.UUID] = None,
) -> None:
    """
    Soft-delete a consultant by deactivating the account.
    Optionally reassign active leads to another consultant.
    """
    if reassign_to_id:
        # Validate target consultant exists and is active
        target_result = await db.execute(
            select(User).where(User.id == reassign_to_id, User.is_active.is_(True))
        )
        target = target_result.scalar_one_or_none()
        if not target:
            raise ValueError("TARGET_CONSULTOR_NOT_FOUND")

        # Reassign active (non-archived) leads
        leads_result = await db.execute(
            select(Lead).where(
                Lead.consultor_id == user.id,
                Lead.is_archived.is_(False),
            )
        )
        leads = leads_result.scalars().all()
        for lead in leads:
            old_consultor_id = lead.consultor_id
            lead.consultor_id = reassign_to_id
            logger.info(
                "lead_reassigned_on_delete",
                lead_id=str(lead.id),
                old_consultor_id=str(old_consultor_id),
                new_consultor_id=str(reassign_to_id),
            )

    user.is_active = False
    await db.commit()
    await db.refresh(user)

    logger.info(
        "admin_user_soft_deleted",
        admin_action="soft_delete_consultor",
        user_id=str(user.id),
        email=user.email,
        reassign_to_id=str(reassign_to_id) if reassign_to_id else None,
    )


async def reassign_lead(
    db: AsyncSession,
    lead: Lead,
    new_consultor_id: uuid.UUID,
) -> dict:
    """
    Reassign a lead to another consultant and notify both via push.
    Returns a dict with old/new consultor IDs.
    """
    old_consultor_id = lead.consultor_id

    if old_consultor_id == new_consultor_id:
        raise ValueError("SAME_CONSULTOR")

    # Validate new consultant
    target_result = await db.execute(
        select(User).where(User.id == new_consultor_id, User.is_active.is_(True))
    )
    target = target_result.scalar_one_or_none()
    if not target:
        raise ValueError("TARGET_CONSULTOR_NOT_FOUND")

    lead.consultor_id = new_consultor_id
    await db.commit()
    await db.refresh(lead)

    # Notify old consultant (if any)
    if old_consultor_id:
        old_result = await db.execute(select(User).where(User.id == old_consultor_id))
        old_consultor = old_result.scalar_one_or_none()
        if old_consultor and old_consultor.fcm_token:
            await send_push_notification(
                fcm_token=old_consultor.fcm_token,
                title="Lead reatribuído",
                body=f"O lead {lead.nome or lead.telefone} foi reatribuído para outro consultor.",
                data={"type": "lead_reassigned", "lead_id": str(lead.id)},
            )

    # Notify new consultant
    if target.fcm_token:
        await send_push_notification(
            fcm_token=target.fcm_token,
            title="Novo lead atribuído",
            body=f"Você recebeu o lead {lead.nome or lead.telefone}.",
            data={"type": "lead_assigned", "lead_id": str(lead.id)},
        )

    logger.info(
        "admin_lead_reassigned",
        admin_action="reassign_lead",
        lead_id=str(lead.id),
        old_consultor_id=str(old_consultor_id) if old_consultor_id else None,
        new_consultor_id=str(new_consultor_id),
    )

    return {
        "lead_id": lead.id,
        "old_consultor_id": old_consultor_id,
        "new_consultor_id": new_consultor_id,
    }
async def get_conversion_metrics(db: AsyncSession) -> list[dict]:
    """
    Calcula métricas de conversão detalhadas por consultor.
    """
    # Lista todos os consultores ativos
    result = await db.execute(
        select(User).where(
            User.perfil.in_([UserPerfil.consultor, UserPerfil.agencia]),
            User.is_active == True
        )
    )
    consultores = result.scalars().all()
    
    metrics = []
    for c in consultores:
        # Total de leads (não arquivados)
        total_stmt = select(func.count(Lead.id)).where(
            Lead.consultor_id == c.id,
            Lead.is_archived == False
        )
        total = (await db.execute(total_stmt)).scalar_one() or 0
        
        # Leads fechados
        closed_stmt = total_stmt.where(Lead.status == "fechado")
        closed = (await db.execute(closed_stmt)).scalar_one() or 0
        
        # Taxa de conversão
        conversion_rate = (closed / total * 100) if total > 0 else 0.0
        
        metrics.append({
            "consultor_id": str(c.id),
            "consultor_nome": c.nome,
            "total_leads": total,
            "leads_fechados": closed,
            "taxa_conversao": round(conversion_rate, 2)
        })
        
    # Ordena por melhor taxa de conversão
    metrics.sort(key=lambda x: x["taxa_conversao"], reverse=True)
    return metrics
