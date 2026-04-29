# Cadife Smart Travel — Product Steering

## Visão Geral e Contexto

A Cadife Tour é uma agência de turismo operando no modelo consultivo multibandeiras. Os dois gargalos críticos atuais:

1. **Atendimento manual não escalável:** representantes perdem horas respondendo as mesmas dúvidas via WhatsApp antes de identificar o potencial real do lead.
2. **Perda de dados:** conversas informais não geram dados estruturados, impossibilitando gestão de pipeline de vendas.

## Solução e Princípio Estratégico

Plataforma integrada de atendimento inteligente com três camadas:

- **AYA (WhatsApp Bot):** recebe cliente, conduz qualificação via briefing estruturado, notifica agência.
- **Backend FastAPI:** orquestra fluxo, persiste leads, aciona notificações push.
- **App Flutter:** CRM para a agência + portal de acompanhamento para o cliente.

**Princípio Inegociável:** O sistema NÃO substitui o consultor humano. A IA é pré-atendente — prepara o terreno para que o consultor realize curadoria, proposta e fechamento. **Automação completa de orçamentos e fechamentos está FORA do MVP.**

## Identidade do Assistente AYA

| Atributo | Valor |
|---|---|
| Nome | AYA (alternativas NOA / OTTO — decidir com PO Diego) |
| Tom | Consultivo e próximo — 80% consultor / 20% vendedor |
| Linguagem | Natural, clara, educada, não invasiva |
| Apresentação | "Olá, sou a AYA da Cadife Tour. Vou te ajudar a organizar sua próxima viagem." |
| Disponibilidade | 24/7 — sem restrição de horário |

## Regras de Negócio Críticas

### Fluxo de Qualificação (Briefing)

A IA coleta **nesta ordem** para maximizar dados com mínimo de perguntas:

| # | Campo | Pergunta |
|---|---|---|
| 1 | Destino | "Você já tem um destino em mente, ou posso te ajudar a escolher?" |
| 2 | Datas | "Tem alguma data em mente para a viagem? Ou ainda está avaliando?" |
| 3 | Nº Pessoas | "Quantas pessoas vão viajar com você?" |
| 4 | Perfil | "É uma viagem em família, casal, sozinho ou grupo de amigos?" |
| 5 | Tipo | "O que você busca: turismo, lazer, aventura, imigração ou outra coisa?" |
| 6 | Preferências | "Prefere clima frio ou quente? Praia ou cidade? Algo mais específico?" |
| 7 | Orçamento | "Tem uma faixa de investimento em mente? (Apenas para eu te orientar melhor)" |
| 8 | Passaporte | "Já possui passaporte válido?" |
| 9 | Experiência | "Já viajou internacionalmente antes?" |

### Score de Qualificação

| Score | Critérios | Ação |
|---|---|---|
| **QUENTE** | Destino + datas + nº pessoas + orçamento definidos | Priorizar contato imediato — oferecer curadoria no mesmo dia |
| **MORNO** | Destino definido, mas datas ou orçamento em aberto | Agendar curadoria e enviar conteúdo de apoio |
| **FRIO** | Apenas interesse genérico, sem dados concretos | Manter nutrição via WhatsApp, follow-up automatizado |

### Horários e Capacidade Operacional

- Atendimento humano: Segunda–Sexta, 09h–16h (Brasília)
- Capacidade: máximo 6 curadorias/dia, duração 30–60 min, intervalo mínimo de 1h entre sessões
- IA: 24/7 sem restrição de horário

### Proibições Absolutas da IA

A IA **NUNCA** deve:
- Gerar preços, valores ou estimativas financeiras
- Confirmar disponibilidade de voos ou hospedagem
- Fechar vendas ou comprometer a empresa comercialmente
- Citar condições de pagamento (cartão, boleto, parcelas)

## Escopo MVP vs Fora do Escopo

**Dentro do MVP:**
- Webhook WhatsApp + bot AYA com RAG
- Coleta e extração estruturada de briefing
- Criação automática de leads com score
- App Flutter: dashboard agência + portal cliente
- Notificações push FCM em tempo real (< 2s)
- Auth JWT + Firebase Auth

**Fora do MVP (roadmap):**
- Integração Amadeus (busca de voos)
- Geração automática de orçamentos
- Pagamentos online
- Motor de recomendação de destinos
- Sugestão de valores médios por destino
