import os
import sys

# Ajusta o PYTHONPATH para encontrar os módulos do app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.infrastructure.security.jwt import create_access_token

def get_token():
    # ID fixo do admin que inserimos via SQL
    admin_id = "00000000-0000-0000-0000-000000000001"
    token = create_access_token(admin_id)
    
    print("\n🎫 TOKEN DE ACESSO GERADO:")
    print("-------------------------")
    print(token)
    print("-------------------------")
    print("\nCopie o token acima para usar nos testes.\n")

if __name__ == "__main__":
    get_token()
