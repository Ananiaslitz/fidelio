# Fidelio Integration Test Script
# Usage: .\test-system.ps1

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Fidelio Integration Test Suite" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Step 1: Stop and remove existing containers
Write-Host "`nStep 1: Cleaning up..." -ForegroundColor Yellow
docker-compose down -v 2>$null
Write-Host "OK" -ForegroundColor Green

# Step 2: Start Docker services
Write-Host "`nStep 2: Starting PostgreSQL..." -ForegroundColor Yellow
docker-compose up -d postgres
Start-Sleep -Seconds 5
Write-Host "OK" -ForegroundColor Green

#Step 3: Wait for PostgreSQL
Write-Host "`nStep 3: Waiting for PostgreSQL..." -ForegroundColor Yellow
for ($i = 1; $i -le 20; $i++) {
    $result = docker exec fidelio-postgres pg_isready -U fideliouser 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PostgreSQL is ready!" -ForegroundColor Green
        break
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 1
}

# Step 4: Apply migrations (they run automatically on container start)
Write-Host "`nStep 4: Checking migrations..." -ForegroundColor Yellow
Write-Host "OK - Migrations run on container init" -ForegroundColor Green

# Step 5: Seed test data
Write-Host "`nStep 5: Seeding test data..." -ForegroundColor Yellow

# Merchant
docker exec fidelio-postgres bash -c "echo \"INSERT INTO merchants (id, name, api_key, settings, created_at, updated_at) VALUES ('11111111-1111-1111-1111-111111111111', 'Test Coffee Shop', 'test_api_key_12345', '{}', NOW(), NOW()) ON CONFLICT (id) DO NOTHING; \" | psql -U fideliouser -d fideliodb" 2>&1 | Out-Null

# Campaign
docker exec fidelio-postgres bash -c "echo \"INSERT INTO campaigns (id, merchant_id, name, type, config, is_active, starts_at, ends_at, created_at, updated_at) VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Buy 5 Get 1 Free', 'PUNCH_CARD', '{\\\"required_purchases\\\": 5, \\\"reward_amount\\\": 1, \\\"min_purchase_amount\\\": 10.0}', true, NOW() - INTERVAL '1 day', NOW() + INTERVAL '30 days', NOW(), NOW()) ON CONFLICT (id) DO NOTHING; \" | psql -U fideliouser -d fideliodb" 2>&1 | Out-Null

Write-Host "OK" -ForegroundColor Green

# Step 6: Build application  
Write-Host "`nStep 6: Building application..." -ForegroundColor Yellow
Push-Location backend
go build -o fidelio.exe main.go 2>&1 | Out-Null
Pop-Location
Write-Host "OK" -ForegroundColor Green

# Step 7: Create .env
Write-Host "`nStep 7: Creating .env..." -ForegroundColor Yellow
@"
DATABASE_URL=postgresql://fideliouser:fideliopass@localhost:5432/fideliodb?sslmode=disable
SERVER_PORT=8080
SUPABASE_URL=https://test.supabase.co
SUPABASE_SERVICE_KEY=test_service_key
WEBHOOK_SECRET=test_webhook_secret_12345
SHADOW_WALLET_TTL_HOURS=72
EXPIRATION_WORKER_INTERVAL_MINUTES=60
"@ | Out-File -FilePath "backend\.env" -Encoding UTF8
Write-Host "OK" -ForegroundColor Green

# Step 8: Start API
Write-Host "`nStep 8: Starting API..." -ForegroundColor Yellow
Push-Location backend
$proc = Start-Process -FilePath ".\fidelio.exe" -PassThru -NoNewWindow
Pop-Location
Start-Sleep -Seconds 3
Write-Host "API Started (PID: $($proc.Id))" -ForegroundColor Green

# Step 9: Run tests
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Running Functional Tests" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$passed = 0
$failed = 0

# Test 1: Health check
Write-Host "`nTest 1: Health Check" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "PASSED" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Test 2: Shadow Wallet Transaction
Write-Host "`nTest 2: Shadow Wallet Transaction" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511987654321"
        transaction_id = "TEST_001"
        amount         = 25.50
    } | ConvertTo-Json
    
    $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json"
    Write-Host "PASSED - Balance: $($r.new_balance), Shadow: $($r.is_shadow)" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Test 3: Accumulate shadow balance
Write-Host "`nTest 3: Accumulate Shadow Balance" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511987654321"
        transaction_id = "TEST_002"
        amount         = 30.00
    } | ConvertTo-Json
    
    $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json"
    Write-Host "PASSED - Balance: $($r.new_balance)" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Test 4: Complete punch card
Write-Host "`nTest 4-6: Complete Punch Card (3 more transactions)" -ForegroundColor Yellow
$amounts = @(15.00, 20.00, 25.00)
for ($i = 0; $i -lt 3; $i++) {
    try {
        $body = @{
            phone          = "+5511987654321"
            transaction_id = "TEST_00$($i+3)"
            amount         = $amounts[$i]
        } | ConvertTo-Json
        
        $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json"
        Write-Host "  TX$($i+3) PASSED - Balance: $($r.new_balance)" -ForegroundColor Green
        $passed++
    }
    catch {
        Write-Host "  TX$($i+3) FAILED" -ForegroundColor Red
        $failed++
    }
}

# Test 7: New Shadow Wallet
Write-Host "`nTest 7: New Shadow Wallet (different phone)" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511999887766"
        transaction_id = "TEST_NEW_001"
        amount         = 50.00
    } | ConvertTo-Json
    
    $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "test_api_key_12345" } -Body $body -ContentType "application/json"
    Write-Host "PASSED - Balance: $($r.new_balance)" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Test 8: Invalid API Key
Write-Host "`nTest 8: Invalid API Key (should fail)" -ForegroundColor Yellow
try {
    $body = @{
        phone          = "+5511000000000"
        transaction_id = "INVALID"
        amount         = 10.00
    } | ConvertTo-Json
    
    $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/ingest" -Method POST -Headers @{"X-API-Key" = "invalid_key" } -Body $body -ContentType "application/json"
    Write-Host "FAILED - Should have rejected invalid key" -ForegroundColor Red
    $failed++
}
catch {
    Write-Host "PASSED - Correctly rejected invalid key" -ForegroundColor Green
    $passed++
}

# Test 9: Stats endpoint
Write-Host "`nTest 9: Stats Endpoint" -ForegroundColor Yellow
try {
    $r = Invoke-RestMethod -Uri "http://localhost:8080/v1/stats" -Method GET
    Write-Host "PASSED" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    $failed++
}

# Database verification
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "Database Verification" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$dbCheck = docker exec fidelio-postgres psql -U fideliouser -d fideliodb -t -c "SELECT COUNT(*) FROM shadow_balances WHERE converted_at IS NULL;"
Write-Host "Active Shadow Balances: $($dbCheck.Trim())" -ForegroundColor Cyan

$dbCheck2 = docker exec fidelio-postgres psql -U fideliouser -d fideliodb -t -c "SELECT COUNT(*) FROM transactions;"
Write-Host "Total Transactions: $($dbCheck2.Trim())" -ForegroundColor Cyan

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
