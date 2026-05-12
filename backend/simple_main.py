from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel
import jwt
from datetime import datetime, timedelta

app = FastAPI()

SECRET_KEY = "sua_chave_secreta_super_segura"
ALGORITHM = "HS256"

class LoginRequest(BaseModel):
    email: str
    password: str

# Dados mockados do usuario
MOCK_USER = {
    "id": "user_123",
    "name": "Test User",
    "email": "test@example.com",
    "role": "cliente", # Usando 'cliente' para bater com o UserRole
    "avatar": "https://api.dicebear.com/7.x/avataaars/svg?seed=Test"
}

@app.post("/auth/login")
async def login(request: LoginRequest):
    email = request.email.strip().lower()
    password = request.password.strip()
    
    print("--- TENTATIVA DE LOGIN ---")
    print(f"Recebido: '{email}' / '{password}'")
    
    if "test" in email and password == "password123":
        print("OK: LOGIN APROVADO!")
        expire = datetime.utcnow() + timedelta(hours=24)
        
        # Adicionando dados ao payload do JWT para que o decode local funcione se necessÃ¡rio
        to_encode = {
            "sub": email, 
            "exp": expire,
            "name": MOCK_USER["name"],
            "role": MOCK_USER["role"],
            "email": MOCK_USER["email"]
        }
        token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        
        # FORMATO EXATO QUE O AUTH_REPOSITORY_IMPL ESPERA:
        return {
            "token": {
                "access_token": token,
                "refresh_token": "fake_refresh_token_123"
            },
            "user": MOCK_USER
        }
    
    print("ERR: LOGIN REJEITADO!")
    raise HTTPException(status_code=401, detail="Credenciais invalidas")

@app.get("/users/me")
async def get_me(authorization: str = Header(None)):
    print("--- BUSCANDO USUARIO ---")
    if not authorization or not authorization.startswith("Bearer "):
        print("ERR: Token ausente")
        raise HTTPException(status_code=401, detail="Nao autorizado")
    
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        print(f"OK: Token decodificado para: {payload.get('sub')}")
        return MOCK_USER
    except Exception as e:
        print(f"ERR: Erro no token: {e}")
    
    raise HTTPException(status_code=401, detail="Token invalido")

@app.post("/auth/logout")
async def logout():
    print("OK: LOGOUT RECEBIDO NO SERVIDOR")
    return {"detail": "Logged out"}

if __name__ == "__main__":
    import uvicorn
    print("\nSERVIDOR DE TESTE RODANDO NA PORTA 8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
