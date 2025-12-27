#Requires -Version 5.1
# ================================================
# SteaMar Fix Games Not Showing Script
# Created by: Abo Hassan (أبو حسن)
# Year: 2025
# ================================================

Clear-Host

# Minimal header
Write-Host ""
Write-Host "  Abo Hassan - Fix Games Not Showing" -ForegroundColor Cyan
Write-Host "  ================================" -ForegroundColor DarkGray
Write-Host ""

# Function to get Steam path
function Get-SteamPath {
    $steamPath = $null
    
    $regPath = "HKCU:\Software\Valve\Steam"
    if (Test-Path $regPath) {
        $steamPath = (Get-ItemProperty -Path $regPath -Name "SteamPath" -ErrorAction SilentlyContinue).SteamPath
        if ($steamPath -and (Test-Path $steamPath)) { return $steamPath }
    }
    
    $regPath = "HKLM:\Software\Valve\Steam"
    if (Test-Path $regPath) {
        $steamPath = (Get-ItemProperty -Path $regPath -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        if ($steamPath -and (Test-Path $steamPath)) { return $steamPath }
    }
    
    $regPath = "HKLM:\Software\WOW6432Node\Valve\Steam"
    if (Test-Path $regPath) {
        $steamPath = (Get-ItemProperty -Path $regPath -Name "InstallPath" -ErrorAction SilentlyContinue).InstallPath
        if ($steamPath -and (Test-Path $steamPath)) { return $steamPath }
    }
    
    return $null
}

# Step 1: Detect Steam
Write-Host "  [1/6] Detecting Steam..." -ForegroundColor Yellow -NoNewline
$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Steam not found. Please install Steam first." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

$steamExePath = Join-Path $steamPath "steam.exe"
if (-not (Test-Path $steamExePath)) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  steam.exe not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Step 2: Close Steam
Write-Host "  [2/6] Closing Steam..." -ForegroundColor Yellow -NoNewline
$steamProcesses = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $remainingProcesses = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($remainingProcesses) {
        Start-Sleep -Seconds 2
        $remainingProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Step 3: Update shortcuts
Write-Host "  [3/6] Updating Steam shortcuts..." -ForegroundColor Yellow -NoNewline
$shortcutPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Steam\Steam.lnk",
    "$env:USERPROFILE\Desktop\Steam.lnk",
    "$env:PUBLIC\Desktop\Steam.lnk"
)

$shortcutUpdated = $false
foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path $shortcutPath) {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $steamExePath
            $shortcut.Arguments = "-forcesteamupdate -forcepackagedownload -overridepackageurl http://web.archive.org/web/20230531113527if_/media.steampowered.com/client -exitsteam"
            $shortcut.Save()
            $shortcutUpdated = $true
        } catch { }
    }
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Step 4: Run Steam with parameters
Write-Host "  [4/6] Running Steam update..." -ForegroundColor Yellow
Write-Host "        Please wait, this may take a few minutes..." -ForegroundColor DarkGray
Write-Host ""

try {
    $process = Start-Process -FilePath $steamExePath -ArgumentList "-forcesteamupdate", "-forcepackagedownload", "-overridepackageurl", "http://web.archive.org/web/20230531113527if_/media.steampowered.com/client", "-exitsteam" -PassThru -WindowStyle Minimized
    
    $timeout = 600
    $elapsed = 0
    $checkInterval = 5
    
    while (-not $process.HasExited -and $elapsed -lt $timeout) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        
        if ($elapsed % 30 -eq 0) {
            $minutes = [math]::Floor($elapsed / 60)
            $seconds = $elapsed % 60
            Write-Host "        Still waiting... ($minutes min $seconds sec)" -ForegroundColor DarkGray
        }
    }
    
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "  [4/6] Update complete" -ForegroundColor Green
} catch {
    Write-Host "  [4/6] FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}
Write-Host ""

# Step 5: Restore shortcuts
Write-Host "  [5/6] Restoring shortcuts..." -ForegroundColor Yellow -NoNewline
foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path $shortcutPath) {
        try {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $steamExePath
            $shortcut.Arguments = ""
            $shortcut.Save()
        } catch { }
    }
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Step 6: Create steam.cfg
Write-Host "  [6/6] Creating steam.cfg..." -ForegroundColor Yellow -NoNewline
$steamCfgPath = Join-Path $steamPath "steam.cfg"

if (Test-Path $steamCfgPath) {
    Remove-Item -Path $steamCfgPath -Force -ErrorAction SilentlyContinue
}

$cfgContent = "BootStrapperInhibitAll=Enable`nBootStrapperForceSelfUpdate=False"

try {
    Set-Content -Path $steamCfgPath -Value $cfgContent -Force -Encoding ASCII
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}
Write-Host ""

# Success message
Write-Host "  ================================" -ForegroundColor DarkGray
Write-Host "  Fix completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "  Your games should now appear in Steam." -ForegroundColor Cyan
Write-Host "  You can close this window and launch Steam." -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey()

