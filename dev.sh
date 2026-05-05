#!/usr/bin/env bash
# =============================================================================
# dev.sh — Ambiente de Desenvolvimento Local — Cadife Smart Travel
# =============================================================================
# Orquestra em sequência:
#   1. PostgreSQL + Redis + ChromaDB via Docker Compose (apenas infraestrutura)
#   2. FastAPI com --reload para hot-reload de código (fora do Docker)
#   3. Túnel ngrok apontando para porta 8000 (HTTPS público para o webhook)
#
# Uso:
#   chmod +x dev.sh
#   ./dev.sh
#
# Pré-requisitos:
#   - Docker Engine + Docker Compose v2
#   - ngrok   (https://ngrok.com/download)
#   - uvicorn disponível no PATH (ative o virtualenv antes de rodar)
#   - backend/.env configurado  →  cp backend/.env.example backend/.env
# =============================================================================

set -uo pipefail

# ── Cores ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Constantes ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/.dev-logs"
COMPOSE_FILE="${SCRIPT_DIR}/docker/docker-compose.yml"
API_PORT=8000
NGROK_DASHBOARD_PORT=4040

# ── Estado global ─────────────────────────────────────────────────────────────
UVICORN_PID=""
NGROK_PID=""
NGROK_URL=""

# =============================================================================
# Utilitários de log
# =============================================================================
log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()      { echo -e "${GREEN}[ OK ]${NC}  $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERRO]${NC}  $*" >&2; }
log_section() { echo -e "\n${BOLD}${CYAN}━━━  $*  ━━━${NC}"; }

# =============================================================================
# cleanup — chamado via trap em Ctrl+C ou término do script
# Encerra processos na ordem inversa de inicialização para evitar erros.
# =============================================================================
cleanup() {
    echo ""
    log_section "Encerrando ambiente de desenvolvimento"

    if [ -n "$UVICORN_PID" ] && kill -0 "$UVICORN_PID" 2>/dev/null; then
        kill "$UVICORN_PID" 2>/dev/null
        wait "$UVICORN_PID" 2>/dev/null || true
        log_ok "FastAPI (uvicorn) encerrado — porta ${API_PORT} liberada."
    fi

    if [ -n "$NGROK_PID" ] && kill -0 "$NGROK_PID" 2>/dev/null; then
        kill "$NGROK_PID" 2>/dev/null
        wait "$NGROK_PID" 2>/dev/null || true
        log_ok "Túnel ngrok encerrado."
    fi

    log_info "Parando containers Docker (db, redis, chroma)..."
    docker compose -f "$COMPOSE_FILE" stop db redis chroma 2>/dev/null || true
    log_ok "Containers parados. Ambiente encerrado com sucesso."
    exit 0
}

trap cleanup SIGINT SIGTERM

# =============================================================================
# Passo 1 — Verificar dependências obrigatórias
# =============================================================================
check_dependencies() {
    log_section "Verificando dependências"
    local missing=()

    command -v docker   >/dev/null 2>&1 || missing+=("docker")
    command -v uvicorn  >/dev/null 2>&1 || missing+=("uvicorn  →  pip install uvicorn[standard]")
    command -v ngrok    >/dev/null 2>&1 || missing+=("ngrok    →  https://ngrok.com/download")
    command -v python3  >/dev/null 2>&1 || missing+=("python3")
    command -v curl     >/dev/null 2>&1 || missing+=("curl")
    command -v alembic  >/dev/null 2>&1 || missing+=("alembic  →  pip install alembic")

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Dependências ausentes — instale antes de continuar:"
        for dep in "${missing[@]}"; do
            echo -e "  ${RED}✗${NC}  $dep"
        done
        exit 1
    fi

    log_ok "Todas as dependências encontradas."
}

# =============================================================================
# Passo 2 — Verificar arquivo de configuração .env
# =============================================================================
check_env_file() {
    log_section "Verificando configuração do ambiente"
    cd "$SCRIPT_DIR"

    if [ ! -f "backend/.env" ]; then
        log_error "Arquivo 'backend/.env' não encontrado."
        echo ""
        echo -e "  Crie o arquivo de configuração:"
        echo -e "    ${YELLOW}cp backend/.env.example backend/.env${NC}"
        echo -e "  Em seguida, preencha as variáveis obrigatórias:"
        echo -e "    GEMINI_API_KEY, WHATSAPP_TOKEN, PHONE_NUMBER_ID, VERIFY_TOKEN, JWT_SECRET_KEY"
        exit 1
    fi

    log_ok "Arquivo backend/.env encontrado."

    # Ler NGROK_AUTHTOKEN do .env (opcional, mas recomendado)
    local token
    token=$(grep -E "^NGROK_AUTHTOKEN=" backend/.env 2>/dev/null \
        | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)

    if [ -n "$token" ] && [ "$token" != "seu_ngrok_authtoken_aqui" ] && [ "$token" != "" ]; then
        log_info "NGROK_AUTHTOKEN detectado — autenticando ngrok..."
        ngrok config add-authtoken "$token" >/dev/null 2>&1 && log_ok "ngrok autenticado com sucesso." || true
    else
        log_warn "NGROK_AUTHTOKEN não configurado. O ngrok funcionará com limitações de sessão (2h)."
        log_warn "Token gratuito disponível em: https://dashboard.ngrok.com/get-started/your-authtoken"
    fi
}

# =============================================================================
# Passo 3 — Subir infraestrutura Docker (apenas db, redis, chroma)
# O serviço 'backend' é intencionalmente omitido: o FastAPI roda localmente
# com --reload para hot-reload durante o desenvolvimento.
# =============================================================================
start_infrastructure() {
    log_section "Iniciando infraestrutura Docker"
    log_info "Serviços: PostgreSQL (→ localhost:5433) | Redis (→ localhost:6379) | ChromaDB (→ localhost:8001)"
    echo ""

    docker compose -f "$COMPOSE_FILE" up -d db redis chroma

    # Aguardar PostgreSQL estar pronto para aceitar conexões
    echo -n "  Aguardando PostgreSQL"
    local attempt=0 max_attempts=30
    until docker compose -f "$COMPOSE_FILE" exec -T db \
            pg_isready -U cadife -d cadife_db >/dev/null 2>&1; do
        echo -n "."
        sleep 2
        (( attempt++ ))
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo -e " ${RED}✗  Timeout (60s)${NC}"
            log_error "PostgreSQL não respondeu. Verifique os logs com:"
            echo -e "    docker compose -f docker/docker-compose.yml logs db"
            exit 1
        fi
    done
    echo -e " ${GREEN}✓${NC}"

    # Aguardar Redis
    echo -n "  Aguardando Redis"
    attempt=0 max_attempts=15
    until docker compose -f "$COMPOSE_FILE" exec -T redis \
            redis-cli ping >/dev/null 2>&1; do
        echo -n "."
        sleep 1
        (( attempt++ ))
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo -e " ${RED}✗  Timeout (15s)${NC}"
            log_error "Redis não respondeu. Verifique os logs com:"
            echo -e "    docker compose -f docker/docker-compose.yml logs redis"
            exit 1
        fi
    done
    echo -e " ${GREEN}✓${NC}"
    log_ok "Infraestrutura Docker pronta."
}

# =============================================================================
# Passo 4 — Aplicar migrações do banco de dados
# =============================================================================
run_migrations() {
    log_section "Aplicando migrações do banco de dados"

    (cd "${SCRIPT_DIR}/backend" && alembic upgrade head) && \
        log_ok "Migrações aplicadas." || \
        log_warn "Falha ao aplicar migrações — a API pode iniciar com schema desatualizado."
}

# =============================================================================
# Passo 5 — Iniciar servidor FastAPI com hot-reload
# =============================================================================
start_api() {
    log_section "Iniciando servidor FastAPI"
    mkdir -p "$LOG_DIR"

    # Verificar se a porta já está em uso
    if lsof -ti ":${API_PORT}" >/dev/null 2>&1; then
        log_error "Porta ${API_PORT} já está em uso. Encerre o processo antes de continuar:"
        echo -e "    lsof -ti :${API_PORT} | xargs kill -9"
        exit 1
    fi

    log_info "Iniciando uvicorn com --reload (observa mudanças em backend/app/)"
    log_info "Logs em tempo real: tail -f .dev-logs/uvicorn.log"

    (cd "${SCRIPT_DIR}/backend" && \
        uvicorn main:app \
            --host 0.0.0.0 \
            --port "${API_PORT}" \
            --reload \
            --reload-dir app \
            --log-level info \
        >> "${LOG_DIR}/uvicorn.log" 2>&1) &
    UVICORN_PID=$!

    # Aguardar a API responder no /health
    echo -n "  Aguardando FastAPI inicializar"
    local attempt=0 max_attempts=25
    until curl -sf "http://localhost:${API_PORT}/health" >/dev/null 2>&1; do
        # Verificar se o processo ainda está vivo
        if ! kill -0 "$UVICORN_PID" 2>/dev/null; then
            echo -e " ${RED}✗  Processo morreu${NC}"
            log_error "uvicorn encerrou inesperadamente. Últimas linhas do log:"
            tail -30 "${LOG_DIR}/uvicorn.log" 2>/dev/null || true
            exit 1
        fi
        echo -n "."
        sleep 1
        (( attempt++ ))
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo -e " ${RED}✗  Timeout (25s)${NC}"
            log_error "FastAPI não respondeu. Últimas linhas do log:"
            tail -30 "${LOG_DIR}/uvicorn.log" 2>/dev/null || true
            exit 1
        fi
    done
    echo -e " ${GREEN}✓${NC}"
    log_ok "FastAPI respondendo em http://localhost:${API_PORT}"
}

# =============================================================================
# Passo 6 — Iniciar túnel ngrok
# =============================================================================
start_ngrok() {
    log_section "Iniciando túnel ngrok"
    mkdir -p "$LOG_DIR"

    # Encerrar instância anterior do ngrok se houver
    pkill -f "ngrok http" 2>/dev/null || true
    sleep 1

    ngrok http "${API_PORT}" --log=stdout > "${LOG_DIR}/ngrok.log" 2>&1 &
    NGROK_PID=$!

    # Aguardar o dashboard local do ngrok (porta 4040) responder
    echo -n "  Aguardando túnel ngrok"
    local attempt=0 max_attempts=20
    until curl -sf "http://localhost:${NGROK_DASHBOARD_PORT}/api/tunnels" >/dev/null 2>&1; do
        if ! kill -0 "$NGROK_PID" 2>/dev/null; then
            echo -e " ${RED}✗  Processo morreu${NC}"
            log_error "ngrok encerrou inesperadamente. Últimas linhas do log:"
            tail -10 "${LOG_DIR}/ngrok.log" 2>/dev/null || true
            exit 1
        fi
        echo -n "."
        sleep 1
        (( attempt++ ))
        if [ "$attempt" -ge "$max_attempts" ]; then
            echo -e " ${RED}✗  Timeout (20s)${NC}"
            log_error "ngrok não iniciou. Últimas linhas do log:"
            tail -10 "${LOG_DIR}/ngrok.log" 2>/dev/null || true
            exit 1
        fi
    done
    echo -e " ${GREEN}✓${NC}"

    # Extrair a URL HTTPS pública via API local do ngrok
    NGROK_URL=$(curl -sf "http://localhost:${NGROK_DASHBOARD_PORT}/api/tunnels" \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    url = next((t['public_url'] for t in tunnels if t['public_url'].startswith('https')), '')
    print(url)
except Exception:
    print('')
" 2>/dev/null || echo "")

    log_ok "Túnel ngrok ativo."
}

# =============================================================================
# Resumo final — exibe todas as URLs e instruções de configuração
# =============================================================================
show_summary() {
    local webhook_url="${NGROK_URL}/webhook/whatsapp"

    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║      CADIFE SMART TRAVEL  —  Ambiente Dev Ativo  ✓               ║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Endpoints locais:${NC}"
    echo -e "  ├─ API FastAPI    →  ${CYAN}http://localhost:${API_PORT}${NC}"
    echo -e "  ├─ Swagger Docs   →  ${CYAN}http://localhost:${API_PORT}/docs${NC}"
    echo -e "  ├─ PostgreSQL     →  ${CYAN}localhost:5433${NC}  (cadife / cadife)"
    echo -e "  ├─ Redis          →  ${CYAN}localhost:6379${NC}"
    echo -e "  ├─ ChromaDB       →  ${CYAN}http://localhost:8001${NC}"
    echo -e "  └─ ngrok UI       →  ${CYAN}http://localhost:${NGROK_DASHBOARD_PORT}${NC}"
    echo ""

    if [ -n "$NGROK_URL" ]; then
        echo -e "  ${BOLD}${YELLOW}┌─ URL pública HTTPS do ngrok: ─────────────────────────────────────┐${NC}"
        echo -e "  ${BOLD}${YELLOW}│${NC}  ${BOLD}${GREEN}${NGROK_URL}${NC}"
        echo -e "  ${BOLD}${YELLOW}│${NC}"
        echo -e "  ${BOLD}${YELLOW}│${NC}  URL do Webhook para o Meta:"
        echo -e "  ${BOLD}${YELLOW}│${NC}  ${BOLD}${GREEN}${webhook_url}${NC}"
        echo -e "  ${BOLD}${YELLOW}└───────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "  ${BOLD}Como registrar no Meta for Developers (passo a passo):${NC}"
        echo -e "  1. Acesse: https://developers.facebook.com → Meu App → WhatsApp → Configuração"
        echo -e "  2. Em ${YELLOW}Callback URL${NC}, cole:"
        echo -e "     ${GREEN}${webhook_url}${NC}"
        echo -e "  3. Em ${YELLOW}Verify Token${NC}, cole o valor de ${YELLOW}VERIFY_TOKEN${NC} do seu backend/.env"
        echo -e "  4. Clique em ${YELLOW}Verificar e Salvar${NC}."
        echo -e "  5. Assine os campos: ${YELLOW}messages${NC} e ${YELLOW}message_deliveries${NC}."
        echo ""
        echo -e "  ${BOLD}${RED}ATENÇÃO:${NC} A URL do ngrok muda a cada restart do script."
        echo -e "  Para URL fixa, configure um domínio ngrok estático no plano pago"
        echo -e "  ou use NGROK_DOMAIN no backend/.env (ver .env.example)."
    else
        echo -e "  ${YELLOW}URL ngrok:${NC} Não foi possível extrair automaticamente."
        echo -e "  Acesse ${CYAN}http://localhost:${NGROK_DASHBOARD_PORT}${NC} para ver a URL pública."
    fi

    echo ""
    echo -e "  ${BOLD}Logs em tempo real:${NC}"
    echo -e "  ├─ FastAPI:  ${CYAN}tail -f .dev-logs/uvicorn.log${NC}"
    echo -e "  └─ ngrok:    ${CYAN}tail -f .dev-logs/ngrok.log${NC}"
    echo ""
    echo -e "  ${BOLD}${RED}Pressione Ctrl+C para encerrar todos os processos e containers.${NC}"
    echo ""
}

# =============================================================================
# ENTRYPOINT
# =============================================================================
main() {
    echo ""
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}   Cadife Smart Travel  —  Iniciando Ambiente de Desenvolvimento  ${NC}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════════════════════${NC}"

    check_dependencies
    check_env_file
    start_infrastructure
    run_migrations
    start_api
    start_ngrok
    show_summary

    # Bloqueia o script aguardando o uvicorn; ao sair (Ctrl+C), o trap dispara cleanup()
    wait "$UVICORN_PID" 2>/dev/null || true
}

main
