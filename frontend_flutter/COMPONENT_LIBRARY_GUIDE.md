# Guia de Uso: Biblioteca de Componentes (CDS v3.0)

Este guia explica como acessar, navegar e expandir a biblioteca de componentes interna do Cadife Smart Travel.

## 1. Como Acessar

A biblioteca está disponível apenas em modo **Debug** para garantir que não seja exposta em produção.

1. Certifique-se de que o app está rodando em modo debug (`flutter run`).
2. No navegador ou emulador, navegue para a rota:
   - `.../dev/components`
   - Exemplo no Chrome: `http://localhost:xxxx/#/dev/components`

## 2. Navegação e Interface

A interface é dividida em três áreas principais:

- **Sidebar (Esquerda)**: Use o `NavigationRail` para trocar entre as categorias principais (Botões, Inputs, Cards, etc.).
- **Seletor de Componentes (Topo)**: Dentro de cada categoria, use os `FilterChips` para selecionar a variante específica que deseja visualizar.
- **Área de Visualização (Centro)**: Exibe os detalhes do componente selecionado.

## 3. Explorando um Componente

Cada componente no catálogo exibe:

1. **Preview Real**: O componente renderizado exatamente como apareceria no app. É interativo (você pode clicar em botões, digitar em inputs, etc.).
2. **Código Fonte**: Um snippet de código pronto para ser copiado. Use o botão de **Copiar** (ícone de prancheta) para facilitar a implementação no seu código.
3. **Notas e Props**: Documentação técnica sobre comportamentos, estados e props obrigatórios.
4. **Dark Mode Toggle**: No Header da página, use o ícone de Lua/Sol para testar como o componente se comporta em diferentes temas.

## 4. Como Adicionar um Novo Componente

Siga este passo a passo para registrar um novo componente no catálogo:

### Passo 1: Criar o arquivo de Showcase
Vá para `lib/config/dev/components/` e identifique em qual arquivo seu componente se encaixa (ou crie um novo).

### Passo 2: Definir o `ComponentShowcaseData`
Crie um objeto que descreva seu componente:

```dart
final meuNovoComponente = ComponentShowcaseData(
  name: 'Nome do Componente',
  description: 'Uma breve descrição do que ele faz.',
  category: ComponentCategory.buttons, // Selecione a categoria correta
  builder: (context) => MeuWidget(
    param: 'exemplo',
  ),
  codeSnippet: '''MeuWidget(
  param: 'exemplo',
)''',
  notes: [
    'Prop "param" é obrigatória.',
    'Suporta acessibilidade via TalkBack.',
  ],
);
```

### Passo 3: Registrar na lista global
Adicione seu objeto à lista correspondente no arquivo `lib/config/dev/components/all_showcases.dart` ou exporte-o por lá.

## 5. Boas Práticas

- **Demonstrações Interativas**: Sempre que possível, use um `StatefulWidget` no `builder` para mostrar estados reais (ex: loading, erro, animações).
- **Consistência**: Use os tokens do CDS (`context.cadife`) ao invés de cores hardcoded.
- **Snippets Limpos**: Garanta que o `codeSnippet` seja um exemplo funcional e minimalista.

---
*Dúvidas? Consulte o time de Design System ou verifique as implementações existentes em `lib/config/dev/components/`.*
