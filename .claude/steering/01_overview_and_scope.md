# CADIFE SMART TRAVEL — Project Specification v1.0
## Overview and Scope

> **CONFIDENCIAL — Uso Interno do Time de Desenvolvimento**

**Plataforma de Atendimento Inteligente via WhatsApp + App Flutter**
**ESPECIFICAÇÃO TÉCNICA DO PROJETO**
*Project Specification Document | MVP v1.0*

| Campo | Valor |
|---|---|
| **Versão** | 1.0.0 — MVP |
| **Projeto** | Cadife Smart Travel |
| **Cliente** | Cadife Tour |
| **Prazo MVP** | 25 dias |
| **Data** | Junho 2025 |
| **Status** | **Em Desenvolvimento** |

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
| Webhook WhatsApp Cloud API | **CRÍTICO** | Fase 1 — Dias 1–6 |
| Assistente IA com RAG (LangChain) | **CRÍTICO** | Fase 2 — Dias 7–13 |
| Coleta estruturada de briefing | **CRÍTICO** | Fase 2 — Dias 7–13 |
| Criação automática de leads | **CRÍTICO** | Fase 2 — Dias 7–13 |
| App Flutter — Perfil Agência (CRM) | **CRÍTICO** | Fase 3 — Dias 14–20 |
| App Flutter — Perfil Cliente | **ALTA** | Fase 3 — Dias 14–20 |
| Notificações Push (Firebase FCM) | **ALTA** | Fase 3 — Dias 14–20 |
| Autenticação (Auth) no App | **ALTA** | Fase 1 — Dias 1–6 |
| Base de conhecimento RAG da Cadife | **ALTA** | Fase 2 — Dias 7–13 |
| Score de qualificação de leads | **MÉDIA** | Fase 2 — Dias 7–13 |
| Agendamento básico de curadoria | **MÉDIA** | Fase 3 — Dias 14–20 |
| Tratamento de mídias (áudio/imagem) | **MÉDIA** | Fase 4 — Dias 21–25 |
| Documentação API (Swagger) | **MÉDIA** | Fase 4 — Dias 21–25 |
| Docker / containerização | **BAIXA** | Fase 4 — Dias 21–25 |

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
