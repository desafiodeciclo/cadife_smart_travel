# Cadife Smart Travel — Suíte de Testes

Este diretório contém a infraestrutura de testes do projeto, organizada seguindo a pirâmide de testes do Flutter.

## Estrutura

- `helpers/`: Contém utilitários compartilhados (`pumpApp`, fixtures, mocks).
- `unit/`: Testes de unidade (Domain & Application).
- `widget/`: Testes de componentes e telas (UI Behavior).
- `golden/`: Testes de regressão visual (Pixel-perfect).

## Como Executar

### Testes de Unidade e Widget
```bash
flutter test test/unit/
flutter test test/widget/
```

### Golden Tests
Para gerar/atualizar os goldens:
```bash
flutter test test/golden/ --update-goldens
```

### Cobertura de Código
```bash
flutter test --coverage
# Para visualizar em HTML (requer lcov instalado):
# genhtml coverage/lcov.info -o coverage/html
```

### Testes de Integração (E2E)
Os testes de integração utilizam o **Patrol**.
```bash
patrol test --target integration_test/flows/
```

## Diretrizes

1. **Use `pumpApp`**: Sempre utilize o helper `pumpApp` em testes de widget e golden para garantir que o tema e providers estejam configurados.
2. **Fixtures**: Utilize `LeadFixture`, `UserFixture`, etc. para criar modelos de teste. Evite criar modelos inline.
3. **Mocks**: Utilize `Mocktail` para mockar dependências.
