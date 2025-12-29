# Script para Expor Banco de Dados (Forçado)
$VPS_IP = "72.61.41.92"
$VPS_USER = "root"

Write-Host "📤 Enviando config atualizada..." -ForegroundColor Cyan
scp docker-compose.production.yml ${VPS_USER}@${VPS_IP}:/opt/fidelio/

Write-Host "🔧 Forçando recriação do container..." -ForegroundColor Cyan

# 1. Parar e remover container antigo
# 2. Subir novamente (vai pegar a nova porta)
# 3. Verificar se a porta está ouvindo
$cmd = "cd /opt/backly && docker-compose -f docker-compose.production.yml stop postgres && docker-compose -f docker-compose.production.yml rm -f postgres && docker-compose -f docker-compose.production.yml up -d postgres && ufw allow 5432/tcp && echo 'Verificando porta...' && netstat -tulpn | grep 5432"

ssh ${VPS_USER}@${VPS_IP} $cmd

Write-Host "✨ Processo concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "Tente conectar agora:"
Write-Host "Host: 72.61.41.92"
Write-Host "Port: 5432"
Write-Host "User: fidelio_prod"
Write-Host "Pass: Fidelio@Prod2025!Strong"
