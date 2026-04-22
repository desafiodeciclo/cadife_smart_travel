# API Endpoints — FastAPI Contracts

Este documento centraliza todos os contratos de integração REST do backend FastAPI.

## 1. Webhook WhatsApp

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/webhook/whatsapp` | Verificação do webhook pela Meta (challenge) | WhatsApp |
| **POST** | `/webhook/whatsapp` | Recebimento de mensagens em tempo real | WhatsApp |

## 2. IA e Processamento

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/ia/processar` | Processa mensagem e retorna resposta da IA | AI Core |
| **POST** | `/ia/extrair-briefing` | Extrai dados estruturados de uma conversa | AI Core |
| **GET** | `/ia/status` | Health check do serviço de IA | AI Core |

## 3. Leads (CRM)

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/leads` | Lista todos os leads com filtros e paginação | Leads |
| **POST** | `/leads` | Cria novo lead (via webhook ou manual) | Leads |
| **GET** | `/leads/{id}` | Retorna detalhes de um lead específico | Leads |
| **PUT** | `/leads/{id}` | Atualiza dados ou status do lead | Leads |
| **DELETE** | `/leads/{id}` | Arquiva (soft delete) um lead | Leads |
| **GET** | `/leads/{id}/interacoes` | Histórico completo de conversas do lead | Leads |
| **GET** | `/leads/{id}/briefing` | Briefing estruturado do lead | Leads |
| **PUT** | `/leads/{id}/briefing` | Atualiza briefing manualmente | Leads |

## 4. Agenda e Agendamentos

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **GET** | `/agenda/disponibilidade` | Retorna horários disponíveis para curadoria | Agenda |
| **POST** | `/agenda` | Cria novo agendamento | Agenda |
| **GET** | `/agenda/{id}` | Detalhe de um agendamento | Agenda |
| **PUT** | `/agenda/{id}` | Atualiza status do agendamento | Agenda |

## 5. Propostas

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/propostas` | Cria nova proposta para um lead | Propostas |
| **GET** | `/propostas/{id}` | Detalhe da proposta | Propostas |
| **PUT** | `/propostas/{id}` | Atualiza proposta ou status | Propostas |

## 6. Autenticação e Usuários

| Método | Endpoint | Descrição | Módulo |
|---|---|---|---|
| **POST** | `/auth/login` | Login com e-mail e senha, retorna JWT | Auth |
| **POST** | `/auth/refresh` | Renova token JWT | Auth |
| **GET** | `/users/me` | Retorna perfil do usuário autenticado | Auth |
| **POST** | `/users/fcm-token` | Registra token FCM do dispositivo | Auth |
