# Plano de Implementação — Correção de Erros de Log (Ferramentas de IA & Relações CRM)

Este documento descreve o plano detalhado de implementação para corrigir os erros de log identificados no `cadife-backend`. A correção foca em restabelecer a estabilidade do fluxo de atendimento automatizado (AYA), eliminando falhas de leitura do contexto do lead que resultam em confusão sistemática da IA e alertas indevidos de alucinação/transbordo humano.

---

## 1. Análise de Causa Raiz & Efeitos em Cascata

### 1.1 O Erro Primário (`tool_get_lead_context_failed`)
No log, identificamos a seguinte falha crítica:
```json
{"wa_id": "554791103131", "error": "'str' object has no attribute 'value'", "event": "tool_get_lead_context_failed", "request_id": "7b5d846f-5f67-4251-8631-499e38faa162", "level": "error"}
```

Esta exceção ocorre dentro da função `_get_lead_context_by_wa_id` no arquivo `app/services/ai_tools.py`:
- A função chama `LeadRepository(db).get_by_phone(wa_id)`.
- O `LeadRepository` opera com o modelo de infraestrutura/persistência `LeadModel` (definido em `app/infrastructure/persistence/models/lead_model.py`).
- No `LeadModel`, os campos `status` e `score` são mapeados como strings simples vindas do banco PostgreSQL:
  ```python
  status: Mapped[str] = mapped_column(lead_status_enum, ...)
  score: Mapped[Optional[str]] = mapped_column(lead_score_enum)
  ```
- No entanto, o código de `ai_tools.py` tenta ler estes campos como enums Python (acessando a propriedade `.value`):
  ```python
  "status": lead.status.value if lead.status else None,
  "score": lead.score.value if lead.score else None,
  ```
- Como `lead.status` e `lead.score` retornados do repositório já são instâncias da classe `str`, a tentativa de acessar `.value` lança `AttributeError: 'str' object has no attribute 'value'`.

---

### 1.2 Os Efeitos em Cascata (O Loop do Campo `destino`)
A falha na ferramenta de contexto do lead corrompe todo o fluxo de conversação do WhatsApp da seguinte maneira:

1. **Falha na Busca de Contexto**: Como a ferramenta `get_lead_context_by_wa_id` falha com exceção, o fluxo assume que o lead não pôde ser recuperado (`exists: false`) ou que é um novo atendimento.
2. **Reset do Próximo Campo**: A triagem é forçada a recomeçar do zero, definindo o próximo campo pendente (`next_field`) como `"destino"`.
3. **Preenchimento Fantasma vs. Triagem Stuck**: Conforme o cliente responde (por exemplo, informando que vai viajar com "amigos" ou com orçamento "alto"), a persistência em segundo plano (`persist_lead_data` ou a extração estruturada) consegue preencher os campos reais no banco (completude sobe para 78%, 89% e até 100%), mas o fluxo de orquestração principal continua achando que o próximo passo é perguntar o `"destino"`.
4. **Confusão Sistêmica**: A IA tenta encaixar respostas de outros campos no campo `"destino"`, gerando confusão contínua (`stuck_field: "destino"`, `consecutive_attempts` subindo de 3 a 8).
5. **Transbordo Forçado**: Ao atingir o limite de tentativas frustradas de resolver o `"destino"`, o sistema dispara alertas de alucinação (`ALERT_HALLUCINATION`) para o e-mail de suporte (`frank@cadife.com`) e recomenda transbordo para consultor humano (`human_handoff_recommended`).

---

### 1.3 Eventos Auxiliares no Log (Comportamento Normal)
- **`context_guardrail_violations`**:
  O log registra avisos de violação de guardrail no arquivo `perfis_e_solucoes.md` (chunk 12) devido à menção a valores monetários (`R$ 8.000-15.000/mês`). A estratégia configurada é `"mask"`. 
  *Diagnóstico*: **Comportamento correto e esperado.** O `PriceGuardrail` em `app/services/context_guardrails.py` identificou a menção a preços e aplicou o redator ([REDACTED]), evitando que a IA cite valores comerciais diretamente. Nenhuma ação corretiva é necessária para este aviso.
- **`no_consultant_tokens_for_notification`**:
  Avisos de que não há tokens FCM configurados para notificar consultores sobre a completude do briefing.
  *Diagnóstico*: É um aviso padrão do fluxo de notificação móvel que não impede o funcionamento da IA principal.

---

## 2. Plano de Ação: Correções Propostas

Para corrigir a falha de forma robusta e defensiva (compatível tanto se a propriedade for uma string simples quanto um Enum puro do Python), aplicaremos a mesma verificação segura já utilizada nos campos de briefing (`perfil` e `orcamento`).

### 2.1 Correção 1 — Ferramenta `_get_lead_context_by_wa_id`
No arquivo `/opt/cadife/app/backend/app/services/ai_tools.py`, na função `_get_lead_context_by_wa_id`:

*Código Atual (Linhas 353-354)*:
```python
"status": lead.status.value if lead.status else None,
"score": lead.score.value if lead.score else None,
```

*Correção Proposta*:
```python
"status": (lead.status.value if hasattr(lead.status, "value") else lead.status) if lead.status else None,
"score": (lead.score.value if hasattr(lead.score, "value") else lead.score) if lead.score else None,
```

---

### 2.2 Correção 2 — Ferramenta `_check_existing_lead`
No mesmo arquivo `/opt/cadife/app/backend/app/services/ai_tools.py`, na função `_check_existing_lead`:

*Código Atual (Linhas 584-585)*:
```python
"status": lead.status.value if lead.status else None,
"score": lead.score.value if lead.score else None,
```

*Correção Proposta*:
```python
"status": (lead.status.value if hasattr(lead.status, "value") else lead.status) if lead.status else None,
"score": (lead.score.value if hasattr(lead.score, "value") else lead.score) if lead.score else None,
```

---

## 3. Plano de Testes & Validação

Após a aplicação das correções recomendadas, o fluxo deve ser validado através dos seguintes passos:

1. **Execução de Testes Unitários/Integração Existentes**:
   Navegar até a pasta do backend e rodar a suíte de testes de persistência de webhook para garantir que nenhuma regressão de banco de dados ocorra:
   ```bash
   pytest tests/integration/test_webhook_persistence.py
   ```
2. **Teste de Simulação das Ferramentas**:
   Criar um pequeno script em `/opt/cadife/app/backend/scratch/test_ai_tools_fix.py` para simular a chamada direta de `execute_tool` para `get_lead_context_by_wa_id` e verificar que o JSON de retorno é gerado sem erros e com os campos `status` e `score` preenchidos como strings normais.
3. **Verificação do Log de Produção**:
   Validar que após o processamento da mensagem do WhatsApp, o evento `tool_dispatch` da ferramenta `get_lead_context_by_wa_id` seja seguido por um evento de sucesso, sem disparar a exceção `'str' object has no attribute 'value'`.

---

## 4. Conclusão & Próximos Passos

Esta correção simples, baseada em reflexão de atributos (`hasattr`), resolve de forma elegante e definitiva o problema de dessincronização de tipos entre os modelos de persistência (`LeadModel` com campos `str`) e as suposições feitas pelas ferramentas de IA.

**Ações sugeridas após aprovação deste plano**:
1. Aplicar a correção contida na Seção 2 nos respectivos trechos do arquivo `app/services/ai_tools.py`.
2. Rodar a validação sugerida na Seção 3.
