# Contexto para Auditoria de Arquitetura — Cadife Smart Travel

## Objetivo
Auditar estrutura atual do projeto Flutter em /lib e recomendarações de padronização.

## Scope
- Estrutura de pastas (Clean Architecture vs Feature-first)
- Riverpod providers (nomenclatura, escopo, consistência)
- GoRouter (rotas, guards, redirecionamentos)
- API client (Dio, interceptors, tratamento de erro)
- Modelos/DTOs (Freezed, fromJson/toJson)
- Nomenclatura e convenções Dart
- State management (AsyncNotifier, StateNotifier, etc.)

## Tecnologias em Uso
- Flutter 3.x (SDK Dart ^3.11.4)
- Riverpod 2.6.1 (flutter_riverpod)
- GoRouter 17.2.2
- Dio 5.7.0
- Freezed 2.5.2 (dev) / freezed_annotation 2.4.4
- Isar 3.1.0+1 (local DB)
- Hive 2.2.3 (offline cache)
- fpdart 1.1.0 (Either / functional)
- shadcn_ui 0.54.0 (design system)

## Pontos de Contato
- Frontend Lead: [nome]
- Scrum Master: Nikolas

## Última Revisão
- **v1.0** — 2026-05-05: Auditoria inicial gerada por Antigravity
- **v1.1** — 2026-05-05: Cross-referenciada com código real em `/lib`; versões atualizadas; novas inconsistências identificadas (27 total vs 24 iniciais)
