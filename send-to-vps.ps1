# Script para enviar apenas arquivos necessários para VPS
# Exclui node_modules, dist, .git, etc.

$VPS_IP = "72.61.41.92"
$VPS_PATH = "/opt/fidelio"

Write-Host "📦 Enviando arquivos para VPS..." -ForegroundColor Cyan

# Lista de arquivos/pastas essenciais
$filesToSend = @(
    "backend",
    "web-portal",
    "migrations",
    "nginx",
    "docker-compose.production.yml",
    "Dockerfile",
    ".env",
    "deploy.sh",
    "setup-ssl.sh",
    "Makefile"
)

foreach ($item in $filesToSend) {
    if (Test-Path $item) {
        Write-Host "Enviando: $item" -ForegroundColor Yellow
        scp -r $item "root@${VPS_IP}:${VPS_PATH}/"
    }
}

Write-Host "✓ Arquivos enviados!" -ForegroundColor Green
Write-Host ""
Write-Host "Próximo passo:" -ForegroundColor Cyan
Write-Host "ssh root@$VPS_IP" -ForegroundColor White
Write-Host "cd $VPS_PATH && chmod +x deploy.sh && ./deploy.sh" -ForegroundColor White
