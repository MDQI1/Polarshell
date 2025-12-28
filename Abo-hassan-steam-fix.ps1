#Requires -Version 5.1
# ================================================
# Abo Hassan - All-in-One Installer
# Created by: Abo Hassan (أبو حسن)
# Year: 2025
# ================================================
# This script will:
#   1. Install Millennium
#   2. Install Steamtools
#   3. Install Luatools Plugin
# ================================================

# Check for Admin privileges and restart if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb 'https://raw.githubusercontent.com/MDQI1/Abo-hassan-fix/main/Abo-hassan-steam-fix.ps1' | iex`""
    exit
}

Clear-Host

# Configuration
$pluginName = "luatools"
$pluginLink = "https://github.com/madoiscool/ltsteamplugin/releases/latest/download/ltsteamplugin.zip"

# Hide progress bar
$ProgressPreference = 'SilentlyContinue'

# Minimal header
Write-Host ""
Write-Host "  Abo Hassan - All-in-One Installer" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  This will install:" -ForegroundColor DarkGray
Write-Host "    1. Millennium" -ForegroundColor DarkGray
Write-Host "    2. Steamtools" -ForegroundColor DarkGray
Write-Host "    3. Luatools Plugin" -ForegroundColor DarkGray
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

# ============================================
# STEP 1: Detect Steam
# ============================================
Write-Host "  [1/7] Detecting Steam..." -ForegroundColor Yellow -NoNewline
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
Write-Host "        Path: $steamPath" -ForegroundColor DarkGray
Write-Host ""

# ============================================
# STEP 2: Close Steam
# ============================================
Write-Host "  [2/7] Closing Steam..." -ForegroundColor Yellow -NoNewline
$steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $remainingProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
    if ($remainingProcesses) {
        Start-Sleep -Seconds 2
        $remainingProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 3: Remove steam.cfg (allows updates & Millennium)
# ============================================
Write-Host "  [3/7] Removing steam.cfg..." -ForegroundColor Yellow -NoNewline
$steamCfgPath = Join-Path $steamPath "steam.cfg"

if (Test-Path $steamCfgPath) {
    try {
        Remove-Item -Path $steamCfgPath -Force -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green
        Write-Host "        Removed update blocker" -ForegroundColor DarkGray
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "        Please delete steam.cfg manually" -ForegroundColor DarkGray
    }
} else {
    Write-Host " OK" -ForegroundColor Green
    Write-Host "        No blocker found" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 4: Install Millennium
# ============================================
Write-Host "  [4/7] Installing Millennium..." -ForegroundColor Yellow
Write-Host "        Please wait, downloading from steambrew.app..." -ForegroundColor DarkGray
Write-Host ""

try {
    & { Invoke-Expression (Invoke-WebRequest 'https://steambrew.app/install.ps1' -UseBasicParsing).Content }
    Write-Host ""
    Write-Host "        Millennium installed!" -ForegroundColor Green
} catch {
    Write-Host "        Millennium installation failed!" -ForegroundColor Red
    Write-Host "        Error: $_" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 6: Install Steamtools
# ============================================
Write-Host "  [5/7] Checking Steamtools..." -ForegroundColor Yellow -NoNewline
$steamtoolsPath = Join-Path $steamPath "xinput1_4.dll"

if (Test-Path $steamtoolsPath) {
    Write-Host " Already Installed" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host " Not Found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [5/7] Installing Steamtools..." -ForegroundColor Yellow
    Write-Host "        Please wait..." -ForegroundColor DarkGray
    
    try {
        # Get and filter the installation script
        $script = Invoke-RestMethod "https://steam.run"
        $keptLines = @()

        foreach ($line in $script -split "`n") {
            $conditions = @(
                ($line -imatch "Start-Process" -and $line -imatch "steam"),
                ($line -imatch "steam\.exe"),
                ($line -imatch "Start-Sleep" -or $line -imatch "Write-Host"),
                ($line -imatch "cls" -or $line -imatch "exit"),
                ($line -imatch "Stop-Process" -and -not ($line -imatch "Get-Process"))
            )
            
            if (-not($conditions -contains $true)) {
                $keptLines += $line
            }
        }

        $SteamtoolsScript = $keptLines -join "`n"
        Invoke-Expression $SteamtoolsScript *> $null

        if (Test-Path $steamtoolsPath) {
            Write-Host "        Steamtools installed!" -ForegroundColor Green
        } else {
            Write-Host "        Steamtools installation failed!" -ForegroundColor Red
        }
    } catch {
        Write-Host "        Steamtools installation failed!" -ForegroundColor Red
        Write-Host "        Error: $_" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ============================================
# STEP 7: Install Plugin
# ============================================
Write-Host "  [6/7] Installing $pluginName plugin..." -ForegroundColor Yellow

# Ensure plugins folder exists
$pluginsFolder = Join-Path $steamPath "plugins"
if (-not (Test-Path $pluginsFolder)) {
    New-Item -Path $pluginsFolder -ItemType Directory *> $null
}

$pluginPath = Join-Path $pluginsFolder $pluginName

# Check if plugin already exists
foreach ($plugin in Get-ChildItem -Path $pluginsFolder -Directory -ErrorAction SilentlyContinue) {
    $jsonPath = Join-Path $plugin.FullName "plugin.json"
    if (Test-Path $jsonPath) {
        $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
        if ($json.name -eq $pluginName) {
            Write-Host "        Plugin found, updating..." -ForegroundColor DarkGray
            $pluginPath = $plugin.FullName
            break
        }
    }
}

# Download and install plugin
$tempZip = Join-Path $env:TEMP "$pluginName.zip"

try {
    Write-Host "        Downloading $pluginName..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $pluginLink -OutFile $tempZip *> $null
    
    Write-Host "        Extracting $pluginName..." -ForegroundColor DarkGray
    Expand-Archive -Path $tempZip -DestinationPath $pluginPath -Force *> $null
    Remove-Item $tempZip -ErrorAction SilentlyContinue
    
    Write-Host "  [6/7] Plugin installed!" -ForegroundColor Green
} catch {
    Write-Host "  [6/7] Plugin installation failed!" -ForegroundColor Red
    Write-Host "        Error: $_" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 8: Launch Steam
# ============================================
Write-Host "  [7/7] Launching Steam..." -ForegroundColor Yellow -NoNewline
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# Success message
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Note: First Steam startup will be slower." -ForegroundColor Yellow
Write-Host "  Don't panic and wait for Steam to load!" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to launch Steam..."
$null = $Host.UI.RawUI.ReadKey()

# Launch Steam and enable plugin
Start-Process "steam://millennium/settings/plugins/enable/$pluginName"

Write-Host ""
Write-Host "  Done! Steam is starting with Millennium." -ForegroundColor Green
Write-Host "  Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey()
