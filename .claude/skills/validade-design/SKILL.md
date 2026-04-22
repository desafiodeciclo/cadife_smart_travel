# Skill: /validate-design

## Descrição

Auditoria focada em UI/UX para garantir a integridade visual do frontend. A skill varre o código do frontend (temas, componentes e telas) verificando se a implementação respeita rigorosamente o Design System definido no `spec` (paleta de cores, tokens de tipografia, espaçamentos, sombras, etc.).

## Trigger

Ativado quando o dev escreve: `/validate-design`, "validar frontend com o spec", "checar aderência de UI" ou "revisar design".

## Processo do Agente (Workflow)

1. **Carregamento dos Tokens de Design:** Ler a documentação oficial (`docs/design/`, `spec` ou regras em `.claude/steering/`) para absorver as variáveis exatas aprovadas (códigos hexadecimais, fontes principais/secundárias, tamanhos de fonte, etc.).
2. **Análise do Tema Global:** Verificar se o arquivo central de estilização do Frontend (ex: `theme.dart` ou `globals.css`) mapeia corretamente todos os tokens do spec.
3. **Busca por Anti-patterns Visuais:**
   - Rastrear telas e componentes em busca de valores visuais *hardcoded* (cores cruas inseridas direto no componente em vez de referenciar a variável do tema).
   - Validar se famílias tipográficas não-homologadas estão sendo importadas ou utilizadas.
4. **Geração de Relatório de UI:** Exibir ao desenvolvedor um sumário claro com:
   - Os desvios visuais encontrados (o que está no código vs. o que diz o spec).
   - Recomendações de refatoração para utilizar as variáveis do tema global em vez de valores avulsos.

## Restrições

- O agente nunca deve reescrever o código do frontend sem primeiro apresentar as divergências visuais para aprovação do desenvolvedor.
- Não avaliar lógicas de negócio ou conexões de API nesta rotina; o foco é **100% integridade de Design System**.
- Qualquer cor, espaçamento ou fonte que não exista no spec deve ser categoricamente reportada como "Token Inválido".
