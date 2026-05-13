# Cadife Smart Travel — Architecture Plan
## RAG-Priority LangGraph Multi-Agent System

**Versão:** 2.0 — LangGraph Edition  
**Data:** 2026-05-07  
**Status:** Implementado

---

## 1. Visão Geral

O sistema de IA da Cadife Tour opera como um ecossistema de multi-agentes orquestrado por **LangGraph**, com **RAG como Regra de Ouro**: a base de conhecimento interna é sempre consultada **antes** de qualquer resposta do LLM.

### Por que RAG-First é fundamental para a Cadife

| Vantagem | Impacto |
|---|---|
| **Autoridade** | Se a Cadife tem acordo exclusivo com um hotel em Portugal, a IA vende ESSE hotel — não um aleatório do treinamento geral |
| **Consistência** | Todos os clientes recebem as mesmas informações sobre taxas e prazos |
| **Facilidade de atualização** | Preço mudou? Atualiza o documento na base RAG. Zero mudanças de código |

---

## 2. Diagrama do Fluxo LangGraph

```
WhatsApp Message
       │
       ▼
┌─────────────────┐
│  security_gate  │──── prompt injection? ──▶ END (recusa imediata)
└────────┬────────┘
         │ limpo
         ▼
┌─────────────────┐
│    triagem      │  TriagemAgent (mistral-small:free)
│                 │  · get_lead_context_by_wa_id (CRM lookup)
│                 │  · Identifica: novo/recorrente, next_field
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│              rag_mandatory  ★ REGRA DE OURO ★           │
│                                                         │
│  Query = mensagem + destino_do_briefing + perfil        │
│  Hybrid Search = Vetorial (Gemini embeddings)           │
│                + Keyword (tokenização)                  │
│                + RRF Reranking                          │
│  k=4 chunks mais relevantes → rag_context              │
└────────┬────────────────────────────────────────────────┘
         │ rag_context sempre populado antes do LLM
         ▼
┌─────────────────┐
│  build_context  │  Monta system prompt com:
│                 │  · CRM block (campos coletados, próximo campo)
│                 │  · RAG context (verdade absoluta Cadife)
│                 │  · Saudação inteligente (24h threshold)
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────┐
│              orchestrator  (Tier 2)                     │
│                                                         │
│  Modelo: google/gemini-2.0-flash-001                    │
│  Fallback: baidu/ernie:free → nemotron → mistral-small  │
│                                                         │
│  Tools disponíveis:                                     │
│  · query_project_scope  → RAG on-demand                 │
│  · persist_lead_data    → salva briefing no PostgreSQL  │
│  · check_availability   → slots de curadoria            │
│  · generate_travel_image → recraft-v4 (inspiracional)  │
│                                                         │
│  max_tool_rounds=4 (suporta cadeia: persist→check→img) │
└────────┬────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ validate_output │  · Code leak detector (_CODE_LEAK_RE)
│                 │  · Hallucination detector (preço, disponibilidade)
│                 │  · Substitui por fallback seguro se detectado
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│confusion_tracker│  · Detecta campo repetido ≥ 2x
│                 │  · Alerta silencioso ao consultor
└────────┬────────┘
         │
         ▼
    Resposta AYA → WhatsApp
```

---

## 3. Modelos OpenRouter por Função

| Função | Modelo | Justificativa |
|---|---|---|
| Chat / Conversação | `google/gemini-2.0-flash-001` | Estável, rápido, multimodal, sem sufixo `:free` para SLA consistente |
| Triagem (CRM JSON) | `mistralai/mistral-small-3.1-24b-instruct:free` | Especializado em extração estruturada, custo zero |
| Transcrição de áudio | `google/chirp-3` | STT de alta precisão para briefings via áudio |
| Análise de imagens | `google/gemini-2.0-flash-001` | Vision multimodal nativo |
| Embeddings RAG | `google/gemini-embedding-2-preview` | Alta qualidade semântica, dimensão 3072 |
| Geração de imagens | `recraft-ai/recraft-v3` | Imagens inspiracionais de viagem ao final do briefing |
| Fallback econômico | `baidu/ernie-4.5-turbo-preview:free` | Redundância quando modelos primários estão em 429/503 |
| Whisper (primário) | `openai/whisper-large-v3` | Transcrição via `/audio/transcriptions`, mais preciso |

### Cadeia de Fallback Automática

```
OrquestradorAgent:
  gemini-2.0-flash-001 → [429/503] → baidu/ernie:free → nemotron:free → mistral-small:free

TriagemAgent:
  mistral-small:free → [429/503] → qwen-2-72b:free → llama-3.1-8b:free

Áudio (transcriçãob):
  whisper-large-v3 (/audio/transcriptions) → [falha] → chirp-3 (multimodal fallback)
```

---

## 4. RAG: Hybrid Search com RRF

### Pipeline de Retrieval

```
Query do usuário
    + destino do briefing (se preenchido)
    + perfil do briefing (se preenchido)
         │
         ▼
┌────────────────────────────────────────┐
│           ChromaDB (dev)               │
│         PGVector (prod)                │
│                                        │
│  1. Vector Search (Gemini embeddings)  │
│     k = 4 × multiplier (= 12)          │
│     → 12 candidatos por similaridade   │
│                                        │
│  2. Keyword Score                      │
│     Tokenização + overlap normalizado  │
│     → ranking por sobreposição léxica  │
│                                        │
│  3. RRF Fusion (k=60)                  │
│     score = 1/(60+rank_v) +            │
│             0.5/(60+rank_k)            │
│     → reranking combinado              │
│                                        │
│  4. Guardrails (context_guardrails)    │
│     Remove chunks inseguros            │
└────────────────────────────────────────┘
         │
         ▼
    4 chunks mais relevantes → rag_context
```

### Base de Conhecimento (knowledge_base/)

| Documento | Conteúdo |
|---|---|
| `identidade_empresa.txt` | Proposta de valor, diferenciais, missão |
| `destinos.txt` | Destinos, características, época ideal |
| `experiencias_exclusivas.md` | Parcerias exclusivas, experiências premium |
| `perfis_e_solucoes.md` | Soluções por perfil (casal, família, solo) |
| `logistica_especialista.md` | Visto, passaporte, documentação |
| `regras_negocio.txt` | Políticas, prazos, condições |
| `faq.txt` | Dúvidas frequentes |
| `objecoes.txt` | Como tratar objeções comuns |
| `fluxo_atendimento.txt` | Processo completo de curadoria |
| `argumentacao.txt` | Argumentos de venda éticos |

---

## 5. Fluxo de Estados do Lead

```
NOVO → EM_ATENDIMENTO → QUALIFICADO → AGENDADO → PROPOSTA → FECHADO
                                    ↘              ↗
                        (qualquer estado) → PERDIDO (30 dias sem resposta)
```

### Briefing — Sequência de Coleta (obrigatória)

```
Destino → Datas → Nº pessoas → Perfil → Orçamento → Passaporte → [COMPLETO ≥ 60%]
                                                                        │
                                                                        ▼
                                                              generate_travel_image
                                                              check_availability
                                                              Oferta de curadoria
```

---

## 6. Multimodal Pipeline

### Áudio (briefing por voz)

```
WhatsApp Audio (OGG/MP4/AAC)
    │
    ▼
model_router.transcribe_audio()
    │
    ├─ Tentativa 1: whisper-large-v3 via /audio/transcriptions
    │                    │ sucesso → texto transcrito
    │                    │ falha →
    └─ Tentativa 2: chirp-3 via /chat/completions (multimodal)
                         │
                         ▼
                 Texto → multi_agent_orchestrator.orchestrate()
                         (extrai entidades: datas, destinos, pessoas)
```

### Imagem (análise de preferências)

```
WhatsApp Image (JPEG/PNG)
    │
    ▼
model_router.analyze_image()
    │  gemini-2.0-flash-001 (vision)
    │  Prompt: "Identifique preferências de viagem nesta imagem"
    ▼
Descrição textual → orchestrate()
    (IA infere: praia, aventura, luxo, cultural...)
```

### Imagem Inspiracional (pós-briefing)

```
Briefing completude ≥ 60%
    │
    ▼
orchestrator chama generate_travel_image(destino, perfil, estilo)
    │
    ▼
ai_tools._generate_travel_image()
    │  recraft-ai/recraft-v3 via /images/generations
    │  Prompt: "Beautiful {destino}, {perfil} travel, {estilo_desc}"
    ▼
URL da imagem → resposta AYA → WhatsApp (link para o cliente)
```

---

## 7. Humanização das Respostas RAG

A IA **nunca copia o RAG literalmente**. O system prompt instrui:

| ❌ Errado | ✅ Correto |
|---|---|
| "Segundo a base de conhecimento..." | "Olha, dei uma olhada nos nossos roteiros exclusivos e vi que..." |
| "De acordo com os documentos internos..." | "Verificando aqui no nosso portfólio, temos algo especial..." |
| Copiar e colar o chunk | Reformular com tom consultivo caloroso |

---

## 8. Segurança em Camadas

| Camada | Mecanismo | Localização |
|---|---|---|
| Pré-LLM | `should_block()` + `security_gate` node | `prompt_security.py` + orquestrador |
| Input | `sanitize_user_input()` | `prompt_security.py` |
| RAG | `apply_guardrails()` + `wrap_rag_context()` | `context_guardrails.py` |
| Output | `_check_hallucinations()` + `_CODE_LEAK_RE` | `validate_output` node |
| Prompt | Sandbox de dados, anti-injection no system prompt | `_ORCHESTRATOR_SYSTEM_TEMPLATE` |
| Tool | Whitelist de campos (`_ALLOWED_PERSIST_FIELDS`) | `ai_tools.py` |

---

## 9. Observabilidade

- **Logs estruturados:** `structlog` em todos os nós do grafo
- **Métricas por nó:** latência total, chars do RAG, modelo usado, campo coletado
- **Alertas:** hallucinations + confusão → `alert_service.notify_hallucination()`
- **Langfuse:** tracing opcional das chains LangChain (`ai_service.py`)
- **Prometheus:** métricas HTTP via `infrastructure/metrics/prometheus.py`

---

## 10. Dependências-chave

```
langgraph>=0.2.0       # StateGraph + nós assíncronos
langchain              # Chains de extração de briefing
langchain-openai       # ChatOpenAI → OpenRouter
langchain-chroma       # Vectorstore ChromaDB
httpx                  # Calls diretas OpenRouter (agentes, imagem)
structlog              # Logs estruturados
```
