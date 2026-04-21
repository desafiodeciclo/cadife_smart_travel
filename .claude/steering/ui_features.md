# UI Features — Detailed Requirements

Detalhamento das telas e funcionalidades do App Flutter para ambos os perfis.

## 1. Perfil: Agência (Cadife Tour)

### 1.1 Dashboard Principal
- **Resumo do dia:** total de leads, novos hoje, agendamentos pendentes.
- **KPIs visuais:** leads por status, taxa de qualificação, conversão.
- **Notificação in-app:** alertas de novos leads qualificados em tempo real.

### 1.2 Lista de Leads (CRM)
- **Cards Resumo:** nome, telefone, destino, status, score (quente/morno/frio) e data.
- **Filtros e Busca:** filtros por status, score, destino e período; busca por nome ou telefone.
- **UX:** Pull-to-refresh e paginação infinita.

### 1.3 Detalhe do Lead
- **Dados:** briefing completo, histórico de interações (timeline).
- **Ações Rápidas:** Aprovar, Criar Proposta, Enviar Retorno, Agendar.
- **Timeline de Status:** registro de mudanças com timestamps.
- **Observações:** campo de texto livre para o consultor.

### 1.4 Agenda
- **Calendário:** visualização por dia/semana de agendamentos.
- **Gestão:** criar, confirmar e cancelar agendamentos.
- **Disponibilidade:** consulta de slots livres (09h–16h, Seg–Sex).

### 1.5 Propostas
- **Vinculação:** criar proposta associada a um lead específico.
- **Status:** ciclo `rascunho` → `enviada` → `aprovada` → `recusada`.

## 2. Perfil: Cliente

### 2.1 Status da Viagem
- **Barra de Progresso:** `Em análise` → `Proposta enviada` → `Confirmado` → `Emitido`.
- **Feedback Visual:** indicação clara do estágio atual.

### 2.2 Histórico e Documentos
- **Timeline:** registro de conversas e decisões.
- **Docs:** visualização de PDFs (roteiros, vouchers, comprovantes).

### 2.3 Perfil e Cadastro
- Dados pessoais e preferências de viagem extraídas pela IA ou atualizadas manualmente.

## 3. Design System (Tokens)
- **Primary:** `#dd0b0e` | **Background:** `#393532` | **Scaffold:** `#FFFFFF`.
- **Status Colors:** Success (`#1E8449`), Warning (`#D35400`), Text (`#1A1A1A`).
- **Font:** Inter ou Roboto.
