# ADR 001: Escolhas de Stack Tecnológico — Cadife Smart Travel MVP

## Status
Aceito

## Contexto

O time precisava definir o stack para construir em 25 dias um sistema ponta a ponta: webhook WhatsApp, IA conversacional com RAG, banco de dados, app mobile e notificações push. As restrições eram: prazo curto, time pequeno (6 pessoas), ecossistema Python para IA, e um cliente não-técnico como PO.

## Decisão

### Backend: FastAPI (Python)
**Razão:** Ecossistema Python é obrigatório para LangChain e embeddings. FastAPI oferece performance assíncrona nativa (ASGI/uvicorn), tipagem forte com Pydantic e geração automática de Swagger — eliminando necessidade de documentar manualmente a API.

**Alternativas rejeitadas:** Django (overhead excessivo, ORM síncrono por padrão), Flask (sem async nativo, sem Pydantic integrado), Node.js (separaria ecossistema da IA).

### Banco de Dados: PostgreSQL + PGVector
**Razão:** PostgreSQL suporta PGVector nativamente, unificando banco relacional e vector store em produção sem infra extra. ChromaDB é usado em desenvolvimento local por simplicidade de setup.

**Alternativas rejeitadas:** MongoDB (sem suporte nativo a PGVector, ACID mais fraco para dados financeiros de propostas), banco separado para vetores (mais infra, mais complexidade no MVP).

### IA / RAG: LangChain + OpenAI GPT-4o-mini
**Razão:** LangChain oferece abstrações prontas para RAG, memória de conversação, output parsers Pydantic e chains compostas. GPT-4o-mini tem custo 15x menor que GPT-4o com qualidade suficiente para triagem de leads.

**Alternativas rejeitadas:** LlamaIndex (menos maduro para casos de uso de conversação), modelos open source locais (inviável no prazo de 25 dias), implementação manual de RAG (risco técnico alto).

### Frontend: Flutter (Dart)
**Razão:** Single codebase para Android + iOS + Web. Performance nativa. Permite dois perfis (Agência e Cliente) no mesmo app com code sharing. Jakeline e Otávio já têm experiência com Flutter.

**Alternativas rejeitadas:** React Native (performance inferior, bridge JS/Native), apps separados por plataforma (inviável no prazo), web-only (cliente quer app mobile para consultores em campo).

### Notificações: Firebase FCM
**Razão:** Entrega confiável para Android e iOS, SDK Flutter maduro (`firebase_messaging`), gratuito no tier de uso esperado, integração simples com Firebase Auth já escolhido.

**Alternativas rejeitadas:** OneSignal (dependência extra de terceiro), APNs/FCM direto (mais configuração, sem SDK Flutter unificado), WebSockets (não funciona em background mobile).

### Autenticação: JWT + Firebase Auth
**Razão:** JWT para a API REST (stateless, sem sessão no servidor). Firebase Auth para o app mobile — suporta e-mail/senha e Google Sign-In sem implementar do zero. Integração via `firebase_uid` na tabela `users`.

## Consequências

**Positivas:**
- Stack coerente com expertise do time (Python/Flutter)
- Infraestrutura simplificada: PostgreSQL único para dados + vetores em produção
- Tempo de setup reduzido com abstrações LangChain e Firebase
- Swagger gerado automaticamente pelo FastAPI

**Negativas / Trade-offs:**
- LangChain tem abstrações com curva de aprendizado; Frank é o ponto focal
- GPT-4o-mini pode requerer ajuste de prompts para manter qualidade da extração
- Firebase Auth cria acoplamento com Google Cloud; migração futura seria custosa
- ChromaDB (dev) ≠ PGVector (prod): diferença de comportamento requer testes em ambos
