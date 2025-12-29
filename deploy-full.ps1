# Script Completo de Deploy via ZIP (Versão Final CMD)

$VPS_IP = "72.61.41.92"
$VPS_USER = "root"
$REMOTE_DIR = "/opt/backly"

# Garantir que estamos no diretório onde o script está
if ($PSScriptRoot) {
    Set-Location $PSScriptRoot
}

Write-Host "📦 Preparando pacote de deploy..." -ForegroundColor Cyan

$zipFile = "deploy-package.zip"

# Remover zip antigo
if (Test-Path $zipFile) { Remove-Item $zipFile }

# Criar lista de inclusão
$include = @(
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

# Zipar arquivos
Compress-Archive -Path $include -DestinationPath $zipFile -Force

if (-not (Test-Path $zipFile)) {
    Write-Host "❌ Erro: Falha ao criar zip!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Pacote criado: $zipFile" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Configurando VPS ($VPS_IP)..." -ForegroundColor Cyan

# Criar diretório remoto
cmd /c "ssh ${VPS_USER}@${VPS_IP} mkdir -p $REMOTE_DIR"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao conectar via SSH!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Diretório verificado" -ForegroundColor Green

Write-Host "📤 Enviando arquivo..." -ForegroundColor Cyan

# Usando CMD /C para evitar problemas de parsing do PowerShell com SCP
$scpCmd = "scp $zipFile ${VPS_USER}@${VPS_IP}:${REMOTE_DIR}/$zipFile"
Write-Host "Executando: $scpCmd" -ForegroundColor DarkGray

cmd /c $scpCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro no upload!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Upload concluído!" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Executando deploy remoto..." -ForegroundColor Cyan

# Comando remoto
$remoteCmd = "apt install -y unzip && cd $REMOTE_DIR && unzip -o $zipFile && cp .env .env.production && chmod +x deploy.sh && ./deploy.sh"

# Usando CMD /C também para o SSH final para consistência
cmd /c "ssh ${VPS_USER}@${VPS_IP} ""$remoteCmd"""

Write-Host ""
Write-Host "✨ Processo finalizado!" -ForegroundColor Green
