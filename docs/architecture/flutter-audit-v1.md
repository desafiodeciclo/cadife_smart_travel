# Flutter Architecture Audit — Cadife Smart Travel
## v1.0 | Gerado por Antigravity | Data: 2026-05-05

### Executivo

**Total de inconsistências encontradas:** 24
- Críticas: 5
- Altas: 8
- Médias: 7
- Baixas: 4

**Estimativa total de refactor:** 65 pontos de trabalho

---

## 1. Análise de Estrutura de Pastas

### Atual
O projeto utiliza uma estrutura predominantemente **Feature-first** com divisões internas em `domain`, `data` e `presentation`. No entanto, a camada de aplicação está muitas vezes fundida com `presentation` ou `providers`, e a camada de infraestrutura é nomeada como `data`.

### Recomendado
- Padronizar para Feature-first com Clean Architecture 4 layers: `domain`, `application`, `infrastructure`, `presentation`.
- Mover `data` para `infrastructure`.
- Criar `application` para lógica de orquestração e Riverpod Notifiers.

### Inconsistências
- [ ] **Múltiplos padrões de camadas** — Algumas features usam `data`, outras apenas `presentation`. Impacto: Médio.
- [ ] **Core vs Shared** — Existe uma pasta `core` e uma `shared`, com responsabilidades sobrepostas (ex: `network` em `core`, `widgets` em `shared`). Impacto: Alto.

---

## 2. Análise de Riverpod

### Padrões Utilizados
Uso misto de Riverpod com Bloc. Muitos providers simples agindo como Service Locator para instâncias do GetIt.

### Inconsistências & Recomendações
- [ ] **Uso de Bloc envolto em Provider** — `authBlocProvider` utiliza `AuthBloc`. Recomendado migrar para `AsyncNotifier`. Impacto: Crítico.
- [ ] **GetIt + Riverpod** — Providers como `dioClientProvider` buscam instâncias no GetIt. Recomendado usar Riverpod para toda a árvore de dependências. Impacto: Alto.
- [ ] **Naming de Interface em Provider** — `iAgendaRepositoryProvider` usa prefixo `i`. Recomendado: `agendaRepositoryProvider`. Impacto: Baixo.

### Exemplos
**Antes (Bloc wrapper):**
```dart
final authBlocProvider = Provider<AuthBloc>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthBloc(repository);
});
```
**Depois (AsyncNotifier):**
```dart
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
```

---

## 3. Análise de GoRouter

### Padrões Utilizados
Centralizado em `app_router.dart` com lógica de redirecionamento baseada em estado do Bloc.

### Inconsistências & Recomendações
- [ ] **Dependência de Bloc no Router** — O roteador observa um stream do Bloc. Recomendado observar um `Notifier` do Riverpod. Impacto: Alto.
- [ ] **Uso extensivo de `extra`** — Objetos complexos como `Lead` e `Documento` passados via `extra`, quebrando deep links. Recomendado usar IDs em caminhos. Impacto: Médio.

---

## 4. Análise de API & Networking

### Padrões Utilizados
Dio com interceptores básicos e repositórios retornando `Either<Failure, T>`.

### Inconsistências & Recomendações
- [ ] **Tratamento de Erro Genérico** — `catch (e)` retorna sempre `ServerFailure`. Impacto: Crítico.
- [ ] **Falta de Retry Logic** — Nenhuma política de retry para falhas transientes. Impacto: Médio.

---

## 5. Análise de Models & Serialization

### Padrões Utilizados
Uso manual de `fromJson`/`toJson` com `Equatable`.

### Inconsistências & Recomendações
- [ ] **Falta de Freezed** — Models como `Lead` são manuais e extensas. Impacto: Alto.
- [ ] **Entidades com Lógica de Serialization** — A camada de `domain` conhece o formato JSON. Recomendado criar DTOs em `infrastructure` e Mappers. Impacto: Alto.

---

## 6. Análise de Nomenclatura

### Inconsistências
- [ ] **Prefixo 'i' em Providers** — `iAgendaRepositoryProvider` deve ser `agendaRepositoryProvider`.
- [ ] **Mistura de idiomas** — Algumas pastas em PT (`perfil`, `documentos`) e outras em EN (`leads`, `settings`). Recomendado: 100% EN. Impacto: Baixo.

---

## 7. Lista Priorizada de Refactors

| # | Problema | Impacto | Esforço | Blocos? |
|---|----------|---------|---------|---------|
| 1 | Migrar AuthBloc para Riverpod AuthNotifier | Crítico | 12h | Sim |
| 2 | Implementar Freezed em todas as Models | Alto | 16h | Não |
| 3 | Padronizar Error Handling em Repositórios | Crítico | 8h | Sim |
| 4 | Separar DTOs de Entidades (Mappers) | Alto | 12h | Não |
| 5 | Migrar de GetIt para Riverpod DI Puro | Médio | 8h | Não |
| 6 | Corrigir Nomenclatura e Idioma de Pastas | Baixo | 4h | Não |

---

## 8. Plano de Implementação

### Fase 1 (Sprint 5)
- Task: `refactor/auth-notifier-migration`
- Task: `refactor/api-error-handling-standardization`

### Fase 2 (Sprint 6)
- Task: `refactor/freezed-model-migration`
- Task: `refactor/dto-entity-separation`

---

## 9. Recomendações de Tooling

### Lint Rules (analysis_options.yaml)
Ativar `prefer_final_locals`, `always_declare_return_types`, e regras de `riverpod_lint`.

### Guia de Estilo (style-guide.md)
Documentar o uso obrigatório de Freezed e o padrão de nomes para Notifiers.
