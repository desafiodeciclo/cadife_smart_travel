# CADIFE SMART TRAVEL — Project Specification v1.0

> **CONFIDENCIAL — Uso Interno do Time de Desenvolvimento**

**Plataforma de Atendimento Inteligente via WhatsApp + App Flutter**
**ESPECIFICAÇÃO TÉCNICA DO PROJETO**
*Project Specification Document | MVP v1.0*

| Campo | Valor |
|---|---|
| **Versão** | 1.1.0 — MVP |
| **Projeto** | Cadife Smart Travel |
| **Cliente** | Cadife Tour |
| **Prazo MVP** | 25 dias |
| **Data** | Maio 2026 |
| **Status** | **CONCLUÍDO — 19/19 specs entregues** |

---

## 1. Visão Geral do Projeto

### 1.1 Contexto e Problema

A Cadife Tour é uma agência de turismo especializada em curadoria personalizada, operando no modelo consultivo multibandeiras. Seu modelo atual de atendimento apresenta dois gargalos críticos:

- **Atendimento manual e não escalável:** representantes perdem horas respondendo às mesmas dúvidas via WhatsApp antes de identificar o potencial real do lead.
- **Perda de informações e falta de visibilidade:** dados coletados em conversas informais não são estruturados, dificultando a gestão do pipeline de vendas.

### 1.2 Proposta de Solução

O Cadife Smart Travel é uma plataforma integrada composta por três camadas funcionais:

- **Atendimento automatizado via WhatsApp com IA (RAG + LangChain):** o assistente virtual 'AYA' recebe o cliente, coleta briefing estruturado e qualifica o lead.
- **Backend inteligente (FastAPI):** orquestra o fluxo de dados, aplica regras de negócio, persiste leads e aciona notificações.
- **Aplicativo Flutter (CRM):** dois perfis — Cliente (acompanhamento do status da viagem) e Agência (dashboard de leads, pipeline comercial, gestão de atendimentos).

### 1.3 Objetivo do MVP

Construir em 25 dias um sistema funcional ponta a ponta que:

- Automatize a triagem inicial de leads via WhatsApp
- Estruture dados do briefing do cliente com extração automática por IA
- Disponibilize dashboard para a agência visualizar e gerenciar leads
- Envie notificações push em tempo real (< 2 segundos) ao consultor
- Preserve o atendimento humanizado como pilar central da Cadife Tour

### 1.4 Princípio Estratégico

O sistema **NÃO** substitui o consultor humano. A IA atua como pré-atendente, preparando o terreno para que o consultor humano realize a curadoria, montagem de proposta e fechamento da venda. A automação completa de orçamentos está fora do escopo do MVP.

---

## 2. Escopo do Projeto

### 2.1 Dentro do Escopo — MVP (25 dias)

| Funcionalidade | Prioridade | Status MVP |
|---|---|---|
| Webhook WhatsApp Cloud API | **CRÍTICO** | ✅ **CONCLUÍDO** |
| Assistente IA com RAG (LangChain) | **CRÍTICO** | ✅ **CONCLUÍDO** |
| Coleta estruturada de briefing | **CRÍTICO** | ✅ **CONCLUÍDO** |
| Criação automática de leads | **CRÍTICO** | ✅ **CONCLUÍDO** |
| App Flutter — Perfil Agência (CRM) | **CRÍTICO** | 🔄 **EM ANDAMENTO** (auth/perfil/config restantes) |
| App Flutter — Perfil Cliente | **ALTA** | ✅ **CONCLUÍDO** |
| Notificações Push (Firebase FCM) | **ALTA** | ✅ **CONCLUÍDO** |
| Autenticação (Auth) no App | **ALTA** | ✅ **CONCLUÍDO** |
| Base de conhecimento RAG da Cadife | **ALTA** | ✅ **CONCLUÍDO** |
| Score de qualificação de leads | **MÉDIA** | ✅ **CONCLUÍDO** |
| Agendamento básico de curadoria | **MÉDIA** | ✅ **CONCLUÍDO** |
| Tratamento de mídias (áudio/imagem) | **MÉDIA** | Fase 4 — Em andamento |
| Documentação API (Swagger) | **MÉDIA** | Fase 4 — Pendente |
| Docker / containerização | **BAIXA** | Fase 4 — Pendente |

### 2.2 Fora do Escopo — MVP

- Integração direta com operadoras (ex: Amadeus, emissão de passagens)
- Geração automática de orçamentos ou preços
- Automação completa do ciclo de vendas (checkout sem humano)
- Pagamentos online dentro do app
- Motor próprio de recomendação de destinos
- Sugestão de valores médios por destino pela IA
- Recomendação de viagem gerada automaticamente

### 2.3 Evolução Pós-MVP (Roadmap)

| Fase | Nome | Escopo |
|---|---|---|
| **Fase 2** | Inteligência Comercial | Score avançado de leads, templates de resposta, sugestões de destinos por perfil |
| **Fase 3** | Integração de APIs | Integração com Amadeus (busca de voos), sugestões reais sem venda automatizada |
| **Fase 4** | Pré-Orçamento | Combinações simples voo + hotel apresentadas como 'sugestão inicial' |
| **Fase 5** | Automação Assistida | Geração semi-automática de proposta, humano apenas valida |
| **Fase 6** | SaaS Escalável | Produto para múltiplas agências, catálogo próprio, venda parcial automatizada |

---

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
| **IA / Orquestração** | LangChain + Google Gemini | Cadeia de processos para RAG, extração de entidades, memória de conversação e roteamento de fluxo (migrado de OpenAI GPT para Gemini) |
| **Vector DB (RAG)** | ChromaDB ou PGVector | Chroma para desenvolvimento local; PGVector para produção integrado ao PostgreSQL |
| **Banco de Dados** | PostgreSQL (preferencial) ou MongoDB | PostgreSQL recomendado pelo suporte ao PGVector e ACID; MongoDB como alternativa para flexibilidade de schema |
| **Frontend / App** | Flutter (Dart) — Riverpod + GoRouter + Isar | Multiplataforma (Android + iOS + Web), offline-first (Hive + Isar), autenticação biométrica, certificate pinning, dois perfis de usuário |
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

---

## 4. Modelagem de Dados

### 4.1 Entidade: LEAD

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único gerado automaticamente |
| `nome` | String | Não | Nome extraído pela IA ou informado pelo cliente |
| `telefone` | String | **Sim** | Número WhatsApp — chave de identificação do contato |
| `origem` | Enum | **Sim** | Canal de entrada: `whatsapp` \| `app` \| `web` |
| `status` | Enum | **Sim** | `novo` \| `em_atendimento` \| `qualificado` \| `agendado` \| `proposta` \| `fechado` \| `perdido` |
| `score` | Enum | Não | Temperatura do lead: `quente` \| `morno` \| `frio` |
| `criado_em` | DateTime | **Sim** | Timestamp da criação do registro |
| `atualizado_em` | DateTime | **Sim** | Timestamp da última atualização |

### 4.2 Entidade: BRIEFING

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead pai |
| `destino` | String | Não | Destino desejado extraído pela IA |
| `origem` | String | Não | Cidade/país de origem do cliente |
| `data_ida` | Date | Não | Data de partida desejada |
| `data_volta` | Date | Não | Data de retorno desejada |
| `duracao_dias` | Integer | Não | Duração calculada da viagem em dias |
| `qtd_pessoas` | Integer | Não | Número de viajantes |
| `perfil` | String | Não | Perfil: `casal` \| `família` \| `solo` \| `grupo` \| `amigos` |
| `tipo_viagem` | String[] | Não | `turismo` \| `lazer` \| `aventura` \| `imigração` \| `negócios` |
| `preferencias` | String[] | Não | `frio` \| `calor` \| `praia` \| `cidade` \| `luxo` \| `econômico` |
| `orcamento` | Enum | Não | `baixo` \| `médio` \| `alto` \| `premium` |
| `tem_passaporte` | Boolean | Não | Cliente possui passaporte válido |
| `observacoes` | String | Não | Observações livres extraídas da conversa |
| `completude_pct` | Integer | Não | Percentual de campos preenchidos (0–100) |

### 4.3 Entidade: INTERAÇÃO

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único da mensagem |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `mensagem_cliente` | Text | Não | Texto enviado pelo cliente |
| `mensagem_ia` | Text | Não | Resposta gerada pela IA |
| `tipo_mensagem` | Enum | **Sim** | `texto` \| `audio` \| `imagem` \| `documento` |
| `timestamp` | DateTime | **Sim** | Momento da interação |

### 4.4 Entidade: AGENDAMENTO

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `data` | Date | **Sim** | Data da curadoria |
| `hora` | Time | **Sim** | Horário do atendimento |
| `status` | Enum | **Sim** | `pendente` \| `confirmado` \| `realizado` \| `cancelado` |
| `tipo` | Enum | **Sim** | `online` \| `presencial` |
| `consultor_id` | UUID (FK) | Não | Consultor responsável pelo atendimento |

### 4.5 Entidade: PROPOSTA

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | UUID | **Sim** | Identificador único |
| `lead_id` | UUID (FK) | **Sim** | Referência ao lead |
| `descricao` | String | **Sim** | Resumo da proposta (ex: 'Pacote Portugal 10 dias') |
| `valor_estimado` | Decimal | Não | Valor estimado em BRL |
| `status` | Enum | **Sim** | `rascunho` \| `enviada` \| `aprovada` \| `recusada` \| `em_revisao` |
| `criado_em` | DateTime | **Sim** | Data de criação da proposta |

---

## 5. Endpoints da API (FastAPI)

### 5.1 Webhook WhatsApp

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/webhook/whatsapp` | Verificação do webhook pela Meta (challenge) | WhatsApp |
| **POST** | `/webhook/whatsapp` | Recebimento de mensagens em tempo real | WhatsApp |

### 5.2 IA e Processamento

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/ia/processar` | Processa mensagem e retorna resposta da IA | AI Core |
| **POST** | `/ia/extrair-briefing` | Extrai dados estruturados de uma conversa | AI Core |
| **GET** | `/ia/status` | Health check do serviço de IA | AI Core |
| **POST** | `/ia/reindexar` | Reindexa a base de conhecimento no Vector DB | AI Core |
| **GET** | `/ia/ingestion-status` | Status do pipeline de ingestão de documentos | AI Core |

### 5.3 Leads (CRM)

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/leads` | Lista todos os leads com filtros e paginação | Leads |
| **GET** | `/leads/my-active` | Retorna o lead ativo do usuário autenticado (perfil cliente) | Leads |
| **POST** | `/leads` | Cria novo lead (via webhook ou manual) | Leads |
| **GET** | `/leads/{id}` | Retorna detalhes de um lead específico | Leads |
| **PUT** | `/leads/{id}` | Atualiza dados ou status do lead | Leads |
| **DELETE** | `/leads/{id}` | Arquiva (soft delete) um lead | Leads |
| **GET** | `/leads/{id}/interacoes` | Histórico completo de conversas do lead | Leads |
| **POST** | `/leads/{id}/interacao` | Adiciona uma interação manual ao lead | Leads |
| **GET** | `/leads/{id}/briefing` | Briefing estruturado do lead | Leads |
| **PUT** | `/leads/{id}/briefing` | Atualiza briefing manualmente | Leads |

### 5.4 Agenda e Agendamentos

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/agenda/disponibilidade` | Retorna horários disponíveis para curadoria | Agenda |
| **POST** | `/agenda` | Cria novo agendamento | Agenda |
| **GET** | `/agenda/{id}` | Detalhe de um agendamento | Agenda |
| **PUT** | `/agenda/{id}` | Atualiza status do agendamento | Agenda |

### 5.5 Propostas

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/propostas` | Cria nova proposta para um lead | Propostas |
| **GET** | `/propostas/{id}` | Detalhe da proposta | Propostas |
| **PUT** | `/propostas/{id}` | Atualiza proposta ou status | Propostas |

### 5.6 Autenticação e Usuários

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/auth/login` | Login com e-mail e senha, retorna JWT | Auth |
| **POST** | `/auth/refresh` | Renova token JWT | Auth |
| **GET** | `/users/me` | Retorna perfil do usuário autenticado | Auth |
| **PATCH** | `/users/me` | Atualiza perfil do usuário autenticado | Auth |
| **POST** | `/users/fcm-token` | Registra token FCM do dispositivo | Auth |

---

## 6. Especificação da Inteligência Artificial (RAG)

### 6.1 Arquitetura da Camada de IA

A IA é composta por três módulos integrados via LangChain:

- **Módulo RAG:** recuperação de contexto da base de conhecimento da Cadife Tour via embeddings vetoriais (ChromaDB / PGVector)
- **Módulo de Extração:** prompt estruturado que identifica entidades do briefing (destino, datas, pessoas, orçamento, perfil) na conversa
- **Módulo de Decisão (Motor de Fluxo):** avalia completude do briefing e roteia para curadoria, coleta adicional ou consultor

### 6.2 Identidade do Assistente Virtual

| Atributo | Valor |
|---|---|
| **Nome** | AYA (ou NOA / OTTO — a definir com o PO Diego Gil) |
| **Tom** | Consultivo e próximo — 80% consultor / 20% vendedor |
| **Linguagem** | Natural, clara, educada e não invasiva |
| **Apresentação** | "Olá, sou a AYA da Cadife Tour. Vou te ajudar a organizar sua próxima viagem." |

### 6.3 Limitações Obrigatórias da IA

**A IA NUNCA deve:**

- Gerar preços, valores ou estimativas financeiras
- Confirmar disponibilidade de voos ou hospedagem
- Fechar vendas ou comprometer a empresa comercialmente
- Tomar decisões comerciais críticas de forma autônoma

**A IA SEMPRE deve:**

- Manter respostas abertas, indicando que o consultor irá validar
- Evitar afirmações definitivas sobre disponibilidade ou preço
- Preservar tom humano e natural, mesmo sendo automatizada

### 6.4 Fluxo de Qualificação (Briefing)

A IA conduz perguntas estratégicas para preencher o briefing:

| # | Campo | Pergunta estratégica |
|---|---|---|
| **1** | **Destino** | *Você já tem um destino em mente, ou posso te ajudar a escolher?* |
| **2** | **Datas** | *Tem alguma data em mente para a viagem? Ou ainda está avaliando?* |
| **3** | **Nº Pessoas** | *Quantas pessoas vão viajar com você?* |
| **4** | **Perfil da viagem** | *É uma viagem em família, casal, sozinho ou grupo de amigos?* |
| **5** | **Tipo** | *O que você busca: turismo, lazer, aventura, imigração ou outra coisa?* |
| **6** | **Preferências** | *Prefere clima frio ou quente? Praia ou cidade? Algo mais específico?* |
| **7** | **Orçamento** | *Tem uma faixa de investimento em mente? (Apenas para eu te orientar melhor)* |
| **8** | **Passaporte** | *Já possui passaporte válido?* |
| **9** | **Viagens anteriores** | *Já viajou internacionalmente antes?* |

### 6.5 Estrutura do Payload de Briefing Extraído pela IA

Exemplo de JSON gerado após extração automática:

```json
{
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
```

### 6.6 Base de Conhecimento RAG (Cadife Tour)

Documentos indexados no Vector Database:

| Arquivo | Tipo | Conteúdo |
|---|---|---|
| `identidade_empresa.txt` | **Institucional** | Missão, valores, posicionamento, diferenciais da Cadife Tour |
| `fluxo_atendimento.txt` | **Processo** | Etapas de recepção, qualificação, curadoria e encaminhamento |
| `faq.txt` | **FAQ** | Perguntas frequentes: visto, passaporte, seguro, documentação |
| `regras_negocio.txt` | **Regras** | Horários, pagamentos, prazos, limites de atendimento |
| `destinos.txt` | **Produtos** | Destinos principais, tipos de serviço, experiências ofertadas |
| `objecoes.txt` | **Vendas** | Estratégias para clientes indecisos, comparadores de preço, sumidos |
| `argumentacao.txt` | **Vendas** | Argumentação comercial consultiva e gatilhos de valor |

> *Configuração dos chunks: 300–500 tokens por chunk, sem redundância, contexto objetivo.*

---

## 7. Requisitos do Aplicativo Flutter

### 7.1 Perfil: Agência (Cadife Tour)

#### Dashboard Principal

- Resumo do dia: total de leads, novos hoje, agendamentos pendentes
- KPIs visuais: leads por status, taxa de qualificação, conversão
- Notificação in-app de novos leads em tempo real

#### Lista de Leads (CRM)

- Listagem com card resumo: nome, telefone, destino, status, score (quente/morno/frio) e data
- Filtros por status, score, destino e período
- Busca por nome ou telefone
- Pull-to-refresh e paginação infinita

#### Detalhe do Lead

- Dados completos: contato, briefing estruturado, histórico de interações
- Ações rápidas: Aprovar, Criar Proposta, Enviar Retorno, Agendar
- Timeline de status com timestamps
- Campo de observações para o consultor

#### Agenda

- Calendário com agendamentos do dia e da semana
- Criar, confirmar e cancelar agendamentos
- Visualização de disponibilidade (09h–16h, Seg–Sex)

#### Propostas

- Criar proposta vinculada a um lead
- Atualizar status: `rascunho` → `enviada` → `aprovada` → `recusada`

### 7.2 Perfil: Cliente

#### Tela de Status da Viagem

- Status atual visualizado de forma clara: `Em análise` | `Proposta enviada` | `Confirmado` | `Emitido`
- Barra de progresso visual do processo

#### Histórico de Interações

- Timeline das conversas com o assistente e com o consultor

#### Documentos

- Área para visualizar documentos enviados pela agência: roteiros, vouchers, comprovantes

#### Perfil e Cadastro

- Dados pessoais, preferências de viagem e informações de contato

### 7.3 Design System — Identidade Visual Cadife Tour

| Token | Valor HEX | Uso |
|---|---|---|
| `primaryColor` | `#dd0b0e` | CTA buttons, ícones de ação, badges de status crítico |
| `backgroundColor` | `#393532` | AppBar, dark backgrounds, navegação principal |
| `scaffoldColor` | `#FFFFFF` | Fundo padrão das telas |
| `accentColor` | `#dd0b0e` | Highlights, selected states |
| `textPrimary` | `#1A1A1A` | Textos principais |
| `textSecondary` | `#5D6D7E` | Subtítulos, labels de campos |
| `cardBackground` | `#F8F9FA` | Background de cards |
| `successColor` | `#1E8449` | Status positivos, leads quentes |
| `warningColor` | `#D35400` | Leads mornos, alertas |
| `font` | **Inter ou Roboto** | Tipografia principal do app |

---

## 8. Regras de Negócio

### 8.1 Atendimento e Operação

| Regra | Especificação |
|---|---|
| **Horário de atendimento** | Segunda a Sexta, das 09h às 16h (Brasília) |
| **Capacidade diária** | Até 6 atendimentos de curadoria por dia |
| **Duração da curadoria** | 30 a 60 minutos por sessão (principalmente online) |
| **Intervalo entre atendimentos** | Mínimo de 1 hora entre agendamentos |
| **Atendimento da IA** | 24/7 — o assistente não tem horário de operação restrito |
| **Tempo de resposta da IA** | Máximo de 3 segundos para retornar ao cliente |
| **Notificação ao consultor** | Em até 2 segundos após criação/atualização de lead (FCM) |

### 8.2 Pagamento e Reservas

- Reservas somente após confirmação de pagamento total
- Formas aceitas: cartão de crédito, boleto, entrada + parcelas
- A IA nunca menciona valores ou condições de pagamento
- Propostas com valor estimado só são geradas pelo consultor humano

### 8.3 Qualificação e Score de Leads

| Score | Critérios | Ação Recomendada |
|---|---|---|
| **QUENTE** | Destino + datas + pessoas + orçamento definidos | Priorizar contato imediato — oferecer curadoria no mesmo dia |
| **MORNO** | Destino definido mas datas ou orçamento em aberto | Agendar curadoria e enviar conteúdo de apoio (FAQ, destinos) |
| **FRIO** | Apenas interesse genérico, sem dados concretos | Manter nutrição via WhatsApp, follow-up automatizado |

### 8.4 Fluxo de Status do Lead

Ciclo de vida obrigatório:

- `NOVO` → `EM_ATENDIMENTO`: quando a IA inicia diálogo com o cliente
- `EM_ATENDIMENTO` → `QUALIFICADO`: quando briefing atinge 60%+ de completude
- `QUALIFICADO` → `AGENDADO`: quando cliente aceita agendar curadoria
- `QUALIFICADO` → `PROPOSTA`: quando consultor envia proposta sem agendamento prévio
- `AGENDADO` → `PROPOSTA`: após realização da curadoria
- `PROPOSTA` → `FECHADO`: quando cliente aprova proposta e realiza pagamento
- Qualquer estado → `PERDIDO`: quando cliente desiste ou não responde por 30 dias

---

## 9. Fluxo Operacional Detalhado

### 9.1 Fluxo Principal — WhatsApp → Lead → App

| # | Etapa | Detalhe | Ator |
|---|---|---|---|
| **1** | **Entrada do Cliente** | "Quero viajar para Portugal" — mensagem no WhatsApp | Cliente |
| **2** | **Recepção** | Webhook recebe payload, identifica tipo (texto/audio/imagem) | Backend |
| **3** | **Recepção Humanizada** | "Olá, sou a AYA da Cadife Tour. Vou te ajudar a organizar sua viagem!" | IA (AYA) |
| **4** | **Qualificação** | IA faz perguntas estratégicas uma a uma para coletar briefing | IA (AYA) |
| **5** | **Extração de Dados** | A cada resposta, IA extrai entidades e atualiza briefing no banco | IA + Backend |
| **6** | **Avaliação de Completude** | Motor verifica: briefing >= 60%? → sim: oferta de curadoria \| não: continuar perguntas | Orquestrador |
| **7a** | **Caminho A: Curadoria Aceita** | IA oferece horários → cliente escolhe → agendamento criado no banco | IA + Cliente |
| **7b** | **Caminho B: Sem Agendamento** | "Vou encaminhar suas informações para um consultor. Em breve entraremos em contato." | IA |
| **8** | **Criação do Lead** | Lead salvo com briefing completo, score atribuído, status = qualificado | Backend |
| **9** | **Notificação Push** | Firebase FCM: 'Novo lead qualificado: Portugal, 3 pessoas, orçamento médio' | FCM → App |
| **10** | **Dashboard Agência** | Consultor vê card do lead em tempo real com todos os dados estruturados | App Agência |
| **11** | **Curadoria Humana** | Consultor pesquisa operadoras, monta proposta personalizada | Consultor |
| **12** | **Retorno ao Cliente** | Proposta enviada via WhatsApp ou atualização de status no App Cliente | Consultor |

---

## 10. Cronograma de Execução — 25 Dias

| Período | Fase | Entregas | Responsáveis |
|---|---|---|---|
| **Dias 1–6** | **Fase 1 — Fundação** | Setup do backend FastAPI, configuração do banco de dados, webhook WhatsApp funcional recebendo e logando mensagens, estrutura base do App Flutter (navegação, auth, tema Cadife), configuração do Firebase | *Nikolas (Backend), Luiz (DevOps), Otávio (Flutter)* |
| **Dias 7–13** | **Fase 2 — IA + RAG** | Implementação do LangChain, criação e indexação do Vector DB com documentos da Cadife, lógica de extração de briefing por IA, motor de decisão de fluxo, respostas contextualizadas via RAG, integração WhatsApp → IA → Banco | *Frank (AI), Nikolas (Backend), Diego (UX/API)* |
| **Dias 14–20** | **Fase 3 — App + Firebase** | Desenvolvimento completo das telas do app: dashboard agência, lista de leads, detalhe de lead, telas do cliente (status, histórico, docs), agenda, configuração do FCM, notificações push em tempo real | *Otávio (Flutter Client), Jakeline (Flutter Agency), Luiz (Firebase)* |
| **Dias 21–25** | **Fase 4 — Finalização** | Tratamento de erros e edge cases (áudio, imagem, timeouts), ajustes de UX, documentação da API (Swagger/Postman), containerização (Docker), preparação da demo de 10 min ponta a ponta, organização do GitHub | *Time completo — validação PO Diego* |

### 10.1 Cerimônias Ágeis

| Cerimônia | Frequência | Formato |
|---|---|---|
| **Sprint Planning** | Semanal | Segunda-feira pós-aula ou às 19h — definição de escopo, divisão e atribuição de tarefas (Jira) |
| **Daily Stand-up** | Diária (10–15 min) | O que fiz \| O que farei \| Impedimentos — formato assíncrono ou síncrono via Discord |
| **Sprint Review** | Semanal | Demonstração das entregas, validação pelo PO Diego, time completo presente |
| **Sprint Retrospective** | Semanal | Pontos positivos, negativos e melhorias para o próximo sprint |

---

## 11. Estrutura da Equipe

| Papel | Membro | Responsabilidades |
|---|---|---|
| **Product Owner** | **Diego Gil** | Validação de todas as entregas, definição de prioridades, knowledge base do negócio Cadife Tour, decisão sobre funcionalidades do MVP |
| **Scrum Master** | **Nikolas Tesch** | Aplicação da metodologia ágil, remoção de impedimentos, organização do fluxo do time, manutenção do board Jira e burndown chart |
| **Tech Lead / Backend** | **Nikolas Tesch** | Arquitetura da API FastAPI, segurança (JWT), modelagem de banco, integração WhatsApp Cloud API, code review |
| **AI Engineer** | **Frank Willian** | Implementação do LangChain, configuração do RAG (ChromaDB/PGVector), prompts de extração, lógica de qualificação e roteamento |
| **Flutter Dev — Cliente** | **Otávio Grotto** | Interface do perfil cliente: cadastro, status da viagem, histórico, documentos, consumo da API |
| **Flutter Dev — Agência** | **Jakeline** | Dashboard agência, lista de leads, detalhe de lead, agenda, gestão de propostas, UX do consultor |
| **DevOps & QA** | **Luiz Angelo** | Firebase FCM, notificações push, deploy Docker/LXC, testes de integração, CI/CD GitHub Actions |

### 11.1 Ferramentas do Time

| Ferramenta | Finalidade |
|---|---|
| **Jira** | Gestão do backlog, sprints, tarefas, burndown chart e board Kanban (Backlog → To Do → In Progress → Code Review → Testing → Done) |
| **GitHub** | Versionamento de código, pull requests, code review e CI/CD com GitHub Actions |
| **WhatsApp & Discord** | Comunicação diária (WhatsApp para urgências, Discord para reuniões e dailys) |
| **Postman / Swagger** | Testes de API e documentação dos endpoints do backend |
| **Figma / Stitch** | Design de UX/UI das telas do app Flutter |
| **VS Code / Android Studio** | Desenvolvimento principal (backend Python + frontend Flutter/Dart) |
| **ngrok** | Exposição do webhook local para testes com WhatsApp Cloud API durante desenvolvimento |

---

## 12. Requisitos Não Funcionais

### 12.1 Performance

- Resposta da IA ao cliente via WhatsApp: máximo 3 segundos
- Notificação push ao consultor: máximo 2 segundos após evento
- Carregamento do dashboard (lista de leads): máximo 1,5 segundos
- Atualização em tempo real do app após mensagem no WhatsApp: máximo 2 segundos

### 12.2 Segurança

- Autenticação JWT com expiração configurável (access token 1h, refresh token 7d)
- HTTPS obrigatório em todos os endpoints (webhook + API + FCM)
- Variáveis sensíveis (tokens Meta, OpenAI, DB) exclusivamente via `.env` — nunca no código
- Validação do Verify Token no webhook antes de processar qualquer payload
- Rate limiting nos endpoints de webhook e IA para evitar abuso

### 12.3 Confiabilidade

- O webhook deve responder com HTTP 200 em até 5 segundos (timeout da Meta)
- Tratamento de exceções em todo o fluxo de processamento (try/catch)
- Logs estruturados de todas as interações (entrada, saída, erros)
- Mensagens de mídia não suportadas (áudio, imagem) devem ser tratadas com resposta amigável ao cliente

### 12.4 Usabilidade

- App Flutter deve ser intuitivo para usuários leigos (consultor não-técnico)
- Design clean e premium alinhado ao posicionamento da Cadife Tour (intermediário → premium)
- Feedback visual imediato para todas as ações do usuário (loading, success, error states)

### 12.5 Escalabilidade (preparação futura)

- Backend estruturado para suportar múltiplos números WhatsApp (multi-tenant)
- Docker Compose configurado para escalar horizontalmente o backend
- Vector DB preparado para receber novos documentos sem rebuild completo

---

## 13. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| Complexidade da integração WhatsApp Cloud API | **Média** | **Alto** | Utilizar ngrok para testes locais, documentação oficial Meta como referência primária, reservar 2 dias exclusivos para setup e validação |
| Alucinações da IA gerando preços ou promessas indevidas | **Alta** | **Alto** | Prompt base com restrições explícitas, validação de output antes de enviar ao cliente, logs de todas as respostas para revisão |
| Prazo curto (25 dias) para escopo amplo | **Alta** | **Médio** | Foco em MVP funcional ponta a ponta, features adicionais vão para backlog pós-apresentação, priorização rígida no Sprint Planning |
| Desalinhamento técnico do time em tecnologias novas | **Média** | **Médio** | Pair programming nas integrações críticas, Frank apoia o time na parte de IA, Nikolas garante padrão arquitetural |
| Qualidade ruim do RAG por base de conhecimento incompleta | **Alta** | **Médio** | PO Diego valida e complementa base de conhecimento na Fase 1, chunks testados antes da Fase 2 |
| Timeout do webhook da Meta (> 5 segundos) | **Média** | **Alto** | Processamento assíncrono: webhook responde imediatamente com 200, processamento IA em background via fila |
| Mudanças de escopo durante o desenvolvimento | **Baixa** | **Médio** | Mudanças só entram em sprints futuros, sem interromper sprint em andamento, decisão do PO + Scrum Master |

---

## 14. Critérios de Aceite e Definition of Done

### 14.1 Critérios de Sucesso do MVP

| Critério | Método de Verificação | Responsável |
|---|---|---|
| Mensagem enviada no WhatsApp aparece no App em < 2 segundos | *Teste manual cronometrado* | QA / Luiz |
| IA responde corretamente usando a base de conhecimento RAG da Cadife | *10 perguntas de teste predefinidas pelo PO* | Frank + Diego |
| Briefing extraído automaticamente com >= 80% de precisão | *Comparação manual de 20 conversas de teste* | Frank |
| Lead criado automaticamente ao final da qualificação | *Verificação no banco e no dashboard* | Nikolas |
| Notificação push entregue ao consultor em < 2 segundos | *Teste com dois dispositivos simultâneos* | Luiz |
| App exibe lista de leads com dados estruturados corretamente | *Validação visual pelo PO* | Otávio / Jakeline |
| Fluxo completo ponta a ponta funciona sem erros críticos | *Demo de 10 minutos ao PO* | Time completo |
| Mensagens de tipo não suportado (áudio/imagem) são tratadas | *Envio de mídia no WhatsApp de teste* | QA / Luiz |
| Documentação da API está disponível e acessível (Swagger) | *Acesso à URL `/docs` do backend* | Nikolas |

### 14.2 Definition of Done (DoD)

Uma tarefa é considerada **PRONTA (Done)** quando:

- Código desenvolvido e funcionando no ambiente de desenvolvimento
- Testado (testes manuais ou automatizados conforme a feature)
- Integrado ao branch principal sem conflitos
- Sem erros críticos ou bugs bloqueantes
- Validado por pelo menos 2 membros do time (incluindo o PO para features de negócio)
- Documentado quando se trata de endpoint de API

### 14.3 Kanban Board — Fluxo de Tarefas

| BACKLOG | TO DO | IN PROGRESS | CODE REVIEW | TESTING | DONE |
|---|---|---|---|---|---|
| Features futuras e ideias | Planejadas para o sprint atual | Em desenvolvimento ativo | Aguardando revisão de código | Em validação e testes | Validado pelo PO e entregue |

---

## 15. Configuração — Variáveis de Ambiente

| Variável | Obrigatória | Descrição |
|---|---|---|
| `WHATSAPP_TOKEN` | **Sim** | Token de acesso da Meta (WhatsApp Cloud API) |
| `PHONE_NUMBER_ID` | **Sim** | ID do número de telefone registrado na Meta |
| `VERIFY_TOKEN` | **Sim** | Token secreto para verificação do webhook pela Meta |
| `GEMINI_API_KEY` | **Sim** | Chave da API Google Gemini para o modelo de linguagem (migrado de OpenAI) |
| `DATABASE_URL` | **Sim** | String de conexão com PostgreSQL ou MongoDB |
| `JWT_SECRET_KEY` | **Sim** | Chave secreta para assinatura dos tokens JWT |
| `FIREBASE_CREDENTIALS` | **Sim** | Caminho para o arquivo JSON de credenciais do Firebase Admin |
| `CHROMA_PERSIST_DIR` | Não | Diretório de persistência do ChromaDB (padrão: `./chroma_db`) |
| `LANGCHAIN_API_KEY` | Não | Chave LangSmith para observabilidade das chains (opcional) |
| `DEBUG` | Não | Modo debug: `true` \| `false` (padrão: `false` em produção) |

---

## 16. Stakeholders e Alinhamento

| Stakeholder | Papel | Envolvimento |
|---|---|---|
| **Diego Gil** | PO / CEO | Valida todas as entregas, define prioridades de negócio, conhecimento das regras operacionais da Cadife Tour, aprovação final do MVP |
| **Nikolas Tesch** | Scrum Master / Backend | Garante metodologia ágil, remove impedimentos, organiza cerimônias e artefatos |
| **Equipe de Desenvolvimento (6 membros)** | Dev Team | Execução técnica — sprints, code review, testes e integração |
| **Instrutores Alpha** | Avaliadores | Revisões de progresso, avaliação do projeto final e pitch de demo |
| **Clientes da Cadife Tour (leads)** | Usuários finais | Validação de fluxo UX via teste demo, feedback sobre atendimento da IA |
| **Consultores de Viagem (Cadife)** | Usuários internos | Uso do dashboard agência, feedback de usabilidade do CRM |
| **Terceiros (Marketing)** | Suporte | Fornecimento de logomarca, manual de identidade visual e conteúdos para base RAG |

---

## 17. Glossário

| Termo | Definição |
|---|---|
| **RAG** | Retrieval-Augmented Generation — técnica de IA que recupera documentos relevantes de uma base de conhecimento antes de gerar uma resposta, reduzindo alucinações |
| **Webhook** | Endpoint HTTP que recebe notificações automáticas de sistemas externos (neste projeto: da Meta/WhatsApp) quando há uma mensagem nova |
| **Lead** | Potencial cliente que iniciou contato com a Cadife Tour via WhatsApp e teve seus dados registrados no sistema |
| **Briefing** | Conjunto estruturado de informações do cliente: destino, datas, pessoas, orçamento, perfil — coletado pela IA durante a conversa |
| **Curadoria** | Processo de atendimento aprofundado e personalizado realizado pelo consultor humano da Cadife Tour |
| **FCM** | Firebase Cloud Messaging — serviço do Google para envio de notificações push para dispositivos móveis |
| **JWT** | JSON Web Token — padrão de autenticação stateless usado para proteger os endpoints da API |
| **Score de Lead** | Classificação da temperatura do lead (quente/morno/frio) baseada na completude do briefing e nível de interesse demonstrado |
| **LangChain** | Framework Python para orquestração de LLMs, com suporte a cadeia de prompts, RAG e memória de conversação |
| **Vector DB** | Banco de dados vetorial que armazena embeddings de documentos para busca semântica (ChromaDB ou PGVector) |
| **DoD** | Definition of Done — critérios que uma tarefa deve atender para ser considerada concluída pelo time |
| **MVP** | Minimum Viable Product — versão mínima funcional do produto que entrega valor real ao usuário |

---

*CADIFE SMART TRAVEL — Project Specification v1.0*
*Documento gerado para o Desafio Tech OmniConnect — Uso Interno*
*Cadife Tour — Plataforma de Atendimento Inteligente*
