# CPAP Mask Monitor — Windows Installer
# Run this script in PowerShell as Administrator:
# Right-click PowerShell → Run as Administrator → navigate to repo folder → .\install.ps1

param(
    [string]$InstallDir = "$env:USERPROFILE\cpap-mask-monitor"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   CPAP Mask Monitor - Windows Installer   " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Check PowerShell execution policy ─────────────────────────────────
Write-Host "► Checking execution policy..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy
if ($policy -eq "Restricted") {
    Write-Host "  Setting execution policy to RemoteSigned..." -ForegroundColor Yellow
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}
Write-Host "  OK" -ForegroundColor Green

# ── Step 2: Check Python ──────────────────────────────────────────────────────
Write-Host "► Checking Python..." -ForegroundColor Yellow
try {
    $pyVersion = python --version 2>&1
    Write-Host "  Found: $pyVersion" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "  ERROR: Python not found." -ForegroundColor Red
    Write-Host "  Please install Python 3.10 or later from https://www.python.org/downloads/" -ForegroundColor Red
    Write-Host "  Make sure to check 'Add Python to PATH' during installation." -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ── Step 3: Check Microsoft C++ Build Tools ───────────────────────────────────
Write-Host "► Checking Microsoft C++ Build Tools..." -ForegroundColor Yellow
$vcFound = $false
$vcPaths = @(
    "C:\Program Files (x86)\Microsoft Visual Studio",
    "C:\Program Files\Microsoft Visual Studio",
    "C:\Program Files (x86)\Microsoft Visual C++ Build Tools"
)
foreach ($path in $vcPaths) {
    if (Test-Path $path) { $vcFound = $true; break }
}

if (-not $vcFound) {
    Write-Host ""
    Write-Host "  Microsoft C++ Build Tools not found." -ForegroundColor Yellow
    Write-Host "  These are required to install the Tapo library." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please install them from:" -ForegroundColor Yellow
    Write-Host "  https://visualstudio.microsoft.com/visual-cpp-build-tools/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  During installation, select:" -ForegroundColor Yellow
    Write-Host "  'Desktop development with C++'" -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "  Have you installed the Build Tools? Press Y to continue or N to exit"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "  Please install the Build Tools and run this script again." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  Found" -ForegroundColor Green
}

# ── Step 4: Create install directory ─────────────────────────────────────────
Write-Host "► Setting up install directory..." -ForegroundColor Yellow
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Copy-Item "$scriptDir\*" -Destination $InstallDir -Recurse -Force -Exclude "install.ps1"
Write-Host "  Installed to: $InstallDir" -ForegroundColor Green

# ── Step 5: Install Python dependencies ───────────────────────────────────────
Write-Host "► Installing Python dependencies..." -ForegroundColor Yellow
python -m pip install tapo requests --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to install dependencies." -ForegroundColor Red
    Write-Host "  Try running: python -m pip install tapo requests" -ForegroundColor Red
    exit 1
}
Write-Host "  Done" -ForegroundColor Green

# ── Step 6: Config setup ──────────────────────────────────────────────────────
Write-Host "► Setting up config..." -ForegroundColor Yellow
$configPath = "$InstallDir\config.json"
if (-not (Test-Path $configPath)) {
    Copy-Item "$InstallDir\config.example.json" -Destination $configPath
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │  Please fill in your details:           │" -ForegroundColor Cyan
    Write-Host "  │                                         │" -ForegroundColor Cyan
    Write-Host "  │  • Tapo account email & password        │" -ForegroundColor Cyan
    Write-Host "  │  • Tapo plug IP address                 │" -ForegroundColor Cyan
    Write-Host "  │  • Pushover user key & app token        │" -ForegroundColor Cyan
    Write-Host "  │  • Your timezone offset (e.g. 5.5 IST) │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "  Press Enter to open config.json in Notepad"
    Start-Process notepad.exe -ArgumentList $configPath -Wait
} else {
    Write-Host "  config.json already exists, skipping." -ForegroundColor Green
}

# ── Step 7: Register Task Scheduler tasks ─────────────────────────────────────
Write-Host "► Registering background tasks in Task Scheduler..." -ForegroundColor Yellow
$pythonPath = (Get-Command python).Source

# Monitor task
$monitorAction  = New-ScheduledTaskAction -Execute $pythonPath -Argument "`"$InstallDir\cpap_monitor.py`"" -WorkingDirectory $InstallDir
$monitorTrigger = New-ScheduledTaskTrigger -AtLogOn
$monitorSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable
Register-ScheduledTask -TaskName "CPAP Monitor" -Action $monitorAction -Trigger $monitorTrigger -Settings $monitorSettings -RunLevel Highest -Force | Out-Null

# HTTP server task
$httpAction  = New-ScheduledTaskAction -Execute $pythonPath -Argument "`"$InstallDir\cpap_http_server.py`"" -WorkingDirectory $InstallDir
$httpTrigger = New-ScheduledTaskTrigger -AtLogOn
$httpSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -StartWhenAvailable
Register-ScheduledTask -TaskName "CPAP HTTP Server" -Action $httpAction -Trigger $httpTrigger -Settings $httpSettings -RunLevel Highest -Force | Out-Null

Write-Host "  Done" -ForegroundColor Green

# ── Step 8: Start tasks now ───────────────────────────────────────────────────
Write-Host "► Starting monitor and HTTP server..." -ForegroundColor Yellow
Start-ScheduledTask -TaskName "CPAP Monitor"
Start-Sleep -Seconds 2
Start-ScheduledTask -TaskName "CPAP HTTP Server"
Start-Sleep -Seconds 2
Write-Host "  Done" -ForegroundColor Green

# ── Done ──────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "      Installation Complete!               " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Monitor is now running in the background." -ForegroundColor Green
Write-Host ""
Write-Host "  Useful commands (run in PowerShell):" -ForegroundColor Cyan
Write-Host "  • Check status:   Get-ScheduledTask -TaskName 'CPAP Monitor'"
Write-Host "  • View log:       Get-Content '$InstallDir\cpap_monitor.log' -Tail 30"
Write-Host "  • Stop monitor:   Stop-ScheduledTask -TaskName 'CPAP Monitor'"
Write-Host "  • Start monitor:  Start-ScheduledTask -TaskName 'CPAP Monitor'"
Write-Host "  • HTTP status:    Invoke-WebRequest http://localhost:8765/status | Select -Expand Content"
Write-Host ""
Write-Host "  Install directory: $InstallDir" -ForegroundColor Cyan
Write-Host "  Log file:          $InstallDir\cpap_monitor.log" -ForegroundColor Cyan
Write-Host ""
