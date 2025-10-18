# ==============================================================================
# 🧪 CONCURRENT LOAD TEST - Bleen App
# ==============================================================================
# Test 20 users đồng thời và 1 account gọi API 10 lần
# ==============================================================================

param(
    [string]$ApiBaseUrl = "https://bleen-app-534422182125.asia-southeast1.run.app/api",
    [int]$NumConcurrentUsers = 20,
    [int]$NumSequentialCalls = 10
)

# Cấu hình
$LogDir = ".\concurrent-test-logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Tạo thư mục logs
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# ==============================================================================
# Hàm tiện ích
# ==============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# ==============================================================================
# Test 1: 20 users truy cập đồng thời (Health Check)
# ==============================================================================

function Test-ConcurrentUsers {
    Write-Header "TEST 1: $NumConcurrentUsers CONCURRENT USERS"
    
    $logFile = "$LogDir\concurrent_users_$Timestamp.log"
    $success = 0
    $failed = 0
    $totalTime = 0
    $times = @()
    
    "Starting concurrent users test..." | Out-File $logFile
    "Timestamp: $(Get-Date)" | Out-File $logFile -Append
    "----------------------------------------" | Out-File $logFile -Append
    
    Write-Info "Testing $NumConcurrentUsers users accessing simultaneously..."
    
    # Tạo jobs cho concurrent requests
    $jobs = @()
    
    for ($i = 1; $i -le $NumConcurrentUsers; $i++) {
        $job = Start-Job -ScriptBlock {
            param($UserNum, $Timestamp)
            
            $startTime = Get-Date
            
            try {
                # Test health endpoint
                $response = Invoke-WebRequest -Uri "https://bleen-app-534422182125.asia-southeast1.run.app/health" `
                    -Method GET `
                    -UseBasicParsing `
                    -TimeoutSec 10
                
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalSeconds
                
                return @{
                    Status = "SUCCESS"
                    UserNum = $UserNum
                    HttpCode = $response.StatusCode
                    Duration = $duration
                    Timestamp = $Timestamp
                }
            }
            catch {
                $endTime = Get-Date
                $duration = ($endTime - $startTime).TotalSeconds
                
                return @{
                    Status = "FAILED"
                    UserNum = $UserNum
                    HttpCode = $_.Exception.Response.StatusCode.Value__
                    Duration = $duration
                    Error = $_.Exception.Message
                    Timestamp = $Timestamp
                }
            }
        } -ArgumentList $i, $Timestamp
        
        $jobs += $job
    }
    
    # Chờ tất cả jobs hoàn thành
    Write-Info "Waiting for all concurrent requests to complete..."
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    # Xử lý kết quả
    foreach ($result in $results) {
        $logEntry = "User $($result.UserNum) | HTTP: $($result.HttpCode) | Time: $($result.Duration)s"
        $logEntry | Out-File $logFile -Append
        
        if ($result.Error) {
            "Error: $($result.Error)" | Out-File $logFile -Append
        }
        
        "----------------------------------------" | Out-File $logFile -Append
        
        if ($result.Status -eq "SUCCESS") {
            $success++
            $totalTime += $result.Duration
            $times += $result.Duration
            Write-Success "User $($result.UserNum): Success ($([math]::Round($result.Duration, 3))s)"
        }
        else {
            $failed++
            Write-Error "User $($result.UserNum): Failed (HTTP $($result.HttpCode))"
        }
    }
    
    # Tính toán thống kê
    $avgTime = if ($success -gt 0) { $totalTime / $success } else { 0 }
    $minTime = if ($times.Count -gt 0) { ($times | Measure-Object -Minimum).Minimum } else { 0 }
    $maxTime = if ($times.Count -gt 0) { ($times | Measure-Object -Maximum).Maximum } else { 0 }
    
    # Tổng kết
    Write-Host ""
    Write-Info "Concurrent Users Test Results:"
    Write-Host "  ✅ Successful: $success/$NumConcurrentUsers" -ForegroundColor Green
    Write-Host "  ❌ Failed: $failed/$NumConcurrentUsers" -ForegroundColor Red
    Write-Host "  ⏱️  Average time: $([math]::Round($avgTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📈 Min time: $([math]::Round($minTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📉 Max time: $([math]::Round($maxTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📝 Log file: $logFile" -ForegroundColor Cyan
}

# ==============================================================================
# Test 2: 1 account gọi API 10 lần liên tiếp
# ==============================================================================

function Test-SequentialAPI {
    Write-Header "TEST 2: SEQUENTIAL API CALLS ($NumSequentialCalls CALLS)"
    
    $logFile = "$LogDir\sequential_api_$Timestamp.log"
    $success = 0
    $failed = 0
    $totalTime = 0
    $times = @()
    
    "Starting sequential API test..." | Out-File $logFile
    "Timestamp: $(Get-Date)" | Out-File $logFile -Append
    "----------------------------------------" | Out-File $logFile -Append
    
    Write-Info "Calling API $NumSequentialCalls times sequentially..."
    
    for ($i = 1; $i -le $NumSequentialCalls; $i++) {
        $startTime = Get-Date
        
        try {
            # Test health endpoint
            $response = Invoke-WebRequest -Uri "https://bleen-app-534422182125.asia-southeast1.run.app/health" `
                -Method GET `
                -UseBasicParsing `
                -TimeoutSec 10
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            $totalTime += $duration
            $times += $duration
            
            "Call $i | HTTP: $($response.StatusCode) | Time: ${duration}s" | Out-File $logFile -Append
            "Response: $($response.Content)" | Out-File $logFile -Append
            "----------------------------------------" | Out-File $logFile -Append
            
            $success++
            Write-Success "Call $i`: Success ($([math]::Round($duration, 3))s)"
        }
        catch {
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            $totalTime += $duration
            
            $httpCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.Value__ } else { "ERROR" }
            
            "Call $i | HTTP: $httpCode | Time: ${duration}s" | Out-File $logFile -Append
            "Error: $($_.Exception.Message)" | Out-File $logFile -Append
            "----------------------------------------" | Out-File $logFile -Append
            
            $failed++
            Write-Error "Call $i`: Failed (HTTP $httpCode)"
        }
        
        # Delay nhỏ giữa các calls
        Start-Sleep -Milliseconds 100
    }
    
    # Tính toán thống kê
    $avgTime = if ($NumSequentialCalls -gt 0) { $totalTime / $NumSequentialCalls } else { 0 }
    $minTime = if ($times.Count -gt 0) { ($times | Measure-Object -Minimum).Minimum } else { 0 }
    $maxTime = if ($times.Count -gt 0) { ($times | Measure-Object -Maximum).Maximum } else { 0 }
    
    # Tổng kết
    Write-Host ""
    Write-Info "Sequential API Test Results:"
    Write-Host "  ✅ Successful: $success/$NumSequentialCalls" -ForegroundColor Green
    Write-Host "  ❌ Failed: $failed/$NumSequentialCalls" -ForegroundColor Red
    Write-Host "  ⏱️  Total time: $([math]::Round($totalTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📊 Average time: $([math]::Round($avgTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📈 Min time: $([math]::Round($minTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📉 Max time: $([math]::Round($maxTime, 3))s" -ForegroundColor Yellow
    Write-Host "  📝 Log file: $logFile" -ForegroundColor Cyan
}

# ==============================================================================
# Test 3: Mixed Load Test (Bonus)
# ==============================================================================

function Test-MixedLoad {
    Write-Header "TEST 3: MIXED LOAD TEST (BONUS)"
    Write-Info "5 concurrent users + 5 sequential calls"
    
    $logFile = "$LogDir\mixed_load_$Timestamp.log"
    $success = 0
    $failed = 0
    
    "Starting mixed load test..." | Out-File $logFile
    "Timestamp: $(Get-Date)" | Out-File $logFile -Append
    "----------------------------------------" | Out-File $logFile -Append
    
    # Concurrent requests
    Write-Info "Running 5 concurrent requests..."
    $jobs = @()
    
    for ($i = 1; $i -le 5; $i++) {
        $job = Start-Job -ScriptBlock {
            param($UserNum)
            
            try {
                $response = Invoke-WebRequest -Uri "https://bleen-app-534422182125.asia-southeast1.run.app/health" `
                    -Method GET `
                    -UseBasicParsing `
                    -TimeoutSec 10
                
                return @{ Type = "CONCURRENT"; Status = "SUCCESS"; UserNum = $UserNum }
            }
            catch {
                return @{ Type = "CONCURRENT"; Status = "FAILED"; UserNum = $UserNum }
            }
        } -ArgumentList $i
        
        $jobs += $job
    }
    
    # Sequential requests
    Write-Info "Running 5 sequential requests..."
    for ($i = 1; $i -le 5; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "https://bleen-app-534422182125.asia-southeast1.run.app/health" `
                -Method GET `
                -UseBasicParsing `
                -TimeoutSec 10
            
            $success++
            Write-Success "Sequential $i`: Success"
        }
        catch {
            $failed++
            Write-Error "Sequential $i`: Failed"
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    # Chờ concurrent jobs hoàn thành
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    $concurrentSuccess = ($results | Where-Object { $_.Status -eq "SUCCESS" }).Count
    $concurrentFailed = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
    
    Write-Host ""
    Write-Info "Mixed Load Test Results:"
    Write-Host "  🔄 Concurrent successful: $concurrentSuccess/5" -ForegroundColor Green
    Write-Host "  🔄 Concurrent failed: $concurrentFailed/5" -ForegroundColor Red
    Write-Host "  📝 Sequential successful: $success/5" -ForegroundColor Green
    Write-Host "  📝 Sequential failed: $failed/5" -ForegroundColor Red
    Write-Host "  📝 Log file: $logFile" -ForegroundColor Cyan
}

# ==============================================================================
# Main execution
# ==============================================================================

function Main {
    Clear-Host
    Write-Header "🧪 CONCURRENT LOAD TEST - Bleen App"
    
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  🌐 API URL: $ApiBaseUrl"
    Write-Host "  👥 Concurrent Users: $NumConcurrentUsers"
    Write-Host "  🔄 Sequential Calls: $NumSequentialCalls"
    Write-Host "  📁 Log Directory: $LogDir"
    Write-Host ""
    
    # Chạy các tests
    Write-Host ""
    Read-Host "Press ENTER to start load testing"
    
    $startTotal = Get-Date
    
    # Test 1: 20 concurrent users
    Test-ConcurrentUsers
    Start-Sleep -Seconds 2
    
    # Test 2: 10 sequential API calls
    Test-SequentialAPI
    Start-Sleep -Seconds 2
    
    # Test 3: Mixed load (optional)
    Write-Host ""
    $runMixed = Read-Host "Run mixed load test? (y/n)"
    if ($runMixed -eq "y") {
        Test-MixedLoad
    }
    
    $endTotal = Get-Date
    $totalDuration = ($endTotal - $startTotal).TotalSeconds
    
    # Tổng kết cuối cùng
    Write-Header "🎉 ALL TESTS COMPLETED"
    Write-Host "Total execution time: $([math]::Round($totalDuration, 2))s" -ForegroundColor Yellow
    Write-Host "All logs saved to: $LogDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Success "Load testing finished successfully!"
}

# Chạy script
Main



