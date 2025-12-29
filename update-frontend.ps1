# Script para atualizar apenas o Frontend e rodar deploy
$VPS_IP = "72.61.41.92"

Write-Host "📦 Zipando web-portal..." -ForegroundColor Cyan
if (Test-Path web-portal.zip) { Remove-Item web-portal.zip }
Compress-Archive -Path web-portal -DestinationPath web-portal.zip -Force

Write-Host "🚀 Enviando para VPS..." -ForegroundColor Cyan
scp web-portal.zip root@${VPS_IP}:/opt/backly/

Write-Host "🔧 Atualizando e Reconstruindo na VPS..." -ForegroundColor Cyan
$cmd = "cd /opt/backly && unzip -o web-portal.zip && docker-compose -f docker-compose.production.yml up -d --build web-portal"
ssh root@${VPS_IP} $cmd

Write-Host "✨ Frontend atualizado!" -ForegroundColor Green
