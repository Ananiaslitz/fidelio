# Fidelio Cashback Test Script
$ErrorActionPreference = "Stop"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Fidelio Cashback Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Step 1: Cleaning up DB (Optional, but good for isolation)
# For speed, we will just delete existing data and re-seed
Write-Host "`nStep 1: Reseeding Database..." -ForegroundColor Yellow
docker cp .\test-cashback-seed.sql fidelio-postgres:/tmp/cashback-seed.sql
docker exec -e PGPASSWORD=fidelio_dev_password fidelio-postgres psql -U fidelio -d fidelio -c "TRUNCATE transactions, wallets, shadow_balances, campaigns, merchants CASCADE;"
docker exec -e PGPASSWORD=fidelio_dev_password fidelio-postgres psql -U fidelio -d fidelio -f /tmp/cashback-seed.sql
Write-Host "OK" -ForegroundColor Green

# Step 2: Start API
Write-Host "`nStep 2: Starting API..." -ForegroundColor Yellow
$env:DATABASE_URL = "postgresql://fidelio:fidelio_dev_password@localhost:5432/fidelio?sslmode=disable"
$env:SERVER_PORT = "8080"
$env:SUPABASE_URL = "https://wfjjfktyjwxyvwilccmg.supabase.co"
$env:SUPABASE_SERVICE_KEY = "sb_publishable_KB9NS4m8TEZnWRecZGuMjw_Pg5bBrFC"
$env:WEBHOOK_SECRET = "test_webhook_secret_12345"
$env:SHADOW_WALLET_TTL_HOURS = "72"
$env:EXPIRATION_WORKER_INTERVAL_MINUTES = "60"
$env:MOCK_SUPABASE = "true"

Push-Location backend
$proc = Start-Process -FilePath ".\fidelio.exe" -PassThru -NoNewWindow
Pop-Location
Start-Sleep -Seconds 3

if ($proc.HasExited) {
    Write-Host "API failed to start or exited immediately." -ForegroundColor Red
    exit 1
}
Write-Host "API Started (PID: $($proc.Id))" -ForegroundColor Green

$passed = 0
$failed = 0
$apiKey = "cashback_key_123"

Write-Host "`nTest 1: Purchase below minimum (R$ 10.00, Min: R$ 20.00)" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511988887777"
        transaction_id = "CB_TEST_001"
        amount         = 10.00
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = $apiKey } -Body $body -ContentType "application/json"
    
    # Expected: 0 cashback because < 20.00
    $rewardAmount = 0
    if ($response.reward) { $rewardAmount = $response.reward.amount }

    if ($rewardAmount -eq 0 -and $response.new_balance -eq 0) {
        Write-Host "PASSED - Correctly ignored (amount < min)" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED - Expected 0 cashback, got $rewardAmount" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $failed++
}

# Test 2: Valid Purchase (R$ 100.00, 10% Cashback)
Write-Host "`nTest 2: Valid Purchase (R$ 100.00, 10% Cashback)" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511988887777"
        transaction_id = "CB_TEST_002"
        amount         = 100.00
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = $apiKey } -Body $body -ContentType "application/json"
    
    # Expected: 10.00 cashback
    if ($response.reward.amount -eq 10.00 -and $response.new_balance -eq 10.00) {
        Write-Host "PASSED - Earned R$ 10.00" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED - Expected 10.00, got $($response.reward.amount)" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $failed++
}

# Test 3: Purchase hitting Cap (R$ 600.00 -> 10% = 60.00, but Max is 50.00)
Write-Host "`nTest 3: Purchase hitting Cap (R$ 600.00, Max Cap R$ 50.00)" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511988887777"
        transaction_id = "CB_TEST_003"
        amount         = 600.00
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = $apiKey } -Body $body -ContentType "application/json"
    
    # Expected: 50.00 cashback (capped)
    # Total Balance: 0 (from test 1) + 10 (test 2) + 50 (test 3) = 60.00
    if ($response.reward.amount -eq 50.00 -and $response.new_balance -eq 60.00) {
        Write-Host "PASSED - Capped at R$ 50.00" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED - Expected 50.00, got $($response.reward.amount)" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "FAILED: $_" -ForegroundColor Red
    $failed++
}

Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "Passed: $passed"
Write-Host "Failed: $failed"

if ($failed -gt 0) {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "ALL BACKEND TESTS PASSED!" -ForegroundColor Green
}

# Cleanup
if ($true) {
    if ($proc -and -not $proc.HasExited) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Host "API Process Terminated" -ForegroundColor Gray
    }
}
