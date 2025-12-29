# Script para restaurar o banco de dados na VPS (Stream Direto)

$VPS_IP = "72.61.41.92"
$VPS_USER = "root"
$LOCAL_FILE = "deploy-schema.sql"

if (-not (Test-Path $LOCAL_FILE)) {
    Write-Host "❌ Erro: Arquivo $LOCAL_FILE não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host "� Aplicando schema no banco de dados..." -ForegroundColor Cyan

# Ler conteúdo e passar via pipe para o SSH -> Docker -> PSQL
# Nota: Usamos Get-Content -Raw para ler tudo como string única
# E passamos para o plink ou ssh se disponível.
# No PowerShell, o pipe para SSH pode ser chato com encoding.
# Vamos usar uma abordagem segura: cat local | ssh remoto

type $LOCAL_FILE | ssh ${VPS_USER}@${VPS_IP} "docker exec -i backly-postgres-prod psql -U fidelio_prod -d fidelio_production"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✨ Banco de dados restaurado com sucesso!" -ForegroundColor Green
}
else {
    Write-Host "❌ Erro ao aplicar schema." -ForegroundColor Red
}
