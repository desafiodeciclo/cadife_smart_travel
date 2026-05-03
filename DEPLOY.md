# Cadife Smart Travel - Deployment & Maintenance

## Manutenção do Redis (Ambiente de Staging)

O ambiente de staging utiliza uma instância dedicada do Redis (`redis_staging`), isolada da produção e do desenvolvimento local para garantir que os testes não afetem outros serviços.

### Limpeza de Cache no Staging (FLUSHDB)

Para realizar a limpeza de cache, rate limits ou sessões expiradas no ambiente de Staging, você deve se conectar especificamente à instância `redis_staging`. A limpeza afeta apenas o staging.

**Passos para limpar o banco de dados (FLUSHDB) no ambiente de Staging:**

1. Acesse o servidor ou ambiente onde o Docker Compose está rodando.
2. Execute o seguinte comando usando o `redis-cli` dentro do container de staging:

```bash
# Entrar no CLI do Redis de staging passando a senha (se houver)
docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me

# No prompt do redis-cli, execute o comando para limpar apenas o banco atual:
127.0.0.1:6379> FLUSHDB

# Para verificar as chaves, você pode rodar (deve retornar array vazio):
127.0.0.1:6379> KEYS *
```

Ou em um único comando no terminal:
```bash
docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me FLUSHDB
```

> **Atenção:** Como configuramos o prefixo `STG_` na aplicação (via `REDIS_PREFIX`), certifique-se de que se for limpar apenas chaves específicas, use o comando:
> `docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me --scan --pattern "STG_*" | xargs -r docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me DEL`

### Health Check e Validação de Conexão

Para testar a persistência e a velocidade de resposta do Redis de Staging:

```bash
# Teste de Ping
docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me PING
# Resposta esperada: PONG

# Teste de Escrita e Leitura (Persistência básica)
docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me SET STG_TESTE_HEALTH "OK"
docker compose exec redis_staging redis-cli -a staging_redis_pass_change_me GET STG_TESTE_HEALTH
```

Você também pode utilizar o script de teste disponibilizado em `backend/scripts/test_redis_staging.py` para validar a conexão do backend com o Redis.
