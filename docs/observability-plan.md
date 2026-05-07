# Plano de Observabilidade — Cadife Smart Travel

Baseado no spec.md §13 (Observabilidade).

## 1. Métricas de Negócio (Business Metrics)
- **Leads**: total criado, por dia, por origem (WhatsApp, web, etc.)
- **Propostas**: geradas, convertidas a partir de leads
- **Agendamentos**: realizados, cancelados
- **Taxa de conversão**: Lead → Proposta → Agendamento
- **Uso de IA**: número de interações com assistente, tokens consumidos (OpenAI/Gemini)

## 2. Métricas Técnicas (Technical Metrics)
- **Latência de endpoints**: `/webhook`, `/leads`, `/propostas`, `/ia/pergunta`
- **Taxa de erros HTTP**: 4xx, 5xx por endpoint
- **Tempo de resposta do banco de dados** (PostgreSQL)
- **Uso de recursos**: memória, CPU do servidor
- **Tempo de resposta de APIs externas**: Meta (WhatsApp), OpenAI/Gemini
- **Rate limiting**: número de requisições bloqueadas

## 3. Logs Estruturados (Structlog)
- **Formato**: JSON para fácil processamento (ELK/Loki)
- **Campos obrigatórios**: timestamp, level, service, trace_id, user_id (se disponível)
- **Eventos de interesse**:
  - Requisições HTTP (método, path, status, latency)
  - Erros da aplicação (stacktrace, contexto)
  - Segurança (tentativas de acesso não autorizado, JWT inválido)
  - Assistente IA (prompts, respostas, erros de API)

## 4. Tracing Distribuído (Langfuse/OpenTelemetry)
- **Fluxos críticos a rastrear**:
  - Mensagem WhatsApp → Webhook → LLM → Resposta
  - Criação de Lead → Proposta → Agendamento
- **Instrumentação**: usar OpenTelemetry para exportar traces para Langfuse ou Jaeger.

## 5. Próximos Passos (Implementação)
1. Centralizar configuração de logs (structlog) no `app/infrastructure/logging/`.
2. Instrumentar FastAPI com Prometheus (métricas) usando `prometheus-fastapi-instrumentator`.
3. Configurar exportador de traces (OpenTelemetry + Langfuse).
4. Criar dashboard no Grafana (ou usar Langfuse UI) para visualizar métricas e traces.
5. Configurar alertas (Alertmanager) para erros críticos e latência alta.

---
*Este documento será atualizado conforme a implementação avança.*
