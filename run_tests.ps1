

# Configuration
$LogDir = "test_logs"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$LogDir\test_results_$Timestamp.log"
$ErrorActionPreference = "Continue"

# Create log directory if not exists
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Helper function for logging
function Write-Log {
    param([string]$Message, [string]$Type="INFO")
    $Time = Get-Date -Format "HH:mm:ss"
    $LogEntry = "[$Time] [$Type] $Message"
    $Color = "Cyan"
    if ($Type -eq "ERROR") { $Color = "Red" }
    Write-Host $LogEntry -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $LogEntry
}

Write-Log "Starting Beacon Automated Tests..."
Write-Log "Log file: $LogFile"

# 1. Environment Check
Write-Log "Checking environment..."

if (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    $FlutterVersion = flutter --version | Select-Object -First 1
    Write-Log "Flutter found: $FlutterVersion"
} else {
    Write-Log "Flutter not found in PATH!" "ERROR"
    exit 1
}

if (Get-Command "adb" -ErrorAction SilentlyContinue) {
    $AdbPath = Get-Command "adb" | Select-Object -ExpandProperty Source
    Write-Log "ADB found: $AdbPath"
} else {
    Write-Log "ADB not found. Integration tests may fail if device needed." "WARNING"
}

# 2. Run Unit Tests
Write-Log "----------------------------------------"
Write-Log "SECTION 1: UNIT & WIDGET TESTS"
Write-Log "Running 'flutter test'..."
Write-Log "----------------------------------------"

$UnitTestTimer = [System.Diagnostics.Stopwatch]::StartNew()
try {
    # We pipe output to both console and file using Tee-Object logic manually since Tee-Object can buffer
    flutter test 2>&1 | ForEach-Object {
        Write-Host $_
        Add-Content -Path $LogFile -Value $_
    }
} catch {
    Write-Log "Exception running unit tests: $_" "ERROR"
}
$UnitTestTimer.Stop()
Write-Log "Unit tests finished in $($UnitTestTimer.Elapsed.TotalSeconds) seconds."

# 3. Check for Connected Devices (for Integration Tests)
Write-Log "----------------------------------------"
Write-Log "SECTION 2: DEVICE CHECK"
Write-Log "----------------------------------------"

$Devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\w+\s+device" }
if ($Devices) {
    Write-Log "Connected Device(s) Found:"
    $Devices | ForEach-Object { Write-Log "  $_" }
    
    # 4. Run Integration Tests
    Write-Log "----------------------------------------"
    Write-Log "SECTION 3: INTEGRATION TESTS"
    Write-Log "----------------------------------------"
    
    if (Test-Path "integration_test") {
        Write-Log "Running integration tests..."
    
    # Grant permissions to avoid dialogs blocking tests
    $package = "com.example.flutter_application"
    Write-Log "Granting permissions to $package..." "INFO"
    adb shell pm grant $package android.permission.ACCESS_FINE_LOCATION 2>$null
    adb shell pm grant $package android.permission.ACCESS_COARSE_LOCATION 2>$null
    adb shell pm grant $package android.permission.BLUETOOTH_CONNECT 2>$null
    adb shell pm grant $package android.permission.BLUETOOTH_SCAN 2>$null
    adb shell pm grant $package android.permission.BLUETOOTH_ADVERTISE 2>$null
    adb shell pm grant $package android.permission.NEARBY_WIFI_DEVICES 2>$null
    adb shell pm grant $package android.permission.POST_NOTIFICATIONS 2>$null

    # Run tests sequentially
        $IntTestTimer = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            flutter test integration_test 2>&1 | ForEach-Object {
                $line = $_.ToString()
                Write-Host $line 
                Add-Content -Path $LogFile -Value $line # Preserve logging to file
                
                # Dynamic Permission Granting:
                # 'flutter test' re-installs the app, wiping permissions.
                # We detect the "Installing" phase, wait for it to finish and launch (approx 15s),
                # then re-grant permissions while the test is starting.
                if ($line -match "Installing") {
                     Start-Job -ScriptBlock {
                        $p = "com.example.flutter_application"
                        Start-Sleep -Seconds 12
                        adb shell pm grant $p android.permission.ACCESS_FINE_LOCATION 2>$null
                        adb shell pm grant $p android.permission.ACCESS_COARSE_LOCATION 2>$null
                        adb shell pm grant $p android.permission.BLUETOOTH_CONNECT 2>$null
                        adb shell pm grant $p android.permission.BLUETOOTH_SCAN 2>$null
                        adb shell pm grant $p android.permission.BLUETOOTH_ADVERTISE 2>$null
                        adb shell pm grant $p android.permission.NEARBY_WIFI_DEVICES 2>$null
                        adb shell pm grant $p android.permission.POST_NOTIFICATIONS 2>$null
                     } | Out-Null
                }
            }
        } catch {
            Write-Log "Exception running integration tests: $_" "ERROR"
        }
        $IntTestTimer.Stop()
        Write-Log "Integration tests finished in $($IntTestTimer.Elapsed.TotalSeconds) seconds."
    } else {
        Write-Log "No 'integration_test' directory found. Skipping." "WARNING"
    }

} else {
    Write-Log "No connected devices found (or ADB not running)." "WARNING"
    Write-Log "Skipping Integration Tests."
}

Write-Log "----------------------------------------"
Write-Log "TEST SUITE COMPLETED"
Write-Log "Results saved to: $LogFile"
Write-Log "----------------------------------------"

# Open log file automatically
Invoke-Item $LogFile
