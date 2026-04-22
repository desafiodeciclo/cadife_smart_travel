# Por que o login não funciona e como validar visualmente o app

**Data:** 2026-04-21  
**Contexto:** Sprint de ThemeData & Design Tokens + Router System & Guards

---

## 1. Por que o login falha ao rodar o app

### Causa raiz: backend não está rodando

Quando você toca em **"Entrar"**, o `AuthNotifier` faz duas chamadas HTTP reais:

```
POST http://localhost:8000/auth/login   ← credenciais
GET  http://localhost:8000/users/me    ← busca perfil do usuário
```

O endereço `localhost:8000` é o servidor FastAPI local. Como ele **não está rodando**, o Dio lança um `DioException` de conexão recusada, o `AuthNotifier` captura o erro e exibe:

> "Credenciais inválidas. Verifique e-mail e senha."

Mas o problema não é a senha — é que não existe servidor para responder. Isso é esperado para essa fase do projeto: o backend e o app estão sendo desenvolvidos em paralelo.

**Arquivo responsável:** [auth_notifier.dart](../../frontend_flutter/lib/features/auth/auth_notifier.dart) — método `login()`, linha 51.

---

## 2. Por que não existe opção "Criar conta"

Isso é **decisão de produto, não omissão técnica**.

Na Cadife Tour, contas de usuário não são criadas pelos próprios usuários pelo app. O fluxo é:

- **Conta de agência (consultor):** criada manualmente pelo admin da Cadife Tour no painel administrativo. O consultor recebe as credenciais por e-mail/WhatsApp.
- **Conta de cliente:** criada automaticamente pelo backend quando o lead chega pelo WhatsApp Bot (AYA). O cliente recebe um link/credencial para acessar o portal.

Portanto, uma tela de "Cadastre-se" **não faz parte do escopo do MVP** e nunca esteve planejada. Adicionar um botão de cadastro seria uma feature nova que precisaria de aprovação do PO Diego e uma spec em `specs/pending/`.

---

## 3. Como validar visualmente o que foi implementado

### Opção A — Ver o tema na tela de login (sem backend)

Esta opção já funciona hoje, sem nenhuma mudança.

```bash
cd frontend_flutter
flutter run
```

Na tela de login você já vê:
- Fundo `#393532` (marrom escuro da Cadife Tour)
- Card branco com borda arredondada (12px, `cardBackground`)
- Botão vermelho `#dd0b0e` com altura mínima de 48px
- Tipografia Roboto nos estilos H5/H6 definidos

**Para testar o dark mode:** mude o tema do seu dispositivo/emulador para modo escuro — o app responde automaticamente via `ThemeMode.system`.

---

### Opção B — Entrar nas telas do dashboard sem backend (bypass temporário)

Para ver as telas internas com o BottomNavBar e as transições SharedAxis, faça esta modificação **temporária** no `AuthNotifier`:

**Arquivo:** [auth_notifier.dart](../../frontend_flutter/lib/features/auth/auth_notifier.dart)

Localize o método `_checkSession()` (linha 36) e substitua temporariamente por:

```dart
// MOCK TEMPORÁRIO — remover antes de commitar
Future<void> _checkSession() async {
  await Future.delayed(const Duration(milliseconds: 500)); // simula latência
  state = state.copyWith(
    isLoggedIn: true,
    userPerfil: 'agencia', // troque por 'cliente' para ver o portal do cliente
  );
}
```

Depois de rodar o app e validar, **reverta** o método para o original:

```dart
Future<void> _checkSession() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  if (token == null) return;
  try {
    final response = await _api.get('/users/me');
    state = state.copyWith(
      isLoggedIn: true,
      userPerfil: response.data['perfil'],
    );
  } catch (_) {
    await _api.clearTokens();
  }
}
```

> **Importante:** nunca commite o mock. Use `git diff` antes de qualquer commit para confirmar que o arquivo está revertido.

---

### O que observar em cada tela

#### Tela de Login
| O que verificar | Onde aparece |
|---|---|
| Fundo marrom `#393532` | Scaffold completo |
| Logo "CADIFE TOUR" em branco, bold, letter-spacing 2 | Topo |
| Card branco com sombra sutil | Formulário |
| Botão vermelho `#dd0b0e`, 48px de altura | "Entrar" |
| Spinner vermelho durante loading | Após tocar "Entrar" |

#### Dashboard da Agência (após bypass)
| O que verificar | Onde aparece |
|---|---|
| BottomNavBar marrom `#393532` com 3 tabs | Rodapé |
| Ícone ativo em vermelho `#dd0b0e` | Tab selecionada |
| Animação SharedAxis horizontal ao trocar tabs | Ao tocar em Leads / Agenda |
| Transição desliza para ESQUERDA ao avançar (Dashboard→Leads→Agenda) | Ordem dos tabs |
| Transição desliza para DIREITA ao voltar (Agenda→Leads→Dashboard) | Ordem reversa |

#### Portal do Cliente (após bypass com `userPerfil: 'cliente'`)
| O que verificar | Onde aparece |
|---|---|
| BottomNavBar com tabs: Minha Viagem / Histórico / Documentos | Rodapé |
| Mesma animação SharedAxis horizontal | Ao trocar tabs |

#### Dark Mode (mudar tema do sistema)
| O que verificar | Onde aparece |
|---|---|
| Scaffold vira `#121212` | Fundo geral |
| Cards viram `#2C2C2C` | Cards de conteúdo |
| Botões ficam vermelho mais claro `#FF4447` (contraste melhor) | Botão "Entrar" |
| Textos ficam `#F5F5F5` (near-white) | Todos os textos primários |
| BottomNavBar vira `#1E1B19` (marrom escuro) | Rodapé |

---

### Opção C — Inspetor de Widgets do Flutter (sem rodar no device)

Com o app rodando em qualquer modo, abra o **Flutter DevTools**:

```bash
# O terminal onde o app está rodando mostrará uma URL como:
# Flutter DevTools: http://127.0.0.1:9101?uri=...
```

No DevTools, vá em **Widget Inspector** → selecione qualquer widget → veja em **Details Tree** as propriedades de cor, tamanho e estilo aplicadas. Isso confirma que os tokens do `CadifeThemeExtension` estão sendo injetados corretamente via `ThemeExtension`.

---

## 4. Quando o login vai funcionar de verdade

O login funcionará quando o backend FastAPI estiver rodando localmente:

```bash
# No diretório backend/
cd ../../backend
docker compose up -d       # sobe PostgreSQL + Redis
uvicorn app.main:app --reload --port 8000
```

Com o servidor no ar, o fluxo completo de autenticação funcionará sem nenhuma mudança no Flutter.

---

## Resumo

| Problema | Causa | Solução |
|---|---|---|
| Login falha | Backend `localhost:8000` não está rodando | Subir o backend FastAPI |
| Não há "Criar conta" | Decisão de produto — contas são criadas pelo admin | Não é bug, é design |
| Não consigo ver o dashboard | Depende de auth real | Usar bypass temporário no `_checkSession()` |
