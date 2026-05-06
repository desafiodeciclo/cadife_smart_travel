#!/usr/bin/env python3
"""
dev.py — Ambiente de Desenvolvimento Local — Cadife Smart Travel
Compatível com: macOS, Linux, Windows (PowerShell 7+ / Git Bash / WSL2)

Uso:
  python dev.py          # macOS / Linux / Windows
  python3 dev.py         # macOS / Linux

Pré-requisitos:
  - Docker Engine + Docker Compose v2
  - ngrok   (https://ngrok.com/download)
  - uvicorn disponível no PATH (ative o virtualenv antes de rodar)
  - backend/.env configurado  →  cp backend/.env.example backend/.env
"""

import json
import os
import platform
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

# ─── Constants ────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).parent.resolve()
LOG_DIR = SCRIPT_DIR / ".dev-logs"
COMPOSE_FILE = SCRIPT_DIR / "docker" / "docker-compose.yml"
BACKEND_DIR = SCRIPT_DIR / "backend"
API_PORT = 8000
NGROK_DASHBOARD_PORT = 4040
MIN_FREE_RAM_MB = 1024  # 1 GB mínimo recomendado

OS_NAME = platform.system()  # "Darwin" | "Linux" | "Windows"
IS_WIN = OS_NAME == "Windows"
IS_MAC = OS_NAME == "Darwin"
IS_LIN = OS_NAME == "Linux"

# ─── ANSI Colors ──────────────────────────────────────────────────────────────
# Habilitado: macOS, Linux, Windows Terminal, VS Code, Git Bash, WSL
# Desabilitado: Windows CMD clássico
_ansi = sys.stdout.isatty() and (not IS_WIN or os.environ.get("WT_SESSION") or os.environ.get("TERM"))

RED    = "\033[0;31m" if _ansi else ""
GREEN  = "\033[0;32m" if _ansi else ""
YELLOW = "\033[1;33m" if _ansi else ""
BLUE   = "\033[0;34m" if _ansi else ""
CYAN   = "\033[0;36m" if _ansi else ""
BOLD   = "\033[1m"    if _ansi else ""
NC     = "\033[0m"    if _ansi else ""

# ─── Global process registry ──────────────────────────────────────────────────
_children: list[subprocess.Popen] = []
_ngrok_url = ""

# =============================================================================
# Logging
# =============================================================================
def log_info(msg: str):    print(f"{BLUE}[INFO]{NC}  {msg}")
def log_ok(msg: str):      print(f"{GREEN}[ OK ]{NC}  {msg}")
def log_warn(msg: str):    print(f"{YELLOW}[WARN]{NC}  {msg}")
def log_error(msg: str):   print(f"{RED}[ERRO]{NC}  {msg}", file=sys.stderr)
def log_section(msg: str): print(f"\n{BOLD}{CYAN}━━━  {msg}  ━━━{NC}")


# =============================================================================
# Verificação de RAM disponível (multiplataforma)
# =============================================================================
def _available_ram_mb() -> float:
    """Retorna RAM disponível em MB. Retorna 9999 em caso de erro (não bloqueia)."""
    try:
        if IS_MAC:
            # vm_stat reporta em páginas de 4096 bytes
            out = subprocess.check_output(["vm_stat"], text=True)
            pages = {"free": 0, "inactive": 0, "speculative": 0}
            keys = {"Pages free": "free", "Pages inactive": "inactive",
                    "Pages speculative": "speculative"}
            for line in out.splitlines():
                for label, key in keys.items():
                    if line.startswith(label):
                        pages[key] = int(line.split(":")[1].strip().rstrip("."))
            available = (pages["free"] + pages["inactive"] + pages["speculative"]) * 4096
            return available / (1024 * 1024)

        elif IS_LIN:
            with open("/proc/meminfo") as f:
                for line in f:
                    if line.startswith("MemAvailable:"):
                        return int(line.split()[1]) / 1024  # kB → MB

        elif IS_WIN:
            out = subprocess.check_output(
                ["wmic", "OS", "get", "FreePhysicalMemory", "/Value"],
                text=True, creationflags=subprocess.CREATE_NO_WINDOW
            )
            for line in out.splitlines():
                if "FreePhysicalMemory" in line:
                    return int(line.split("=")[1].strip()) / 1024  # kB → MB

    except Exception:
        pass
    return 9999.0


def check_ram():
    log_section("Verificando memória RAM disponível")
    available = _available_ram_mb()

    if available >= MIN_FREE_RAM_MB:
        log_ok(f"RAM disponível: {available:.0f} MB — suficiente para o ambiente.")
        return

    log_warn(f"Memória disponível baixa: {available:.0f} MB (mínimo recomendado: {MIN_FREE_RAM_MB} MB)")
    log_warn("ChromaDB + LangChain + PostgreSQL + Redis + FastAPI exigem ~1.5 GB livres.")
    print()

    if IS_MAC:
        log_info("Para liberar RAM no macOS:")
        print("    sudo purge")
        print("    # ou feche aplicações pesadas (Slack, Chrome, etc.)")
    elif IS_LIN:
        log_info("Para liberar cache de página no Linux (requer root):")
        print("    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches")
    elif IS_WIN:
        log_info("Para liberar RAM no Windows:")
        print("    # Feche aplicações desnecessárias")
        print("    # Se usar WSL2: wsl --shutdown  (libera memória do kernel WSL)")
        print("    # PowerShell (admin): [System.GC]::Collect()")

    print()
    try:
        answer = input("  Continuar mesmo assim? [s/N] ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        answer = "n"

    if answer not in ("s", "sim", "y", "yes"):
        sys.exit(1)


# =============================================================================
# Verificar dependências
# =============================================================================
_DEPS: dict[str, str] = {
    "docker":  "https://docs.docker.com/get-docker/",
    "uvicorn": "pip install 'uvicorn[standard]'",
    "ngrok":   "https://ngrok.com/download",
    "alembic": "pip install alembic",
}
# python3 vs python (Windows muitas vezes só tem 'python')
_PYTHON_CMD = "python" if IS_WIN else "python3"
_DEPS[_PYTHON_CMD] = "https://python.org/downloads"
if not IS_WIN:
    _DEPS["curl"] = "https://curl.se"


def check_dependencies():
    log_section("Verificando dependências")
    missing = [(cmd, hint) for cmd, hint in _DEPS.items() if shutil.which(cmd) is None]

    if missing:
        log_error("Dependências ausentes — instale antes de continuar:")
        for cmd, hint in missing:
            print(f"  {RED}✗{NC}  {cmd:<12} →  {hint}")
        sys.exit(1)

    log_ok("Todas as dependências encontradas.")


# =============================================================================
# Verificar .env
# =============================================================================
def check_env_file():
    log_section("Verificando configuração do ambiente")
    env_path = BACKEND_DIR / ".env"

    if not env_path.exists():
        log_error("Arquivo 'backend/.env' não encontrado.")
        sep = "\\" if IS_WIN else "/"
        print()
        print("  Crie o arquivo de configuração:")
        print(f"    {YELLOW}cp backend{sep}.env.example backend{sep}.env{NC}")
        print("  Preencha as variáveis obrigatórias:")
        print("    GEMINI_API_KEY, WHATSAPP_TOKEN, PHONE_NUMBER_ID, VERIFY_TOKEN, JWT_SECRET_KEY")
        sys.exit(1)

    log_ok("Arquivo backend/.env encontrado.")

    # Ler NGROK_AUTHTOKEN do .env
    token = ""
    for line in env_path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("NGROK_AUTHTOKEN="):
            token = line.split("=", 1)[1].strip().strip('"').strip("'")
            break

    placeholder = "seu_ngrok_authtoken_aqui"
    if token and token != placeholder:
        log_info("NGROK_AUTHTOKEN detectado — autenticando ngrok...")
        result = subprocess.run(
            ["ngrok", "config", "add-authtoken", token],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            log_ok("ngrok autenticado com sucesso.")
        else:
            log_warn("Falha ao autenticar ngrok. Verifique o token.")
    else:
        log_warn("NGROK_AUTHTOKEN não configurado. ngrok funcionará com limitações (2h).")
        log_warn("Token gratuito: https://dashboard.ngrok.com/get-started/your-authtoken")


# =============================================================================
# Utilitários
# =============================================================================
def _wait_for(check_fn, label: str, timeout_s: int, interval_s: float = 1.0) -> bool:
    print(f"  Aguardando {label}", end="", flush=True)
    elapsed = 0.0
    while elapsed < timeout_s:
        result = check_fn()
        if result:
            print(f" {GREEN}✓{NC}")
            return True
        if result is None:  # sinaliza morte do processo
            print(f" {RED}✗  Processo morreu{NC}")
            return False
        print(".", end="", flush=True)
        time.sleep(interval_s)
        elapsed += interval_s
    print(f" {RED}✗  Timeout ({timeout_s}s){NC}")
    return False


def _tail_log(path: Path, lines: int = 30):
    try:
        text = path.read_text(errors="replace").splitlines()
        for line in text[-lines:]:
            print(f"    {line}")
    except Exception:
        pass


def _port_in_use(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.5)
        return s.connect_ex(("127.0.0.1", port)) == 0


def _http_ok(url: str, timeout: float = 1.0) -> bool:
    try:
        urllib.request.urlopen(url, timeout=timeout)
        return True
    except Exception:
        return False


# =============================================================================
# Passo 1 — Infraestrutura Docker
# =============================================================================
def _docker_exec_ok(*args: str) -> bool:
    r = subprocess.run(
        ["docker", "compose", "-f", str(COMPOSE_FILE), "exec", "-T", *args],
        capture_output=True
    )
    return r.returncode == 0


def start_infrastructure():
    log_section("Iniciando infraestrutura Docker")
    log_info("Serviços: PostgreSQL (→ localhost:5433) | Redis (→ localhost:6379) | ChromaDB (→ localhost:8001)")
    print()

    subprocess.run(
        ["docker", "compose", "-f", str(COMPOSE_FILE), "up", "-d", "db", "redis", "chroma"],
        check=True
    )

    if not _wait_for(
        lambda: _docker_exec_ok("db", "pg_isready", "-U", "cadife", "-d", "cadife_db"),
        "PostgreSQL", timeout_s=60, interval_s=2
    ):
        log_error("PostgreSQL não respondeu. Verifique:")
        print(f"    docker compose -f docker/docker-compose.yml logs db")
        sys.exit(1)

    if not _wait_for(
        lambda: _docker_exec_ok("redis", "redis-cli", "ping"),
        "Redis", timeout_s=15
    ):
        log_error("Redis não respondeu. Verifique:")
        print(f"    docker compose -f docker/docker-compose.yml logs redis")
        sys.exit(1)

    log_ok("Infraestrutura Docker pronta.")


# =============================================================================
# Passo 2 — Migrações
# =============================================================================
def run_migrations():
    log_section("Aplicando migrações do banco de dados")
    result = subprocess.run(["alembic", "upgrade", "head"], cwd=BACKEND_DIR)
    if result.returncode == 0:
        log_ok("Migrações aplicadas.")
    else:
        log_warn("Falha ao aplicar migrações — a API pode iniciar com schema desatualizado.")


# =============================================================================
# Passo 3 — Servidor FastAPI
# =============================================================================
def start_api() -> subprocess.Popen:
    log_section("Iniciando servidor FastAPI")
    LOG_DIR.mkdir(exist_ok=True)

    if _port_in_use(API_PORT):
        log_error(f"Porta {API_PORT} já está em uso. Encerre o processo antes:")
        if IS_WIN:
            print(f"    netstat -ano | findstr :{API_PORT}")
            print(f"    taskkill /PID <pid> /F")
        else:
            print(f"    lsof -ti :{API_PORT} | xargs kill -9")
        sys.exit(1)

    log_info("Iniciando uvicorn com --reload (observa mudanças em backend/app/)")
    log_info("Logs: tail -f .dev-logs/uvicorn.log")

    env = os.environ.copy()
    # Dica ao alocador para devolver memória liberada ao SO mais cedo
    env["MALLOC_TRIM_THRESHOLD_"] = "65536"
    # Força GC agressivo no CPython ao pressionar memória
    env["PYTHONGC"] = "1"

    log_file = (LOG_DIR / "uvicorn.log").open("ab")
    proc = subprocess.Popen(
        [sys.executable, "-m", "uvicorn", "main:app",
         "--host", "0.0.0.0",
         "--port", str(API_PORT),
         "--reload",
         "--reload-dir", "app",
         "--log-level", "info"],
        cwd=BACKEND_DIR,
        stdout=log_file,
        stderr=log_file,
        env=env,
    )
    _children.append(proc)

    print(f"  Aguardando FastAPI inicializar", end="", flush=True)
    for _ in range(25):
        if proc.poll() is not None:
            print(f" {RED}✗  Processo morreu{NC}")
            log_error("uvicorn encerrou inesperadamente. Últimas linhas do log:")
            _tail_log(LOG_DIR / "uvicorn.log")
            sys.exit(1)
        if _http_ok(f"http://localhost:{API_PORT}/health"):
            print(f" {GREEN}✓{NC}")
            break
        print(".", end="", flush=True)
        time.sleep(1)
    else:
        print(f" {RED}✗  Timeout (25s){NC}")
        log_error("FastAPI não respondeu. Últimas linhas do log:")
        _tail_log(LOG_DIR / "uvicorn.log")
        sys.exit(1)

    log_ok(f"FastAPI respondendo em http://localhost:{API_PORT}")
    return proc


# =============================================================================
# Passo 4 — Túnel ngrok
# =============================================================================
def _get_ngrok_url() -> str:
    try:
        with urllib.request.urlopen(
            f"http://localhost:{NGROK_DASHBOARD_PORT}/api/tunnels", timeout=3
        ) as resp:
            data = json.loads(resp.read())
            for t in data.get("tunnels", []):
                if t.get("public_url", "").startswith("https"):
                    return t["public_url"]
    except Exception:
        pass
    return ""


def start_ngrok() -> subprocess.Popen:
    log_section("Iniciando túnel ngrok")
    LOG_DIR.mkdir(exist_ok=True)

    # Encerrar instância anterior
    if IS_WIN:
        subprocess.run(["taskkill", "/IM", "ngrok.exe", "/F"], capture_output=True)
    else:
        subprocess.run(["pkill", "-f", "ngrok http"], capture_output=True)
    time.sleep(1)

    log_file = (LOG_DIR / "ngrok.log").open("ab")
    popen_kwargs: dict = dict(stdout=log_file, stderr=log_file)
    if IS_WIN:
        popen_kwargs["creationflags"] = subprocess.CREATE_NO_WINDOW

    proc = subprocess.Popen(
        ["ngrok", "http", str(API_PORT), "--log=stdout"],
        **popen_kwargs
    )
    _children.append(proc)

    print(f"  Aguardando túnel ngrok", end="", flush=True)
    for _ in range(20):
        if proc.poll() is not None:
            print(f" {RED}✗  Processo morreu{NC}")
            log_error("ngrok encerrou inesperadamente. Últimas linhas do log:")
            _tail_log(LOG_DIR / "ngrok.log", 10)
            sys.exit(1)
        if _http_ok(f"http://localhost:{NGROK_DASHBOARD_PORT}/api/tunnels"):
            print(f" {GREEN}✓{NC}")
            break
        print(".", end="", flush=True)
        time.sleep(1)
    else:
        print(f" {RED}✗  Timeout (20s){NC}")
        log_error("ngrok não iniciou. Últimas linhas do log:")
        _tail_log(LOG_DIR / "ngrok.log", 10)
        sys.exit(1)

    global _ngrok_url
    _ngrok_url = _get_ngrok_url()
    log_ok("Túnel ngrok ativo.")
    return proc


# =============================================================================
# Resumo final
# =============================================================================
def show_summary():
    webhook_url = f"{_ngrok_url}/webhook/whatsapp"
    tail_cmd = "Get-Content -Wait .dev-logs\\uvicorn.log" if IS_WIN else "tail -f .dev-logs/uvicorn.log"

    print()
    print(f"{BOLD}{GREEN}╔══════════════════════════════════════════════════════════════════╗{NC}")
    print(f"{BOLD}{GREEN}║      CADIFE SMART TRAVEL  —  Ambiente Dev Ativo  ✓               ║{NC}")
    print(f"{BOLD}{GREEN}╚══════════════════════════════════════════════════════════════════╝{NC}")
    print()
    print(f"  {BOLD}Endpoints locais:{NC}")
    print(f"  ├─ API FastAPI    →  {CYAN}http://localhost:{API_PORT}{NC}")
    print(f"  ├─ Swagger Docs   →  {CYAN}http://localhost:{API_PORT}/docs{NC}")
    print(f"  ├─ PostgreSQL     →  {CYAN}localhost:5433{NC}  (cadife / cadife)")
    print(f"  ├─ Redis          →  {CYAN}localhost:6379{NC}")
    print(f"  ├─ ChromaDB       →  {CYAN}http://localhost:8001{NC}")
    print(f"  └─ ngrok UI       →  {CYAN}http://localhost:{NGROK_DASHBOARD_PORT}{NC}")
    print()

    if _ngrok_url:
        print(f"  {BOLD}{YELLOW}┌─ URL pública HTTPS do ngrok: ─────────────────────────────────────┐{NC}")
        print(f"  {BOLD}{YELLOW}│{NC}  {BOLD}{GREEN}{_ngrok_url}{NC}")
        print(f"  {BOLD}{YELLOW}│{NC}")
        print(f"  {BOLD}{YELLOW}│{NC}  URL do Webhook para o Meta:")
        print(f"  {BOLD}{YELLOW}│{NC}  {BOLD}{GREEN}{webhook_url}{NC}")
        print(f"  {BOLD}{YELLOW}└───────────────────────────────────────────────────────────────────┘{NC}")
        print()
        print(f"  {BOLD}Como registrar no Meta for Developers (passo a passo):{NC}")
        print( "  1. Acesse: developers.facebook.com → Meu App → WhatsApp → Configuração")
        print(f"  2. Em {YELLOW}Callback URL{NC}, cole:")
        print(f"     {GREEN}{webhook_url}{NC}")
        print(f"  3. Em {YELLOW}Verify Token{NC}, cole o valor de {YELLOW}VERIFY_TOKEN{NC} do seu backend/.env")
        print(f"  4. Clique em {YELLOW}Verificar e Salvar{NC}.")
        print(f"  5. Assine os campos: {YELLOW}messages{NC} e {YELLOW}message_deliveries{NC}.")
        print()
        print(f"  {BOLD}{RED}ATENÇÃO:{NC} A URL do ngrok muda a cada restart do script.")
    else:
        print(f"  {YELLOW}URL ngrok:{NC} Não foi possível extrair automaticamente.")
        print(f"  Acesse {CYAN}http://localhost:{NGROK_DASHBOARD_PORT}{NC} para ver a URL pública.")

    print()
    print(f"  {BOLD}Logs em tempo real:{NC}")
    print(f"  ├─ FastAPI:  {CYAN}{tail_cmd}{NC}")
    print(f"  └─ ngrok:    {CYAN}{tail_cmd.replace('uvicorn', 'ngrok')}{NC}")
    print()
    print(f"  {BOLD}{RED}Pressione Ctrl+C para encerrar todos os processos e containers.{NC}")
    print()


# =============================================================================
# Cleanup — encerrado via Ctrl+C (SIGINT) ou SIGTERM
# =============================================================================
def cleanup(*_):
    print()
    log_section("Encerrando ambiente de desenvolvimento")

    for proc in reversed(_children):
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()

    log_info("Parando containers Docker (db, redis, chroma)...")
    subprocess.run(
        ["docker", "compose", "-f", str(COMPOSE_FILE), "stop", "db", "redis", "chroma"],
        capture_output=True,
    )
    log_ok("Containers parados. Ambiente encerrado com sucesso.")
    sys.exit(0)


# =============================================================================
# Entry point
# =============================================================================
def main():
    print()
    print(f"{BOLD}{BLUE}══════════════════════════════════════════════════════════════════{NC}")
    print(f"{BOLD}{BLUE}   Cadife Smart Travel  —  Iniciando Ambiente de Desenvolvimento  {NC}")
    print(f"{BOLD}{BLUE}══════════════════════════════════════════════════════════════════{NC}")

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    if hasattr(signal, "SIGHUP"):  # não existe no Windows
        signal.signal(signal.SIGHUP, cleanup)

    check_ram()
    check_dependencies()
    check_env_file()
    start_infrastructure()
    run_migrations()
    uvicorn_proc = start_api()
    start_ngrok()
    show_summary()

    # Bloqueia até o uvicorn sair; ao sair o trap Ctrl+C já chamou cleanup()
    uvicorn_proc.wait()


if __name__ == "__main__":
    main()
