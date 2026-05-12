import sys
import os
import argparse
import uuid
from datetime import timedelta
from jose import jwt

# Ajusta o path para encontrar o módulo 'app'
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.infrastructure.config.settings import get_settings

settings = get_settings()

def create_token(user_id: str, perfil: str):
    payload = {
        "sub": user_id,
        "perfil": perfil,
        "type": "access",
    }
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

def main():
    parser = argparse.ArgumentParser(description="Gerador de JWT para Pentest Manual")
    parser.add_argument("--perfil", choices=["admin", "consultor", "cliente", "agencia"], default="cliente")
    parser.add_argument("--id", default=str(uuid.uuid4()))
    
    args = parser.parse_args()
    
    token = create_token(args.id, args.perfil)
    print(f"\n🔑 Token Gerado para Perfil: {args.perfil}")
    print(f"🆔 ID Simulado: {args.id}")
    print(f"\n{token}\n")

if __name__ == "__main__":
    main()
