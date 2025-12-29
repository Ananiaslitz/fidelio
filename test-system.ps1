# Fidelio Integration Test Script

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Fidelio Integration Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Step 1: Clean up
Write-Host "`nStep 1: Cleaning up..." -ForegroundColor Yellow
docker-compose down -v 2>$null
Write-Host "OK" -ForegroundColor Green

# Step 2: Start PostgreSQL
Write-Host "`nStep 2: Starting PostgreSQL..." -ForegroundColor Yellow
docker-compose up -d postgres
Start-Sleep -Seconds 5

# Wait for PostgreSQL
for ($i = 1; $i -le 20; $i++) {
    $result = docker exec fidelio-postgres pg_isready -U fidelio 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PostgreSQL ready!" -ForegroundColor Green
        break
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 1
}

# Step 3: Seed data
Write-Host "`nStep 3: Seeding test data..." -ForegroundColor Yellow
docker cp test-seed.sql fidelio-postgres:/tmp/seed.sql
docker exec fidelio-postgres psql -U fidelio -d fidelio -f /tmp/seed.sql 2>&1 | Out-Null
Write-Host "OK" -ForegroundColor Green

# Step 4: Build
Write-Host "`nStep 4: Building application..." -ForegroundColor Yellow
Push-Location backend
go build -o fidelio.exe main.go 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host "OK" -ForegroundColor Green

# Step 5: Create .env
@"
DATABASE_URL=postgresql://fidelio:fidelio_dev_password@localhost:5432/fidelio?sslmode=disable
SERVER_PORT=8080
SUPABASE_URL=https://wfjjfktyjwxyvwilccmg.supabase.co
SUPABASE_SERVICE_KEY=sb_publishable_KB9NS4m8TEZnWRecZGuMjw_Pg5bBrFC
WEBHOOK_SECRET=test_webhook_secret_12345
SHADOW_WALLET_TTL_HOURS=72
EXPIRATION_WORKER_INTERVAL_MINUTES=60
"@ | Out-File -FilePath "backend\.env" -Encoding UTF8

# Step 6: Start API
Write-Host "`nStep 6: Starting API..." -ForegroundColor Yellow
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
Write-Host "API Started (PID: $($proc.Id))" -ForegroundColor Green

# Run tests
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Running Functional Tests" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$passed = 0
$failed = 0

# Test 1
Write-Host "`nTest 1: Health Check" -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/health" | Out-Null
    Write-Host "PASSED" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED" -ForegroundColor Red
    $failed++
}

# Test 2-6: Shadow wallet transactions
Write-Host "`nTest 2-6: Shadow Wallet Flow (5 transactions)" -ForegroundColor Yellow
$txIds = @("TEST_001", "TEST_002", "TEST_003", "TEST_004", "TEST_005") 
$amounts = @(25.50, 30.00, 15.00, 20.00, 25.00)
for ($i = 0; $i -lt 5; $i++) {
    try {
        $body = @{
            phone          = "+5511987654321"
            transaction_id = $txIds[$i]
            amount         = $amounts[$i]
        } | ConvertTo-Json
        
        $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json"
        Write-Host "  TX$($i+1) PASSED - Balance: $($r.new_balance)" -ForegroundColor Green
        $passed++
    }
    catch {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        Write-Host "  TX$($i+1) FAILED: $body" -ForegroundColor Red
        $failed++
    }
}

# Test 7: New wallet
Write-Host "`nTest 7: New Shadow Wallet" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511999887766"
        transaction_id = "TEST_NEW_001"
        amount         = 50.00
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json" | Out-Null
    Write-Host "PASSED" -ForegroundColor Green
    $passed++
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $body = $reader.ReadToEnd()
    Write-Host "FAILED: $body" -ForegroundColor Red
    $failed++
}

# Test 8: Invalid key
Write-Host "`nTest 8: Invalid API Key" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511000000000"
        transaction_id = "INVALID"
        amount         = 10.00
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "invalid" } -Body $body -ContentType "application/json" | Out-Null
    Write-Host "FAILED - Should reject" -ForegroundColor Red
    $failed++
}
catch {
    Write-Host "PASSED - Correctly rejected" -ForegroundColor Green
    $passed++
}

# Test 9: Stats
Write-Host "`nTest 9: Stats Endpoint" -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/v1/stats" -Headers @{"X-API-Key" = "test_api_key_12345" } | Out-Null
    Write-Host "PASSED" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED" -ForegroundColor Red
    $failed++
}

# Webhook Helper Function
function Get-HmacSha256 {
    param(
        [string]$Message,
        [string]$Secret
    )
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Secret)
    $hash = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Message))
    return ([BitConverter]::ToString($hash) -replace '-').ToLower()
}

# Test 10: Registration with Shadow Wallet
Write-Host "`nTest 10: Register User (With Shadow Wallet)" -ForegroundColor Yellow
try {
    # Valid User ID (must be UUID)
    $userId = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    # Using the phone from Test 7 (+5511999887766) which should have a shadow wallet
    $payload = @{
        type   = "INSERT"
        table  = "users"
        record = @{
            id    = $userId
            phone = "+5511999887766"
        }
    } | ConvertTo-Json -Compress

    $signature = Get-HmacSha256 -Message $payload -Secret "test_webhook_secret_12345"

    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/webhook/user-created" `
        -Method POST `
        -Headers @{"X-Webhook-Signature" = $signature } `
        -Body $payload `
        -ContentType "application/json"

    if ($response.success -eq $true -and $response.message -like "*converted successfully*") {
        Write-Host "PASSED - Shadow wallet converted" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED - Unexpected response: $($response | ConvertTo-Json)" -ForegroundColor Red
        $failed++
    }
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $body = $reader.ReadToEnd()
    Write-Host "FAILED: $body" -ForegroundColor Red
    $failed++
}

# Test 11: Registration without Shadow Wallet
Write-Host "`nTest 11: Register User (No Shadow Wallet)" -ForegroundColor Yellow
try {
    # New User ID
    $userId = "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380b22"
    # New phone number
    $payload = @{
        type   = "INSERT"
        table  = "users"
        record = @{
            id    = $userId
            phone = "+5511555554444"
        }
    } | ConvertTo-Json -Compress

    $signature = Get-HmacSha256 -Message $payload -Secret "test_webhook_secret_12345"

    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/webhook/user-created" `
        -Method POST `
        -Headers @{"X-Webhook-Signature" = $signature } `
        -Body $payload `
        -ContentType "application/json"

    # Depending on implementation, it might report success even if no shadow wallet found,
    # or a specific message. Based on code review: "conversion failed" is only if error, 
    # but ConvertShadowToRealWallet returns nil if no shadows found.
    # The handler returns success=true.
    
    if ($response.success -eq $true) {
        Write-Host "PASSED - Registration succeeded (no conversion needed)" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED - Unexpected response: $($response | ConvertTo-Json)" -ForegroundColor Red
        $failed++
    }
}
catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $body = $reader.ReadToEnd()
    Write-Host "FAILED: $body" -ForegroundColor Red
    $failed++
}

# Database check
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Database Verification" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$shadows = docker exec fidelio-postgres psql -U fidelio -d fidelio -t -c "SELECT COUNT(*) FROM shadow_balances WHERE converted_at IS NULL;"
$txCount = docker exec fidelio-postgres psql -U fidelio -d fidelio -t -c "SELECT COUNT(*) FROM transactions;"

Write-Host "Active Shadow Balances: $($shadows.Trim())" -ForegroundColor Cyan
Write-Host "Total Transactions: $($txCount.Trim())" -ForegroundColor Cyan

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Yellow
Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
Write-Host "OK" -ForegroundColor Green

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" }else { "Green" })
$rate = [math]::Round(($passed / ($passed + $failed)) * 100, 1)
Write-Host "Success Rate: $rate%" -ForegroundColor Cyan

if ($failed -eq 0) {
    Write-Host "`nALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nSOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
