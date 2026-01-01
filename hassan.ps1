#Requires -Version 5.1
# ================================================
# Abo Hassan - Steam Reset Tool
# Created by: Abo Hassan (أبو حسن)
# Year: 2025
# ================================================
# This script will:
#   1. Backup config folder to Desktop
#   2. Delete Steam.dll, Steam.cfg, Steam2.dll
#   3. Launch Steam (login required)
#   4. Close Steam after login
#   5. Restore config (except depotcache, stplug-in)
# ================================================

# Check for Admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Clear-Host

# Hide progress bar
$ProgressPreference = 'SilentlyContinue'

# Header
Write-Host ""
Write-Host "  Abo Hassan - Steam Reset Tool" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor DarkGray
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

Write-Host " OK" -ForegroundColor Green
Write-Host "        Path: $steamPath" -ForegroundColor DarkGray
Write-Host ""

# Define paths
$configPath = Join-Path $steamPath "config"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$backupBaseName = "Steam_Config_Backup"
$backupPath = Join-Path $desktopPath $backupBaseName

# Find unique backup name (Steam_Config_Backup, Steam_Config_Backup_1, Steam_Config_Backup_2, etc.)
if (Test-Path $backupPath) {
    $counter = 1
    while (Test-Path (Join-Path $desktopPath "${backupBaseName}_$counter")) {
        $counter++
    }
    $backupPath = Join-Path $desktopPath "${backupBaseName}_$counter"
}

# ============================================
# STEP 2: Close Steam
# ============================================
Write-Host "  [2/7] Closing Steam..." -ForegroundColor Yellow -NoNewline
$steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 3: Move (cut) config folder to Desktop
# ============================================
Write-Host "  [3/7] Moving config folder to Desktop..." -ForegroundColor Yellow -NoNewline

if (Test-Path $configPath) {
    try {
        # Move (cut) config to desktop
        Move-Item -Path $configPath -Destination $backupPath -Force -ErrorAction Stop
        Write-Host " OK" -ForegroundColor Green
        Write-Host "        Moved to: $backupPath" -ForegroundColor DarkGray
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "        Error: $_" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey()
        exit 1
    }
} else {
    Write-Host " SKIPPED" -ForegroundColor Yellow
    Write-Host "        Config folder not found" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 4: Delete Steam files
# ============================================
Write-Host "  [4/7] Deleting Steam files..." -ForegroundColor Yellow

$filesToDelete = @(
    "Steam.dll",
    "Steam.cfg",
    "Steam2.dll"
)

foreach ($file in $filesToDelete) {
    $filePath = Join-Path $steamPath $file
    Write-Host "        Deleting $file..." -ForegroundColor DarkGray -NoNewline
    
    if (Test-Path $filePath) {
        try {
            Remove-Item -Path $filePath -Force -ErrorAction Stop
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " FAILED" -ForegroundColor Red
        }
    } else {
        Write-Host " Not Found" -ForegroundColor DarkGray
    }
}
Write-Host ""

# ============================================
# STEP 5: Launch Steam (login required)
# ============================================
Write-Host "  [5/7] Launching Steam..." -ForegroundColor Yellow
Write-Host "        Please login to Steam when prompted" -ForegroundColor Magenta
Write-Host ""

$steamExe = Join-Path $steamPath "steam.exe"
Start-Process $steamExe

Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host "  Waiting for you to login to Steam..." -ForegroundColor Yellow
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  After you login, press any key to continue..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey()
Write-Host ""

# ============================================
# STEP 6: Close Steam
# ============================================
Write-Host "  [6/7] Closing Steam..." -ForegroundColor Yellow -NoNewline
$steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 7: Restore config (except depotcache, stplug-in)
# ============================================
Write-Host "  [7/7] Restoring config..." -ForegroundColor Yellow

if (Test-Path $backupPath) {
    # Folders to exclude from restore
    $excludeFolders = @("depotcache", "stplug-in")
    
    # Get all items in backup
    $backupItems = Get-ChildItem -Path $backupPath -ErrorAction SilentlyContinue
    
    foreach ($item in $backupItems) {
        $itemName = $item.Name.ToLower()
        
        # Skip excluded folders
        if ($excludeFolders -contains $itemName) {
            Write-Host "        Skipping $($item.Name)..." -ForegroundColor DarkGray
            continue
        }
        
        $destPath = Join-Path $configPath $item.Name
        
        Write-Host "        Restoring $($item.Name)..." -ForegroundColor DarkGray -NoNewline
        
        try {
            if ($item.PSIsContainer) {
                # It's a folder
                if (Test-Path $destPath) {
                    Remove-Item -Path $destPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force -ErrorAction Stop
            } else {
                # It's a file
                Copy-Item -Path $item.FullName -Destination $destPath -Force -ErrorAction Stop
            }
            Write-Host " OK" -ForegroundColor Green
        } catch {
            Write-Host " FAILED" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "        Config restored (excluded: depotcache, stplug-in)" -ForegroundColor Green
} else {
    Write-Host "        No backup found to restore" -ForegroundColor Yellow
}
Write-Host ""

# ============================================
# Done
# ============================================
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host "  Steam Reset Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Backup location: $backupPath" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey()
