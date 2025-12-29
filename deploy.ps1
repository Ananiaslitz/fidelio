# Fidelio Production Deployment Script (PowerShell)
# Para usar no Windows antes de enviar para VPS

Write-Host "🚀 Fidelio Production Deployment (Windows)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se .env existe
if (-not (Test-Path ".env")) {
    Write-Host "❌ Erro: Arquivo .env não encontrado!" -ForegroundColor Red
    Write-Host "Por favor, configure o arquivo .env com suas credenciais." -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Arquivo .env encontrado" -ForegroundColor Green

# Verificar se Docker está rodando
try {
    docker ps | Out-Null
    Write-Host "✓ Docker está rodando" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erro: Docker não está rodando!" -ForegroundColor Red
    Write-Host "Por favor, inicie o Docker Desktop." -ForegroundColor Yellow
    exit 1
}

# Verificar se docker-compose está disponível
try {
    docker-compose --version | Out-Null
    Write-Host "✓ Docker Compose está instalado" -ForegroundColor Green
}
catch {
    Write-Host "❌ Erro: Docker Compose não encontrado!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Construindo imagens Docker..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao construir imagens!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Imagens construídas com sucesso" -ForegroundColor Green
Write-Host ""

Write-Host "Parando containers existentes..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml down

Write-Host ""
Write-Host "Iniciando containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao iniciar containers!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Containers iniciados" -ForegroundColor Green
Write-Host ""

# Aguardar serviços ficarem prontos
Write-Host "Aguardando serviços ficarem prontos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar status
Write-Host ""
Write-Host "Status dos Containers:" -ForegroundColor Cyan
docker-compose -f docker-compose.production.yml ps

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✓ Deployment concluído!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Sua aplicação está rodando em:" -ForegroundColor Cyan
Write-Host "  - Web Portal: http://localhost" -ForegroundColor White
Write-Host "  - API: http://localhost/api" -ForegroundColor White
Write-Host ""
Write-Host "Comandos úteis:" -ForegroundColor Cyan
Write-Host "  - Ver logs: docker-compose -f docker-compose.production.yml logs -f" -ForegroundColor White
Write-Host "  - Parar: docker-compose -f docker-compose.production.yml down" -ForegroundColor White
Write-Host "  - Restart: docker-compose -f docker-compose.production.yml restart" -ForegroundColor White
Write-Host ""

# Perguntar se quer ver logs
$response = Read-Host "Deseja ver os logs agora? (s/n)"
if ($response -eq "s" -or $response -eq "S") {
    docker-compose -f docker-compose.production.yml logs -f
}
