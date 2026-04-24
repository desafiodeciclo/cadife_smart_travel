# ADR 0009 — Isar + Hive Hybrid Cache

## Status
Aceito

## Contexto
O app Flutter precisa de cache offline-first para:
1. Dados simples de configuração e fila de sync (KV)
2. Objetos complexos estruturados (leads, briefings, agenda, propostas)

Hive já estava no projeto como KV store, mas não oferece queries tipadas nem indexação eficiente para objetos aninhados.

## Decisão
Adotar **Isar** para dados estruturados complexos e manter **Hive** para configurações KV e fila de sync offline.

## Consequências
- **Positivas:** Queries tipadas, indexação, performance superior para CRUD de leads/agenda.
- **Negativas:** Duas dependências de DB local; build_runner adicional para gerar `.g.dart` do Isar.
- **Mitigação:** Isar schemas são simples (espelham os domain models); build_runner executado em CI.
