## 3. Arquitetura do Sistema

### 3.1 Visão de Alto Nível

O sistema é composto por 4 camadas principais que se comunicam de forma assíncrona e em tempo real:

| Camada 1 | Camada 2 | Camada 3 | Camada 4 |
|---|---|---|---|
| **ENTRADA** WhatsApp Cloud API + Webhook FastAPI | **PROCESSAMENTO** Orquestrador FastAPI + LangChain + RAG | **PERSISTÊNCIA** Banco de Dados PostgreSQL / MongoDB | **APRESENTAÇÃO** App Flutter + Firebase FCM |

### 3.2 Fluxo de Dados Completo

Fluxo principal de ponta a ponta (WhatsApp → App):

1. Cliente envia mensagem via WhatsApp
2. WhatsApp Cloud API entrega payload ao webhook (`POST /webhook/whatsapp`)
3. Backend extrai tipo e conteúdo da mensagem (texto, áudio, imagem)
4. Orquestrador chama a camada de IA (LangChain + RAG)
5. IA processa: recupera contexto da base (RAG), gera resposta e extrai dados estruturados do briefing
6. Motor de decisão avalia: briefing completo? → oferecer curadoria | incompleto? → continuar coleta
7. Lead é criado ou atualizado no banco de dados com dados extraídos
8. Resposta é enviada ao cliente via API do WhatsApp
9. Firebase FCM notifica a agência: 'Novo lead recebido' (< 2 segundos)
10. Dashboard Flutter exibe o lead em tempo real com dados estruturados

### 3.3 Stack Tecnológico

| Camada | Tecnologia | Justificativa |
|---|---|---|
| **Backend / API** | FastAPI (Python) | Alta performance assíncrona, tipagem com Pydantic, suporte nativo a async/await e ecossistema Python para IA |
| **IA / Orquestração** | LangChain + OpenAI GPT | Cadeia de processos para RAG, extração de entidades, memória de conversação e roteamento de fluxo |
| **Vector DB (RAG)** | ChromaDB ou PGVector | Chroma para desenvolvimento local; PGVector para produção integrado ao PostgreSQL |
| **Banco de Dados** | PostgreSQL (preferencial) ou MongoDB | PostgreSQL recomendado pelo suporte ao PGVector e ACID; MongoDB como alternativa para flexibilidade de schema |
| **Frontend / App** | Flutter (Dart) | Multiplataforma (Android + iOS + Web), performance nativa, single codebase para os dois perfis de usuário |
| **Notificações** | Firebase Cloud Messaging (FCM) | Push notifications confiáveis em tempo real para Android e iOS |
| **WhatsApp** | WhatsApp Cloud API (Meta) | API oficial, sem custo de mensagens para a empresa, suporte a webhook, multi-mídia e templates |
| **Infraestrutura** | Docker + Docker Compose | Containerização do backend, banco e IA para portabilidade e deploy simplificado (LXC compatível) |
| **Autenticação** | JWT + Firebase Auth | JWT para API, Firebase Auth para login no app com suporte a e-mail, Google e OTP |
| **CI/CD / Versionamento** | GitHub + GitHub Actions | Repositório monorepo, pull requests, code review e pipeline de deploy automatizado |

### 3.4 Estrutura de Pastas (Monorepo)

| Diretório | Responsabilidade |
|---|---|
| `cadife_smart_travel/` | Raiz do monorepo |
| `├── backend/` | API FastAPI + IA + integração WhatsApp |
| `│   ├── app/routes/` | Endpoints: webhook, leads, auth, agenda |
| `│   ├── app/services/` | ai_service, rag_service, whatsapp_service |
| `│   ├── app/models/` | Modelos de dados Pydantic: Lead, Briefing, User |
| `│   ├── app/core/` | Configurações, middlewares, segurança |
| `│   └── Dockerfile` | Containerização do backend |
| `├── frontend_flutter/` | App Flutter (cliente + agência) |
| `│   ├── lib/features/auth/` | Telas e lógica de autenticação |
| `│   ├── lib/features/client/` | Perfil cliente: status, histórico, docs |
| `│   ├── lib/features/agency/` | Perfil agência: dashboard, leads, agenda |
| `│   ├── lib/services/` | api_service.dart, notification_service.dart |
| `│   └── lib/core/theme/` | AppTheme, constantes, cores da Cadife |
| `├── docs/` | Documentação técnica, diagramas, Swagger |
| `├── docker/` | docker-compose.yml, configurações |
| `└── .env.example` | Variáveis de ambiente (template) |
