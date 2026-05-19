import aiosmtplib
from email.message import EmailMessage
import structlog
from app.core.config import get_settings

logger = structlog.get_logger()
settings = get_settings()

async def send_password_reset_email(email: str, token: str):
    """
    Envia e-mail de recuperação de senha.
    Template simples com o token (no futuro link completo).
    """
    message = EmailMessage()
    message["From"] = settings.MAIL_FROM
    message["To"] = email
    message["Subject"] = "Recuperação de Senha - Cadife Smart Travel"
    
    # Em produção, o link deve apontar para o front
    reset_link = f"https://app.cadifetour.com/reset-password?token={token}"
    
    body = f"""
    Olá,
    
    Você solicitou a recuperação de senha da sua conta na Cadife Smart Travel.
    Clique no link abaixo para definir uma nova senha:
    
    {reset_link}
    
    Este link é válido por 30 minutos.
    Se você não solicitou esta alteração, ignore este e-mail.
    """
    message.set_content(body)
    
    try:
        if not settings.MAIL_SERVER:
            logger.warning("email_send_skipped_no_config", email=email)
            return

        await aiosmtplib.send(
            message,
            hostname=settings.MAIL_SERVER,
            port=settings.MAIL_PORT,
            username=settings.MAIL_USERNAME,
            password=settings.MAIL_PASSWORD,
            use_tls=settings.MAIL_USE_TLS,
        )
        logger.info("email_reset_sent", email=email)
    except Exception as e:
        logger.error("email_send_failed", email=email, error=str(e))
        # Não levantamos exceção para não quebrar o fluxo do forgot_password (anti-enumeração)
