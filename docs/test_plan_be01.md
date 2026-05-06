# 🧪 Plano de Testes — Task BE-01 (QA)
**Objetivo:** Garantir a integridade da persistência de leads, a precisão do cálculo de completude e a resiliência do sistema frente a falhas de infraestrutura.

---

## 1. Validação de Schemas (Pydantic)
### Cenário 1.1: Tipos de Dados Incorretos
- **Ação:** Enviar um payload onde o campo `orcamento` (que espera um Enum ou Float) recebe uma string inválida.
- **Script Pytest:**
```python
def test_validation_error():
    with pytest.raises(ValidationError):
        BriefingSchema(orcamento="MUITO_DINHEIRO") # Deve falhar por não ser OrcamentoPerfil
```
- **Resultado Esperado:** O FastAPI deve interceptar o erro e retornar `422 Unprocessable Entity` com detalhes sobre o campo inválido.

### Cenário 1.2: Parsing de Datas
- **Ação:** Enviar data no formato ISO string `"2026-12-25"`.
- **Script Pytest:**
```python
def test_date_parsing():
    schema = BriefingSchema(data_ida="2026-12-25")
    assert isinstance(schema.data_ida, date)
```
- **Resultado Esperado:** O Pydantic deve converter a string automaticamente para um objeto `datetime.date`.

---

## 2. Persistência e Upsert (SQLAlchemy)
### Cenário 2.1: Criação de Lead Novo
- **Comando CURL:**
```bash
curl -X POST http://localhost:8000/webhook/whatsapp \
  -H "Content-Type: application/json" \
  -d '{"object": "whatsapp_business_account", "entry": [{"changes": [{"value": {"messages": [{"from": "5511999999999", "text": {"body": "Quero viajar"}}], "contacts": [{"profile": {"name": "João"}}]}}]}]}'
```
- **Resultado Esperado:** Uma nova linha deve ser criada na tabela `leads` e uma linha relacionada na tabela `briefings`.

### Cenário 2.2: Estratégia de Upsert
- **Ação:** Enviar uma segunda mensagem do mesmo número.
- **Resultado Esperado:** O sistema deve identificar o `telefone_hash` existente e realizar um `UPDATE` no registro (ex: atualizando o nome ou o `atualizado_em`), em vez de criar um novo `UUID`.

---

## 3. Resiliência de PII e Banco de Dados
### Cenário 3.1: Campo Nullable (telefone_hash)
- **Ação:** Simular um backfill de dados onde o `telefone_hash` não é fornecido.
- **Resultado Esperado:** O banco deve aceitar o registro sem erro de `NOT NULL`, validando a migration de PII.

### Cenário 3.2: Tabela Inexistente / Banco Offline
- **Ação:** Renomear a tabela `leads` temporariamente ou derrubar o container DB e tentar um upsert.
- **Resultado Esperado:** O log deve mostrar `database_table_missing` e o sistema deve retornar um erro controlado (ou lançar `RuntimeError` amigável conforme implementado no `lead_service.py`), evitando um crash silencioso.

---

## 4. Lógica de Completude (completude_pct)
### Cenário 4.1: Preenchimento Parcial (20-25%)
- **Ação:** Briefing com apenas `destino`.
- **Cálculo:** `(1/4 campos obrigatórios) * 80% = 20%`.
- **Resultado Esperado:** `completude_pct` deve ser 20 (ou 25 se os pesos forem iguais).

### Cenário 4.2: Preenchimento Total (100%)
- **Ação:** Fornecer Destino, Data Ida, Orçamento e Perfil + campos opcionais.
- **Resultado Esperado:** `completude_pct` deve ser gravado como `100` no banco.

---

## 🚀 Execução dos Testes
Para rodar os testes automatizados criados:
```bash
pytest backend/tests/test_be01_qa.py -v
```
