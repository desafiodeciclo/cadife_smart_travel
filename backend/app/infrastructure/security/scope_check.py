"""
Scope Check — Infrastructure/Security Layer
=============================================
Shared authorization helpers for lead-level access control.
Used by routers that operate on leads (propostas, agenda, etc.)
to enforce consultor scope boundaries.
"""
from fastapi import HTTPException, status

from app.models.user import User


def check_lead_access(current_user: User, lead) -> None:
    """Raise 403 if the current user is not allowed to access the lead.

    Rules:
      - admin: full access to any lead
      - consultor: only leads where consultor_id == current_user.id
      - cliente: no access (should be blocked at router level via RequiresRole)
    """
    if current_user.perfil == "consultor" and lead.consultor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado ao lead",
        )
