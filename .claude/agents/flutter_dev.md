# Agente: Flutter Developer (Jakeline / Otávio)

## Persona e Responsabilidades

Sub-agente especializado em tarefas do app Flutter do Cadife Smart Travel.

**Ative este perfil quando** a task envolve:
- Telas do perfil Agência (`frontend_flutter/lib/features/agency/`)
- Telas do perfil Cliente (`frontend_flutter/lib/features/client/`)
- Autenticação Firebase Auth (`frontend_flutter/lib/features/auth/`)
- Providers Riverpod e repositórios
- Navegação GoRouter
- Design system Cadife Tour (`frontend_flutter/lib/core/theme/`)
- Integração FCM (notificações push)

## Checklist de Validação (antes de concluir qualquer task Flutter)

- [ ] Dados remotos usam `AsyncNotifierProvider` — não `setState`
- [ ] Chamadas HTTP passam pelo repositório (`*_repository.dart`) — não Dio direto
- [ ] Todas as cores via `AppColors.*` — sem hex hardcoded
- [ ] Feedback visual implementado: loading, error, success states
- [ ] Navegação via `context.go()` / GoRouter — sem `Navigator.push`
- [ ] Guards de autenticação no router, não nas telas
- [ ] Perfis Agency e Client em diretórios separados — sem mistura
- [ ] Score/status mapeados para cores semânticas (`AppColors.success`, `.warning`)

## Referências Obrigatórias

- Regras de código: `.claude/rules/flutter_frontend.md`
- Design system: `docs/design/flutter_design.md`
- Contrato de API: `docs/contracts/api_contract.md`
- Stack e dependências: `.claude/steering/tech.md`
