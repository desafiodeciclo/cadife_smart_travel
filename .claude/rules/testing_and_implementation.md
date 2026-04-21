# Regra de Comportamento: Testes e Implementação

## Contexto
Para garantir a confiabilidade do sistema Cadife Smart Travel e evitar regressões no curto prazo de 25 dias do MVP, é mandatório que toda nova funcionalidade, alteração de lógica ou correção de bug seja acompanhada pelos seus respectivos testes automatizados.

## Instruções para o Claude

### 1. Mandato Geral
- **NUNCA** entregue um código de lógica de negócio ou endpoint de API sem um arquivo de teste correspondente.
- **SEMPRE** execute os testes existentes antes de propor mudanças em componentes core para garantir que nada foi quebrado.

### 2. Backend (Python/FastAPI)
- Use o framework **pytest**.
- Testes de endpoints devem usar `httpx.AsyncClient` e herdar as fixtures de banco de dados configuradas em `conftest.py`.
- **Mockar obrigatoriamente** serviços externos: WhatsApp Cloud API, OpenAI, Firebase Admin e serviços de e-mail/SMS.
- Caminho: `backend/tests/`.

### 3. Frontend (Flutter/Dart)
- Use os pacotes `test` e `flutter_test`.
- **Unit Tests:** Para Notifiers (Riverpod), Repositories e classes de domínio.
- **Widget Tests:** Para componentes de UI críticos e fluxos de navegação.
- Use `mocktail` ou `mockito` para simular dependências de API.
- Caminho: `frontend_flutter/test/`.

### 4. Exemplos

#### Exemplo Aceito (Backend)
```python
# backend/tests/test_leads.py
@pytest.mark.asyncio
async def test_create_lead_success(client: AsyncClient):
    payload = {"nome": "Teste", "telefone": "5511999999999", "origem": "whatsapp"}
    response = await client.post("/leads/", json=payload)
    assert response.status_code == 201
    assert response.json()["nome"] == "Teste"
```

#### Exemplo Aceito (Frontend)
```dart
// frontend_flutter/test/features/auth/auth_notifier_test.dart
void main() {
  test('Deve mudar o estado para autenticado após login com sucesso', () async {
    final notifier = AuthNotifier(mockRepository);
    await notifier.login("user@email.com", "senha123");
    expect(notifier.state, isA<Authenticated>());
  });
}
```

#### Exemplo Recusado
- "Aqui está o novo serviço de extração de briefing. (Sem o arquivo `test_extraction_service.py` correspondente)."
- "Adicionei a tela de agendamento. (Sem um widget test básico que valide a renderização dos campos)."
