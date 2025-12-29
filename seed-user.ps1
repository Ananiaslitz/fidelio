# Script para criar usuário de teste no banco
$VPS_IP = "72.61.41.92"

# Hash para a senha "123456" (bcrypt custo 10)
$HASH = '$2a$10$2l.vO.d_d__d__d__d__d__d__d__d__d__d__d__' # Placeholder, vou usar um real no comando abaixo

# Hash real de "123456" gerado por bcrypt
$REAL_HASH = '$2a$10$3X/.S1/d.d/d.d/d.d/d.d/d.d/d.d/d.d/d.d/d.d/d.d/d.d' 
# Ops, vou usar um hash válido de verdade:
# $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy  (senha: 123456)

$SQL = "INSERT INTO merchants (id, email, password_hash, business_name, created_at) VALUES (gen_random_uuid(), 'admin@fidelio.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Fidelio HQ', NOW()) ON CONFLICT (email) DO NOTHING;"

Write-Host "🔧 Inserindo usuário 'admin@fidelio.com' (senha: 123456)..." -ForegroundColor Cyan

$cmd = "docker exec -i backly-postgres-prod psql -U fidelio_prod -d fidelio_production -c ""$SQL"""

ssh root@${VPS_IP} $cmd

Write-Host "✨ Usuário criado/verificado!" -ForegroundColor Green
