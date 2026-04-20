# Contrato: API REST — Cadife Smart Travel Backend

## Objetivo

Contrato de fronteira entre o backend FastAPI e os consumidores (App Flutter, integrações externas). Todo endpoint listado aqui deve ser implementado com os schemas exatos abaixo.

**Base URL (produção):** `https://api.cadife.com.br/v1`
**Base URL (desenvolvimento):** `http://localhost:8000`
**Documentação interativa:** `GET /docs` (Swagger UI)

---

## 1. Webhook WhatsApp

### `GET /webhook/whatsapp` — Verificação Meta Challenge
```
Query params: hub.mode, hub.verify_token, hub.challenge
Resposta 200: hub.challenge (plain text)
Resposta 403: { "detail": "Forbidden" }
```

### `POST /webhook/whatsapp` — Recebimento de mensagens
```
Headers: X-Hub-Signature-256: sha256=<hmac>
Body: payload bruto da Meta (JSON)
Resposta 200: { "status": "received" }       ← sempre, imediatamente
Resposta 403: { "detail": "Invalid signature" }
```

---

## 2. IA / Processamento

### `POST /ia/processar` — Processar mensagem isolada
```json
// Request
{
  "phone": "5511999999999",
  "message": "Quero viajar para Portugal em fevereiro",
  "lead_id": "uuid-opcional"
}

// Response 200
{
  "response": "Que destino lindo! Você já tem datas em mente para a viagem a Portugal?",
  "lead_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "briefing_updated": true,
  "completude_pct": 35
}
```

### `POST /ia/extrair-briefing` — Extração estruturada de conversa
```json
// Request
{
  "lead_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "conversation": [
    {"role": "user", "content": "Quero ir a Portugal com minha família"},
    {"role": "assistant", "content": "Quantas pessoas vão viajar?"},
    {"role": "user", "content": "Somos 4, duas crianças. Em fevereiro por 10 dias"}
  ]
}

// Response 200
{
  "destino": "Portugal",
  "data_ida": null,
  "data_volta": null,
  "qtd_pessoas": 4,
  "perfil": "família",
  "tipo_viagem": ["turismo"],
  "preferencias": [],
  "orcamento": null,
  "tem_passaporte": null,
  "observacoes": "duas crianças, 10 dias em fevereiro",
  "completude_pct": 40
}
```

### `GET /ia/status` — Health check da IA
```json
// Response 200
{
  "status": "ok",
  "model": "gpt-4o-mini",
  "rag_documents": 142,
  "vector_db": "chromadb"
}
```

---

## 3. Leads

### `GET /leads` — Listar leads com filtros
```
Auth: Bearer JWT (obrigatório)
Query params:
  status: novo | em_atendimento | qualificado | agendado | proposta | fechado | perdido
  score: quente | morno | frio
  destino: string (busca parcial)
  search: string (nome ou telefone)
  page: int (default: 1)
  limit: int (default: 20, max: 100)
  order_by: criado_em | atualizado_em | score (default: criado_em)

// Response 200
{
  "items": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "nome": "Maria Silva",
      "telefone": "5511999999999",
      "origem": "whatsapp",
      "status": "qualificado",
      "score": "quente",
      "destino": "Portugal",
      "criado_em": "2025-06-01T10:30:00Z",
      "atualizado_em": "2025-06-01T11:45:00Z",
      "completude_pct": 85
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20,
  "pages": 3
}
```

### `POST /leads` — Criar lead manualmente
```json
// Request (Auth: Bearer JWT)
{
  "nome": "João Pereira",
  "telefone": "5521988887777",
  "origem": "app"
}

// Response 201
{
  "id": "uuid",
  "nome": "João Pereira",
  "telefone": "5521988887777",
  "origem": "app",
  "status": "novo",
  "score": null,
  "criado_em": "2025-06-01T10:00:00Z",
  "atualizado_em": "2025-06-01T10:00:00Z"
}
```

### `GET /leads/{id}` — Detalhe do lead
```json
// Auth: Bearer JWT
// Response 200
{
  "id": "uuid",
  "nome": "Maria Silva",
  "telefone": "5511999999999",
  "origem": "whatsapp",
  "status": "qualificado",
  "score": "quente",
  "consultor_id": null,
  "is_archived": false,
  "criado_em": "2025-06-01T10:30:00Z",
  "atualizado_em": "2025-06-01T11:45:00Z",
  "briefing": {
    "destino": "Portugal",
    "data_ida": "2026-02-10",
    "data_volta": "2026-02-20",
    "qtd_pessoas": 3,
    "perfil": "família",
    "tipo_viagem": ["turismo", "imigração"],
    "preferencias": ["cidade", "cultura"],
    "orcamento": "médio",
    "tem_passaporte": true,
    "observacoes": "primeira viagem internacional da família",
    "completude_pct": 85
  }
}
```

### `PUT /leads/{id}` — Atualizar lead
```json
// Auth: Bearer JWT
// Request (campos parciais aceitos)
{
  "status": "agendado",
  "score": "quente",
  "consultor_id": "uuid-do-consultor"
}

// Response 200 — lead atualizado completo
```

### `DELETE /leads/{id}` — Arquivar lead (soft delete)
```
// Auth: Bearer JWT
// Response 204 No Content
// Nota: sets is_archived=true, nunca deleta fisicamente
```

### `GET /leads/{id}/interacoes` — Histórico de conversas
```json
// Auth: Bearer JWT
// Response 200
{
  "items": [
    {
      "id": "uuid",
      "mensagem_cliente": "Quero viajar para Portugal",
      "mensagem_ia": "Que destino maravilhoso! Você já tem datas em mente?",
      "tipo_mensagem": "texto",
      "timestamp": "2025-06-01T10:30:00Z"
    }
  ],
  "total": 18
}
```

### `GET /leads/{id}/briefing` — Briefing estruturado
```json
// Auth: Bearer JWT — resposta com schema completo do briefing (ver seção 3.2 em architecture.md)
```

### `PUT /leads/{id}/briefing` — Atualizar briefing manualmente
```json
// Auth: Bearer JWT
// Request (campos parciais aceitos)
{
  "destino": "Lisboa, Portugal",
  "orcamento": "alto",
  "observacoes": "Cliente prefere hotéis boutique no centro histórico"
}
// Response 200 — briefing atualizado com novo completude_pct
```

---

## 4. Agenda

### `GET /agenda/disponibilidade` — Slots disponíveis
```
Auth: Bearer JWT
Query params:
  data_inicio: date (ISO 8601)
  data_fim: date (ISO 8601)

// Response 200
{
  "slots": [
    { "data": "2025-06-02", "hora": "09:00", "disponivel": true },
    { "data": "2025-06-02", "hora": "10:00", "disponivel": false },
    { "data": "2025-06-02", "hora": "11:00", "disponivel": true }
  ]
}
// Regras: Seg-Sex, 09h-16h, máx 6/dia, intervalo mínimo 1h
```

### `POST /agenda` — Criar agendamento
```json
// Auth: Bearer JWT
// Request
{
  "lead_id": "uuid",
  "data": "2025-06-03",
  "hora": "10:00",
  "tipo": "online",
  "consultor_id": "uuid-opcional"
}

// Response 201
{
  "id": "uuid",
  "lead_id": "uuid",
  "data": "2025-06-03",
  "hora": "10:00",
  "status": "pendente",
  "tipo": "online",
  "consultor_id": "uuid",
  "criado_em": "2025-06-01T15:00:00Z"
}

// Response 422 — se slot indisponível ou fora das regras de negócio
{
  "detail": "Slot indisponível: máximo de 6 atendimentos atingido para esta data"
}
```

### `PUT /agenda/{id}` — Atualizar status do agendamento
```json
// Auth: Bearer JWT
// Request
{ "status": "confirmado" }
// Response 200 — agendamento atualizado
```

---

## 5. Propostas

### `POST /propostas` — Criar proposta
```json
// Auth: Bearer JWT
// Request
{
  "lead_id": "uuid",
  "descricao": "Pacote Portugal 10 dias — Lisboa + Porto",
  "valor_estimado": 8500.00
}

// Response 201
{
  "id": "uuid",
  "lead_id": "uuid",
  "descricao": "Pacote Portugal 10 dias — Lisboa + Porto",
  "valor_estimado": 8500.00,
  "status": "rascunho",
  "consultor_id": "uuid",
  "criado_em": "2025-06-01T16:00:00Z"
}
```

### `PUT /propostas/{id}` — Atualizar proposta
```json
// Auth: Bearer JWT
// Request (campos parciais)
{ "status": "enviada" }
// Response 200 — proposta atualizada
```

---

## 6. Autenticação e Usuários

### `POST /auth/login` — Login
```json
// Request
{ "email": "consultor@cadife.com.br", "password": "senha123" }

// Response 200
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 3600
}

// Response 401
{ "detail": "Credenciais inválidas" }
```

### `POST /auth/refresh` — Renovar token
```json
// Request
{ "refresh_token": "eyJhbGciOiJIUzI1NiJ9..." }
// Response 200 — novo access_token + refresh_token
```

### `GET /users/me` — Perfil do usuário autenticado
```json
// Auth: Bearer JWT
// Response 200
{
  "id": "uuid",
  "email": "consultor@cadife.com.br",
  "nome": "Nikolas Tesch",
  "perfil": "agencia",
  "is_active": true,
  "criado_em": "2025-01-01T00:00:00Z"
}
```

### `POST /users/fcm-token` — Registrar token FCM
```json
// Auth: Bearer JWT
// Request
{ "fcm_token": "cX8r9k..." }
// Response 200
{ "message": "Token FCM registrado com sucesso" }
```

---

## 7. Códigos de Erro Padrão

| Código | Significado | Quando ocorre |
|---|---|---|
| `400` | Bad Request | Payload malformado |
| `401` | Unauthorized | JWT ausente ou expirado |
| `403` | Forbidden | Assinatura webhook inválida ou sem permissão |
| `404` | Not Found | Lead/agendamento/proposta não encontrado |
| `409` | Conflict | Telefone duplicado ao criar lead |
| `422` | Unprocessable Entity | Validação Pydantic falhou ou regra de negócio violada |
| `429` | Too Many Requests | Rate limit excedido |
| `500` | Internal Server Error | Erro não tratado (log obrigatório) |

Formato padrão de erro:
```json
{ "detail": "Mensagem descritiva do erro" }
```
