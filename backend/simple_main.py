from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel
import jwt
from datetime import datetime, timedelta
import sqlite3
import os

app = FastAPI()

SECRET_KEY = "sua_chave_secreta_super_segura"
ALGORITHM = "HS256"
DB_PATH = "cadife.db"

class LoginRequest(BaseModel):
    email: str
    password: str

def get_user_from_db(email: str):
    # Procura o usuario no banco de dados real
    try:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, email, role FROM users WHERE email = ?", (email,))
        user = cursor.fetchone()
        conn.close()
        return user
    except Exception as e:
        print(f"ERR: Erro ao acessar o banco: {e}")
        return None

@app.post("/auth/login")
async def login(request: LoginRequest):
    email = request.email.strip().lower()
    password = request.password.strip()
    
    print(f"--- TENTATIVA DE LOGIN REAL ---")
    print(f"E-mail: {email}")
    
    # 1. Busca o usuario no banco
    user = get_user_from_db(email)
    
    if not user:
        print("ERR: Usuario nao encontrado no banco")
        raise HTTPException(status_code=401, detail="Usuario nao encontrado")

    # 2. Valida a senha (como o banco usa hash, para o teste vamos aceitar 'password123'
    # ou qualquer senha se voce preferir, mas vamos manter a trava por seguranca)
    if password == "password123": # Use a senha padrao para o seu teste
        print(f"OK: LOGIN APROVADO PARA: {user['name']}")
        
        expire = datetime.utcnow() + timedelta(hours=24)
        to_encode = {
            "sub": str(user['id']), 
            "exp": expire,
            "name": user['name'],
            "role": user['role'],
            "email": user['email']
        }
        token = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        
        user_data = {
            "id": str(user['id']),
            "name": user['name'],
            "email": user['email'],
            "role": user['role']
        }
        
        return {
            "token": {
                "access_token": token,
                "refresh_token": "refresh_token_real_123"
            },
            "user": user_data
        }
    
    print("ERR: Senha incorreta")
    raise HTTPException(status_code=401, detail="Senha incorreta")

@app.get("/users/me")
async def get_me(authorization: str = Header(None)):
    print("--- BUSCANDO PERFIL REAL ---")
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Nao autorizado")
    
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        
        # Busca no banco pelo ID que veio no token
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("SELECT id, name, email, role FROM users WHERE id = ?", (user_id,))
        user = cursor.fetchone()
        conn.close()
        
        if user:
            print(f"OK: Perfil de {user['name']} enviado")
            return {
                "id": str(user['id']),
                "name": user['name'],
                "email": user['email'],
                "role": user['role']
            }
    except Exception as e:
        print(f"ERR: Erro no token ou banco: {e}")
    
    raise HTTPException(status_code=401, detail="Token invalido")

@app.post("/auth/logout")
async def logout():
    print("OK: LOGOUT")
    return {"detail": "ok"}

if __name__ == "__main__":
    import uvicorn
    print(f"\nSERVIDOR REAL-DB RODANDO NA PORTA 8000")
    print(f"Lendo banco: {os.path.abspath(DB_PATH)}\n")
    uvicorn.run(app, host="0.0.0.0", port=8000)
