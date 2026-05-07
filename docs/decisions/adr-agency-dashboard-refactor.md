# ADR-006: Refatoração do Dashboard da Agência — CustomScrollView + Modularização

**Data:** 30 de Abril de 2026  
**Status:** Implementado  
**Decisor:** Nikolas Tesch  
**Contexto:** Implementação do novo dashboard da agência conforme mockup especificado, com foco em performance e modularização.

---

## Problema

O dashboard anterior era funcional mas monolítico, limitado a um layout simples com `SingleChildScrollView` e sem seções dedicadas a performance e funil de leads — informações críticas para o consultor gerenciar seu pipeline de vendas.

## Decisão

Refatorar o dashboard utilizando:
- **`CustomScrollView` com `SliverToBoxAdapter`** em lugar de `SingleChildScrollView` para melhor performance e integração com headers fixos
- **Modularização de widgets** em pasta dedicada (`lib/features/agency/dashboard/widgets/`)
- **Expansão de `DashboardStats`** para incluir métricas de performance e funil
- **`CadifeAppBar`** como header pinned (conforme design system)

## Consequências

✅ **Positivas:**
- Código mais modular e reutilizável
- Padrão consistente com outras telas (cliente)
- Métricas de performance/conversão visíveis ao consultor
- Funil de leads em formato visual intuitivo
- Performance melhorada com Slivers

❌ **Trade-offs:**
- Mais arquivos para manutenção (5 widgets modulares)
- Maior tamanho inicial do código (necessário para funcionalidade)

## Arquitetura

```
dashboard/
├── dashboard.dart              # Exports
├── dashboard_provider.dart     # DashboardStats + DashboardStatsNotifier
├── dashboard_screen.dart       # Screen principal (CustomScrollView)
└── widgets/
    ├── notification_card.dart      # Hot-lead notification
    ├── summary_section.dart        # Cards: Total, Novos, Agendamentos
    ├── performance_section.dart    # Circular progress + taxa de conversão
    └── funnel_section.dart         # Linear bars para cada status
```

## Métricas Calculadas

### Taxa de Qualificação (%)
```
(Qualificados + Proposta + Fechado) / Total * 100
```

### Taxa de Conversão (%)
```
Fechado / Total * 100
```

### Funil de Leads
Contagem por status: novo, qualificado, proposta, fechado

---

## Validação

- ✅ Flutter analyze sem erros (dashboard)
- ✅ Enums corretos (`LeadStatus`, `LeadScore`)
- ✅ Linting compliance (imports ordenados, const constructors)
- ✅ Riverpod pattern (AsyncNotifierProvider + StateNotifier)
- ✅ Design tokens do Cadife aplicados (cores, tipografia)

## Próximas Iterações (Pós-MVP)

1. **Notificação em tempo real:** integrar com FCM para hot-leads
2. **Gráficos avançados:** Recharts ou similar para visualizações mais ricas
3. **Filtros:** aba para segmentar dashboard por período, agente, destino
4. **Exportação:** gerar relatório PDF com métricas do dia

---

**Relacionado a:** MVP-F3-DASH-001, specs/active/agency-dashboard-refactor-001.json
