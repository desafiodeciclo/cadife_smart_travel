# 🚀 Cadife Smart Travel UI — Branch Tasks (NOVA v1.0)

> Padrão de branches: `(F) feat/`, `(R) refactor/`, `(C) chore/`, `(B) bugfix/`
> **⚠️ Legenda de revisão:** `✅ Validado` | `🔧 Atualizado` | `🆕 Nova Task` | `🚨 Gap Crítico`
> Total: **15 tasks** | Estimado: **115 pontos**

---

## 📋 RESUMO DA IMPLEMENTAÇÃO UI

| Categoria | Qtde | Impacto |
|---|---|---|
| **Tasks de Foundation (Design System)** | **2** | 🚨 CRÍTICO |
| Tasks de Perfil Cliente (End-User) | 8 | 🔵 High |
| Tasks de Perfil Gestor (Admin/CRM) | 5 | 🔴 High |

---

# 🎨 Sprint 5 — Foundation & Experiência do Cliente (Semanas 1-2)

## História 5.1 — Design System & Flutter Foundation (15 pontos)

**Contexto:** Para garantir consistência visual Premium conforme o CDS v3.0, é necessário instanciar os tokens de design (cores, tipografia, sombras) e componentes reutilizáveis que servirão para ambos os apps.
**Objetivo:** Configurar o tema global e componentes base (Botões, Inputs, Cards).

### 🆕 (C) chore/flutter-design-system-setup
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Frontend Lead | **Status:** 🆕 Nova Task
- [ ] **Configurar Theme Data:** Implementar `ThemeData` com cores Red Cadife (#DD0B0E), Deep Graphite (#393532) e fontes `Bai Jamjuree` (Títulos) e `Inter` (Corpo). (3h)
- [ ] **Componentes Atômicos:** Criar `CadifeButton` com efeito de escala (0.95x), `CadifeInput` com validação animada e `CadifeCard` com border-radius de 20px e elevação suave. (3h)
- [ ] **Shimmer & Transitions:** Implementar `ShimmerEffect` para estados de loading e configurar transições de tela via `PageTransitionsBuilder` (Slide da direita). (2h)

### 🆕 (F) feat/navigation-shell-logic
**Prioridade:** 🔴 Critical | **Pontos:** 7 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Bottom Navigation Custom:** Criar navegação inferior com Lucide Icons em estilo outline, transição suave entre abas e suporte a estados ativos/inativos conforme CDS. (4h)
- [ ] **App Shell Layout:** Estruturar o Scaffold base que gerencia o estado da navegação e AppBar persistente (com logo Cadife). (3h)

---

## História 5.2 — Home e Planejamento de Viagens (25 pontos)

**Contexto:** A Home é o portal de entrada do viajante. Ela deve exibir o status da viagem atual ou próxima, além de oferecer acesso rápido aos serviços da AYA.
**Objetivo:** Implementar a Dashboard do cliente e fluxo de visualização de roteiro.

### 🆕 (F) feat/ui-customer-home
**Prioridade:** 🔵 High | **Pontos:** 8 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Hero Section & Welcome:** Header dinâmico com saudação e resumo de status do usuário. (2h)
- [ ] **Current Trip Card:** Card principal em destaque (16:9) com foto do destino, cronômetro para viagem e progresso do checklist. (4h)
- [ ] **Quick Actions Grid:** Atalhos rápidos para "Minha Mala", "Documentos" e "Falar com AYA". (2h)

### 🆕 (F) feat/ui-customer-trips-list
**Prioridade:** 🔵 High | **Pontos:** 10 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Listagem de Viagens:** Lista vertical de cards com separação visual entre "Em Andamento", "Próximas" e "Histórico". (4h)
- [ ] **Detalhe da Viagem:** Tela rica com Itinerário (Timeline), Informações de Voo/Hotel e link para Documentos. (4h)
- [ ] **Visualização em Calendário (Agenda):** Switch para visão Mensal (dots) e Diária (timeline detalhada por hora) da viagem selecionada. (2h)

### 🆕 (F) feat/ui-customer-offers-explorer
**Prioridade:** 🟢 Medium | **Pontos:** 7 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Feed de Ofertas:** Grid de pacotes com scroll infinito e Shimmer loading. (3h)
- [ ] **Filtros de Destino:** Modal de filtro por categoria (Sol, Neve, Urbano, Aventura) e range de preço. (2h)
- [ ] **Tela de Oferta Específica:** Galeria de imagens, descrição detalhada e CTA flutuante "Interesse nesta oferta" (Dispara fluxo AYA). (2h)

---

## História 5.3 — Utilitários e Perfil do Viajante (20 pontos)

**Contexto:** O viajante precisa gerenciar seus documentos e pertences de forma offline-first e intuitiva.
**Objetivo:** Implementar as telas de Docs, Suitcase (Mala) e Perfil.

### 🆕 (F) feat/ui-customer-docs-and-suitcase
**Prioridade:** 🔵 High | **Pontos:** 8 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Docs Vault:** Listagem de pastas por viagem contendo arquivos PDF/Imagens com preview integrado. (4h)
- [ ] **Minha Mala (Checklist):** Tela de checklist interativo para conferência de itens, com sugestões inteligentes baseadas no destino (ex: levar casaco para Gramado). (4h)

### 🆕 (F) feat/ui-customer-profile-journal
**Prioridade:** 🟢 Medium | **Pontos:** 12 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Dashboard de Perfil:** Estatísticas do viajante (Km percorridos, carimbos virtuais, nível de fidelidade). (3h)
- [ ] **Jornal de Viagem:** Timeline de memórias onde o usuário visualiza fotos e notas salvas de viagens passadas. (5h)
- [ ] **Configurações:** Edição de dados pessoais, preferências de notificação (Push) e segurança. (4h)

---

# 📈 Sprint 6 — Gestão, Leads e Agenda do Consultor (Semanas 2-3)

## História 6.1 — CRM Dashboard & Pipeline de Leads (25 pontos)

**Contexto:** O consultor precisa de uma visão executiva rápida sobre o volume de atendimento e acesso imediato aos leads qualificados pela IA.
**Objetivo:** Implementar o Dashboard de gestão e detalhamento de leads.

### 🆕 (F) feat/ui-manager-dashboard
**Prioridade:** 🔴 Critical | **Pontos:** 8 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **KPI Summary:** Cards de métricas (Total Leads, Leads Quentes, Conversão, Receita Estimada). (3h)
- [ ] **Hot Leads Radar:** Lista resumida de leads que acabaram de ser qualificados pela AYA e aguardam contato humano. (5h)

### 🆕 (F) feat/ui-manager-leads-crm
**Prioridade:** 🔴 Critical | **Pontos:** 10 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Filtro Avançado de Leads:** Busca por status (Novo, Em Atendimento, Qualificado, Perdido), score e destino. (3h)
- [ ] **Lead Details View:** Tela central de atendimento com:
    - **Header:** Score do Lead e Status.
    - **Aba Briefing:** Dados extraídos pela AYA (Passageiros, Orçamento, Destino).
    - **Aba Chat:** Histórico completo de interação cliente-AYA-Consultor. (5h)
- [ ] **Criação de Proposta:** Modal para preenchimento de valor e descrição da proposta final. (2h)

---

## História 6.2 — Agenda e Administração (30 pontos)

**Contexto:** O consultor gerencia sua agenda de reuniões de fechamento e o fluxo de documentos da agência.
**Objetivo:** Implementar o calendário de reuniões e perfil administrativo.

### 🆕 (F) feat/ui-manager-agenda
**Prioridade:** 🔵 High | **Pontos:** 10 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Visão Mensal:** Calendário com marcadores de densidade de reuniões. (4h)
- [ ] **Visão Diária (Timeline):** Lista de slots das 09h às 16h com cards de reuniões agendadas, permitindo clique para abrir o perfil do lead. (4h)
- [ ] **Gestão de Slots:** Bloqueio manual de horários para pausas ou reuniões internas. (2h)

### 🆕 (F) feat/ui-manager-profile-settings
**Prioridade:** 🟢 Medium | **Pontos:** 5 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Perfil do Consultor:** Foto, Bio e histórico de metas/vendas. (2h)
- [ ] **Configurações de Agência:** Horários de atendimento, templates de mensagem e notificações de novos leads qualificados. (3h)

### 🆕 (F) feat/ui-shared-auth-screens
**Prioridade:** 🔴 Critical | **Pontos:** 15 | **Assignee:** Frontend | **Status:** 🆕 Nova Task
- [ ] **Login & Welcome:** Tela de login unificada com seleção de perfil (Viajante / Consultor) ou detecção automática via backend. (5h)
- [ ] **Esqueci Senha / Recuperação:** Fluxo de e-mail de recuperação seguindo layout CDS. (3h)
- [ ] **Onboarding (Optional):** Slides explicativos sobre o uso da AYA para novos usuários. (7h)

---

## 📊 RESUMO FINAL — Cobertura UI

| Módulo | Cobertura | Telas |
|---|---|---|
| Cliente - Core | 100% | Home, Viagens, Detalhe, Agenda |
| Cliente - Extras | 100% | Ofertas, Filtros, Docs, Mala, Perfil |
| Gestor - CRM | 100% | Dashboard, Leads, Detalhe, Chat, Proposta |
| Gestor - Agenda | 100% | Mensal, Diária, Slots |
| Geral | 100% | Auth, Onboarding, Configurações |
