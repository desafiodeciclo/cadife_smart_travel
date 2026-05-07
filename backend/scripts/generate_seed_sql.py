import uuid
import random
import os
import sys
from datetime import datetime, timedelta, timezone

# Ajusta o PYTHONPATH e o diretório de trabalho para encontrar os módulos e o .env
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, base_dir)
os.chdir(base_dir)

from app.infrastructure.security.pii_encryption import hmac_hash, _get_fernet

def generate_sql():
    destinos = ["Fortaleza", "Natal", "Gramado", "Fernando de Noronha", "Paris", "Roma", "Disney"]
    nomes_base = ["Alice Silva", "Bruno Souza", "Carla Dias", "Daniel Oliveira", "Eduarda Lima"]
    status_list = ["novo", "contatado", "em_atendimento", "proposta_enviada", "convertido", "perdido"]
    score_list = ["baixo", "medio", "alto"]
    
    fernet = _get_fernet()
    
    sql_lines = [
        "-- Limpeza e Criação das Tabelas",
        "DROP TABLE IF EXISTS briefings CASCADE;",
        "DROP TABLE IF EXISTS leads CASCADE;",
        "DROP TABLE IF EXISTS users CASCADE;",
        "",
        "CREATE TABLE IF NOT EXISTS users (",
        "    id UUID PRIMARY KEY,",
        "    email VARCHAR(255) UNIQUE NOT NULL,",
        "    nome VARCHAR(255) NOT NULL,",
        "    hashed_password VARCHAR(255) NOT NULL,",
        "    perfil VARCHAR(20) NOT NULL DEFAULT 'agencia',",
        "    telefone VARCHAR(20),",
        "    fcm_token VARCHAR(500),",
        "    avatar_url VARCHAR(500),",
        "    is_active BOOLEAN NOT NULL DEFAULT TRUE,",
        "    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,",
        "    tipo_viagem TEXT[],",
        "    preferencias TEXT[],",
        "    tem_passaporte BOOLEAN",
        ");",
        "INSERT INTO users (id, email, nome, hashed_password, perfil, is_active) ",
        "VALUES ('00000000-0000-0000-0000-000000000001', 'admin@teste.com', 'Admin Teste', 'hashed_pass_not_needed_for_token', 'admin', true) ",
        "ON CONFLICT (id) DO NOTHING;",
        "",
        "CREATE TABLE IF NOT EXISTS leads (",
        "    id UUID PRIMARY KEY,",
        "    nome VARCHAR(512),",
        "    telefone VARCHAR(512) NOT NULL,",
        "    telefone_hash VARCHAR(64) UNIQUE NOT NULL,",
        "    status VARCHAR(50) DEFAULT 'novo',",
        "    score VARCHAR(50),",
        "    origem VARCHAR(100) DEFAULT 'whatsapp',",
        "    consultor_id UUID REFERENCES users(id),",
        "    is_archived BOOLEAN DEFAULT FALSE,",
        "    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,",
        "    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,",
        "    deleted_at TIMESTAMP WITH TIME ZONE",
        ");",
        "CREATE TABLE IF NOT EXISTS briefings (",
        "    lead_id UUID PRIMARY KEY REFERENCES leads(id) ON DELETE CASCADE,",
        "    destino VARCHAR(255),",
        "    orcamento_estimado DECIMAL(12,2),",
        "    data_desejada VARCHAR(100),",
        "    adultos INTEGER DEFAULT 2,",
        "    criancas INTEGER DEFAULT 0,",
        "    tipo_viagem TEXT[],",
        "    preferencias TEXT[],",
        "    completude_pct INTEGER DEFAULT 0",
        ");",
        "DELETE FROM briefings;",
        "DELETE FROM leads; ",
        ""
    ]
    
    print(f"📝 Gerando SQL para 50 leads (criptografados)...")
    for i in range(50):
        lead_id = str(uuid.uuid4())
        nome_puro = f"{random.choice(nomes_base)} {i}"
        tel_puro = f"55119{random.randint(10000000, 99999999)}"
        
        # Criptografia PII
        nome_enc = fernet.encrypt(nome_puro.encode()).decode()
        tel_enc = fernet.encrypt(tel_puro.encode()).decode()
        tel_hash = hmac_hash(tel_puro)
        
        status = random.choice(status_list)
        score = random.choice(score_list)
        data = (datetime.now(timezone.utc) - timedelta(days=random.randint(0, 15))).isoformat()
        
        # Insert Lead
        sql_lines.append(
            f"INSERT INTO leads (id, nome, telefone, telefone_hash, status, score, origem, criado_em) "
            f"VALUES ('{lead_id}', '{nome_enc}', '{tel_enc}', '{tel_hash}', '{status}', '{score}', 'whatsapp', '{data}');"
        )
        
        # Insert Briefing
        destino = random.choice(destinos)
        pct = random.randint(20, 100)
        sql_lines.append(
            f"INSERT INTO briefings (lead_id, destino, completude_pct) "
            f"VALUES ('{lead_id}', '{destino}', {pct});"
        )

    with open("scripts/seed_data.sql", "w", encoding="utf-8") as f:
        f.write("\n".join(sql_lines))
    
    print("✅ Arquivo 'backend/scripts/seed_data.sql' gerado com sucesso!")

if __name__ == "__main__":
    generate_sql()
