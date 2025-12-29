# Script para Configurar Chave SSH do GitHub Actions
$VPS_IP = "72.61.41.92"
$VPS_USER = "root"
$KEY_NAME = "deploy_key"

# 1. Gerar Chave (se não existir)
if (-not (Test-Path "$KEY_NAME")) {
    Write-Host "Gerando nova chave SSH ($KEY_NAME)..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b 4096 -f $KEY_NAME -N "" -q
}
else {
    Write-Host "Chave $KEY_NAME ja existe. Usando a existente." -ForegroundColor Yellow
}

# 2. Enviar Pública para VPS
Write-Host "Instalando chave publica na VPS..." -ForegroundColor Cyan
if (Test-Path "$KEY_NAME.pub") {
    $pubKey = Get-Content "$KEY_NAME.pub" -Raw
    $pubKey = $pubKey.Trim()
    
    # Comando para adicionar ao authorized_keys (seguro)
    $cmd = "mkdir -p ~/.ssh && echo '$pubKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'Chave instalada com sucesso!'"
    
    ssh ${VPS_USER}@${VPS_IP} $cmd

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Chave configurada na VPS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "ACAO NECESSARIA:" -ForegroundColor Yellow
        Write-Host "Copie o conteudo abaixo (TUDO) e cole no GitHub Secret VPS_SSH_KEY:"
        Write-Host "=================================================================" -ForegroundColor Gray
        Get-Content "$KEY_NAME"
        Write-Host "=================================================================" -ForegroundColor Gray
    }
    else {
        Write-Host "Falha ao instalar chave na VPS." -ForegroundColor Red
    }
}
else {
    Write-Host "Erro: Arquivo $KEY_NAME.pub nao encontrado!" -ForegroundColor Red
}
