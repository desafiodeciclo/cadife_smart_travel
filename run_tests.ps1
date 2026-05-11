# ============================================================
# run_tests.ps1 — Suite de Testes: Novas Features
# Cadife Smart Travel | feat/leads-api-filtering-and-interactions
# ============================================================
# Execute com: .\run_tests.ps1
# ============================================================

$backendDir = "$PSScriptRoot\backend"
Set-Location $backendDir

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CADIFE SMART TRAVEL — Suite de Testes" -ForegroundColor Cyan
Write-Host "  feat/leads-api-filtering-and-interactions" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ----------------------------------------------------------
# BLOCO 1: Testes Unitários/Integração (sem DB)
# ----------------------------------------------------------
Write-Host "[ BLOCO 1 ] Testes de Rotas: Leads (Filtros, Soft Delete, Sub-recursos, PII)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_routes/test_leads_filters.py -v --tb=short
Write-Host ""

Write-Host "[ BLOCO 2 ] Testes de Rotas: Propostas (CRUD, RBAC, State Machine)" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_routes/test_propostas.py -v --tb=short
Write-Host ""

# ----------------------------------------------------------
# BLOCO 3: Todos os testes da pasta test_routes
# ----------------------------------------------------------
Write-Host "[ BLOCO 3 ] Todos os testes de Rotas" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/test_routes/ -v --tb=short
Write-Host ""

# ----------------------------------------------------------
# BLOCO 4: Suite completa (excluindo infra que precisa de DB)
# ----------------------------------------------------------
Write-Host "[ BLOCO 4 ] Suite Completa de Testes" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
python -m pytest tests/ -v --tb=short --ignore=tests/test_infrastructure
Write-Host ""

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  TESTES CONCLUÍDOS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
