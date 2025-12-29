$env:DATABASE_URL = "postgresql://fidelio:fidelio_dev_password@localhost:5432/fidelio?sslmode=disable"
$env:SERVER_PORT = "8080"
$env:SUPABASE_URL = "https://wfjjfktyjwxyvwilccmg.supabase.co"
$env:SUPABASE_SERVICE_KEY = "sb_publishable_KB9NS4m8TEZnWRecZGuMjw_Pg5bBrFC"
$env:WEBHOOK_SECRET = "test_webhook_secret_12345"
$env:SHADOW_WALLET_TTL_HOURS = "72"
$env:EXPIRATION_WORKER_INTERVAL_MINUTES = "60"
$env:RESEND_API_KEY = "re_hvbCSUSB_FfVtvPnqyv6xvFRYGPUmJTXr"

Write-Host "✅ Variáveis configuradas!"
Write-Host "🚀 Iniciando backend..."

go run main.go
