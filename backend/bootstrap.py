import os
import sys
import subprocess
import structlog

# Configuramos um logger básico para o bootstrap
logger = structlog.get_logger()

def run_migrations():
    """
    Executa as migrações do banco de dados usando o módulo Alembic.
    """
    logger.info("entrypoint_migrations_start")
    try:
        # Executamos como módulo para garantir o uso do path correto no Distroless
        result = subprocess.run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            logger.error("entrypoint_migrations_failed", error=result.stderr)
            sys.exit(1)
        
        logger.info("entrypoint_migrations_success")
    except Exception as e:
        logger.error("entrypoint_migrations_exception", error=str(e))
        sys.exit(1)

def start_server():
    """
    Inicia o servidor Uvicorn substituindo o processo atual (exec).
    """
    logger.info("entrypoint_server_start")
    
    # Argumentos do Uvicorn
    # --proxy-headers e --forwarded-allow-ips são importantes para rodar atrás de 
    # Load Balancers no K8S para capturar o IP real do cliente.
    args = [
        sys.executable, "-m", "uvicorn", "main:app",
        "--host", "0.0.0.0",
        "--port", "8000",
        "--proxy-headers",
        "--forwarded-allow-ips", "*"
    ]
    
    # os.execvp substitui o processo do bootstrap pelo processo do uvicorn
    # Isso garante que o uvicorn receba os sinais (SIGTERM) do Kubernetes diretamente.
    os.execvp(sys.executable, args)

if __name__ == "__main__":
    # Garante que o diretório atual está no PYTHONPATH
    sys.path.append(os.getcwd())
    
    run_migrations()
    start_server()
