# Guia: Configurar e Rodar o Docker Localmente

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando
- [ngrok](https://ngrok.com/download) instalado (necessário para receber webhooks do WhatsApp)
- Credenciais do projeto (WhatsApp/Meta, OpenAI, Firebase)

Verifique se o Docker está ativo:
```bash
docker --version
docker compose version
```

---

## 1. Configurar o arquivo `.env`

Copie o exemplo e preencha com suas credenciais reais:

```bash
cp backend/.env.example backend/.env
```

Abra `backend/.env` e preencha os campos obrigatórios:

```env
# ── WhatsApp Cloud API (Meta) ─────────────────────────────────────────────
WHATSAPP_TOKEN=seu_token_de_acesso_meta
PHONE_NUMBER_ID=seu_phone_number_id_meta
VERIFY_TOKEN=cadife_verify_token_change_me   # escolha qualquer string, anote — usará no ngrok

# ── OpenAI ────────────────────────────────────────────────────────────────
OPENAI_API_KEY=sk-...

# ── PostgreSQL (já configurado para o container) ──────────────────────────
DATABASE_URL=postgresql+asyncpg://cadife:cadife@db:5432/cadife_db
#                                                   ↑ "db" = nome do serviço no docker-compose

# ── JWT ───────────────────────────────────────────────────────────────────
JWT_SECRET_KEY=troque-por-string-aleatoria-segura

# ── ChromaDB ──────────────────────────────────────────────────────────────
CHROMA_PERSIST_DIR=./chroma_db

# ── Firebase (opcional — necessário para notificações push) ───────────────
FIREBASE_CREDENTIALS=./firebase_credentials.json
```

> **Atenção:** O valor de `DATABASE_URL` deve usar `@db:` (nome do serviço Docker), não `@localhost:`, quando rodando dentro do container.

---

## 2. (Opcional) Credenciais Firebase

Se for usar notificações push (FCM), coloque o arquivo JSON da service account dentro de `backend/`:

```bash
cp ~/Downloads/firebase-adminsdk-xxx.json backend/firebase_credentials.json
```

---

## 3. Subir os containers

Execute a partir da **raiz do projeto**:

```bash
docker compose -f docker/docker-compose.yml up --build
```

O comando sobe três serviços:

| Serviço | Porta local | Função |
|---|---|---|
| `backend` | `8000` | FastAPI + AYA |
| `db` | `5432` | PostgreSQL 16 |
| `chroma` | `8001` | ChromaDB (vector store RAG) |

Para rodar em background (modo daemon):
```bash
docker compose -f docker/docker-compose.yml up --build -d
```

---

## 4. Rodar as migrations do banco

Após os containers estarem de pé, aplique as migrations do Alembic:

```bash
docker compose -f docker/docker-compose.yml exec backend alembic upgrade head
```

Confira se o banco foi criado corretamente:
```bash
docker compose -f docker/docker-compose.yml exec db psql -U cadife -d cadife_db -c "\dt"
```

---

## 5. Verificar se o backend está saudável

```bash
curl http://localhost:8000/health
```

Resposta esperada:
```json
{"status": "ok"}
```

Documentação interativa da API:
- Swagger UI → [http://localhost:8000/docs](http://localhost:8000/docs)
- Redoc → [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

## 6. Expor o webhook com ngrok

O WhatsApp exige uma URL HTTPS pública para entregar mensagens. Use o ngrok:

```bash
ngrok http 8000
```

O ngrok exibirá uma URL do tipo `https://abc123.ngrok-free.app`. Copie-a.

No painel da Meta (Developers → WhatsApp → Configuration), configure:
- **Webhook URL:** `https://abc123.ngrok-free.app/webhook/whatsapp`
- **Verify Token:** o mesmo valor que você colocou em `VERIFY_TOKEN` no `.env`

---

## 7. Comandos úteis do dia a dia

```bash
# Ver logs em tempo real
docker compose -f docker/docker-compose.yml logs -f backend

# Reiniciar apenas o backend (após alterar código)
docker compose -f docker/docker-compose.yml restart backend

# Parar todos os containers
docker compose -f docker/docker-compose.yml down

# Parar e apagar volumes (limpa banco e chroma — use com cuidado)
docker compose -f docker/docker-compose.yml down -v

# Abrir shell dentro do container do backend
docker compose -f docker/docker-compose.yml exec backend bash

# Criar nova migration após alterar models
docker compose -f docker/docker-compose.yml exec backend alembic revision --autogenerate -m "descricao_da_mudanca"

# Aplicar migrations pendentes
docker compose -f docker/docker-compose.yml exec backend alembic upgrade head
```

---

## 8. Solução de problemas comuns

**Container do backend não sobe / erro de conexão com o banco:**
- Verifique se `DATABASE_URL` usa `@db:5432` e não `@localhost:5432`
- O `depends_on` já aguarda o healthcheck do Postgres, mas se o erro persistir, aguarde alguns segundos e reinicie: `docker compose ... restart backend`

**Porta 5432 já em uso:**
- Pare o PostgreSQL local: `brew services stop postgresql` (macOS)

**Porta 8000 já em uso:**
- Identifique o processo: `lsof -i :8000`
- Ou altere a porta no `docker-compose.yml`: `"8080:8000"`

**Erro `ModuleNotFoundError` no backend:**
- Reconstrua a imagem para instalar dependências novas:
```bash
docker compose -f docker/docker-compose.yml up --build
```

**ngrok sessão expirada:**
- Reinicie o ngrok e atualize a URL no painel da Meta.
