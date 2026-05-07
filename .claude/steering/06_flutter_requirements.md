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
