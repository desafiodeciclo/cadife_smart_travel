from pydantic import BaseModel, EmailStr
from typing import Optional
from enum import Enum

class UserRole(str, Enum):
    CLIENT = "client"
    CONSULTANT = "consultant"
    ADMIN = "admin"

class UserResponse(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: UserRole
    avatar_url: Optional[str] = None
    bio: Optional[str] = None

    class Config:
        json_schema_extra = {
            "example": {
                "id": "507f1f77bcf86cd799439011",
                "name": "João Silva",
                "email": "joao@cadife.com",
                "role": "consultant",
                "avatar_url": "https://...",
                "bio": "Consultor especializado em viagens de luxo."
            }
        }
        from_attributes = True
