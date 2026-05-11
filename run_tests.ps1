# ============================================================
# run_tests.ps1 — Suite de Testes: OWASP Security Hardening
# Cadife Smart Travel | feat/security-owasp-assessment
# ============================================================
# Execute com: .\run_tests.ps1
# ============================================================

$backendDir = "$PSScriptRoot\backend"
Set-Location $backendDir

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CADIFE SMART TRAVEL — Suite de Testes de Seguranca" -ForegroundColor Cyan
Write-Host "  feat/security-owasp-assessment" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# BLOCO 1: Testes de Seguranca (PII, RBAC, Headers)
# ----------------------------------------------------------
Write-Host "[ BLOCO 1 ] Testes de Seguranca (PII, RBAC, Headers)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_security/test_security_observability.py -v --tb=short
Write-Host ""

# ----------------------------------------------------------
# BLOCO 2: Testes de Rotas (CRUD, RBAC, State Machine)
# ----------------------------------------------------------
Write-Host "[ BLOCO 2 ] Testes de Rotas (Offers, Propostas, Auth, Suitcase)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_routes/ -v --tb=short
Write-Host ""

# ----------------------------------------------------------
# BLOCO 3: Testes de Integracao (Documentos, Diario)
# ----------------------------------------------------------
Write-Host "[ BLOCO 3 ] Testes de Integracao (Documentos, Diario)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_documents_qa.py tests/integration/test_diary_integration.py -v --tb=short
Write-Host ""

# ----------------------------------------------------------
# BLOCO 4: Suite completa (excluindo infra que precisa de DB externo)
# ----------------------------------------------------------
Write-Host "[ BLOCO 4 ] Suite Completa de Testes" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/ -v --tb=short --ignore=tests/test_infrastructure
Write-Host ""

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  TESTES CONCLUIDOS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
