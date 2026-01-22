#Requires -Version 5.1
# ================================================
# Polar Commuity  - All-in-One Installer (PolarCommunity)
# Created by: PolarCommunity
# Year: 2025
# ================================================
# This script will:
#   1. Add Steam to Windows Defender exclusions
#   2. Clean old installations
#   3. Install Millennium
#   4. Install PolarTools Plugin
#   5. Clean Steam cache
# ================================================

# Set UTF-8 encoding
chcp 65001 | Out-Null
$OutputEncoding = [Console]::OutputEncoding = [Text.Encoding]::UTF8

# Download script to temp for admin restart
$tempScriptPath = Join-Path $env:TEMP "polar-Community.ps1"
if ($PSCommandPath) {
    Copy-Item -Path $PSCommandPath -Destination $tempScriptPath -Force -ErrorAction SilentlyContinue
}

# Check for Admin privileges and restart if needed
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $scriptToRun = if (Test-Path $tempScriptPath) { $tempScriptPath } else { $PSCommandPath }
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptToRun`""
    exit
}

Clear-Host

# Configuration
$pluginName = "PolarTools"
$pluginLink = "https://github.com/MDQI1/PolarTools/releases/download/1.5.6/PolarTools_v1.5.6.zip"
$oldPluginNames = @("luatools", "manilua", "stelenium", "PolarTools")  # Old plugin names to remove

# Hide progress bar for faster downloads
$ProgressPreference = 'SilentlyContinue'

# ============================================
# HEADER
# ============================================
Write-Host ""
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host "   Polar Commuity  - All-in-One (PolarCommunity)" -ForegroundColor Cyan
Write-Host "               Version 2.0                 " -ForegroundColor Cyan
Write-Host "  =========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This will install:" -ForegroundColor DarkGray
Write-Host "    - Millennium (Steam modding framework)" -ForegroundColor DarkGray
Write-Host "    - PolarTools Plugin" -ForegroundColor DarkGray
Write-Host ""

# ============================================
# STEP 1: Detect Steam Path
# ============================================
Write-Host "  [1/9] Detecting Steam..." -ForegroundColor Yellow -NoNewline
$steamPath = $null

# Try multiple registry locations
$regPaths = @(
    @{ Path = "HKCU:\Software\Valve\Steam"; Key = "SteamPath" },
    @{ Path = "HKLM:\Software\Valve\Steam"; Key = "InstallPath" },
    @{ Path = "HKLM:\Software\WOW6432Node\Valve\Steam"; Key = "InstallPath" }
)

foreach ($reg in $regPaths) {
    if (Test-Path $reg.Path) {
        $steamPath = (Get-ItemProperty -Path $reg.Path -Name $reg.Key -ErrorAction SilentlyContinue).$($reg.Key)
        if ($steamPath -and (Test-Path $steamPath)) { break }
        $steamPath = $null
    }
}

if (-not $steamPath) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Steam not found! Please install Steam first." -ForegroundColor Red
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

$steamExePath = Join-Path $steamPath "steam.exe"
if (-not (Test-Path $steamExePath)) {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "  steam.exe not found at: $steamPath" -ForegroundColor Red
    Write-Host "  Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

Write-Host " OK" -ForegroundColor Green
Write-Host "        Path: $steamPath" -ForegroundColor DarkGray
Write-Host ""

# ============================================
# STEP 2: Add Steam to Windows Defender Exclusions
# ============================================
Write-Host "  [2/9] Windows Defender exclusions..." -ForegroundColor Yellow -NoNewline
try {
    $defenderPreferences = Get-MpPreference -ErrorAction SilentlyContinue
    $exclusions = $defenderPreferences.ExclusionPath

    if ($exclusions -notcontains $steamPath) {
        Add-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue
        Write-Host " Added" -ForegroundColor Green
        Write-Host "        Steam folder added to exclusions" -ForegroundColor DarkGray
    } else {
        Write-Host " OK" -ForegroundColor Green
        Write-Host "        Already in exclusions" -ForegroundColor DarkGray
    }
} catch {
    Write-Host " SKIPPED" -ForegroundColor Yellow
    Write-Host "        Could not modify Defender settings" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 3: Close Steam
# ============================================
Write-Host "  [3/9] Closing Steam..." -ForegroundColor Yellow -NoNewline
$steamProcesses = Get-Process -Name "steam*" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    $steamProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    # Double check
    Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Write-Host " OK" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 4: Remove steam.cfg (update blocker)
# ============================================
Write-Host "  [4/9] Removing steam.cfg..." -ForegroundColor Yellow -NoNewline
$steamCfgPath = Join-Path $steamPath "steam.cfg"

if (Test-Path $steamCfgPath) {
    Remove-Item -Path $steamCfgPath -Force -ErrorAction SilentlyContinue
    Write-Host " Removed" -ForegroundColor Green
    Write-Host "        Update blocker removed" -ForegroundColor DarkGray
} else {
    Write-Host " OK" -ForegroundColor Green
    Write-Host "        No blocker found" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# STEP 5: Clean old installations
# ============================================
Write-Host "  [5/9] Cleaning old installations..." -ForegroundColor Yellow

# Remove old Steamtools files
$steamtoolsFiles = @(
    (Join-Path $steamPath "hid.dll"),
    (Join-Path $steamPath "xinput1_4.dll")
)

foreach ($file in $steamtoolsFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force -ErrorAction SilentlyContinue
        Write-Host "        Removed: $(Split-Path $file -Leaf)" -ForegroundColor DarkGray
    }
}

# Remove old config.json
$configJsonPath = Join-Path $steamPath "ext\config.json"
if (Test-Path $configJsonPath) {
    Remove-Item $configJsonPath -Force -ErrorAction SilentlyContinue
    Write-Host "        Removed old config.json" -ForegroundColor DarkGray
}

# Remove old Millennium files
$millenniumFiles = @(
    (Join-Path $steamPath "ext"),
    (Join-Path $steamPath "user32.dll"),
    (Join-Path $steamPath "version.dll"),
    (Join-Path $steamPath "wsock32.dll"),
    (Join-Path $steamPath "millennium.dll"),
    (Join-Path $steamPath "millennium.hhx64.dll"),
    (Join-Path $steamPath "python311.dll")
)

foreach ($file in $millenniumFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "        Removed: $(Split-Path $file -Leaf)" -ForegroundColor DarkGray
    }
}

# Remove old plugins (luatools, manilua, stelenium, PolarTools)
$pluginsPath = Join-Path $steamPath "plugins"
if (Test-Path $pluginsPath -PathType Container) {
    Get-ChildItem -Path $pluginsPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $jsonPath = Join-Path $_.FullName "plugin.json"
        if (Test-Path $jsonPath) {
            try {
                $manifest = Get-Content $jsonPath -Raw | ConvertFrom-Json
                if ($manifest.name -in $oldPluginNames) {
                    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "        Removed old plugin: $($manifest.name)" -ForegroundColor DarkGray
                }
            } catch {}
        }
    }
}

Write-Host "        Cleanup complete!" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 6: Install Millennium
# ============================================
Write-Host "  [6/9] Installing Millennium..." -ForegroundColor Yellow
Write-Host "        Downloading from GitHub..." -ForegroundColor DarkGray

try {
    $installerUrl = "https://github.com/SteamClientHomebrew/Installer/releases/latest/download/MillenniumInstaller-Windows.exe"
    $installerPath = Join-Path $env:TEMP "MillenniumInstaller-Windows.exe"
    
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 120
    
    if (Test-Path $installerPath) {
        Write-Host ""
        Write-Host "        =============================================" -ForegroundColor Magenta
        Write-Host "          Millennium installer will open now!      " -ForegroundColor Magenta
        Write-Host "          1. Click 'Install' in the installer      " -ForegroundColor Magenta
        Write-Host "          2. Wait for installation to complete     " -ForegroundColor Magenta
        Write-Host "          3. The script will continue automatically" -ForegroundColor Magenta
        Write-Host "        =============================================" -ForegroundColor Magenta
        Write-Host ""
        
        # Run installer and wait for it to exit
        $process = Start-Process -FilePath $installerPath -PassThru
        
        Write-Host "        Waiting for installer to close..." -ForegroundColor Yellow
        
        # Wait for the main installer process to exit
        $process.WaitForExit()
        
        # Wait a bit more for any child processes
        Start-Sleep -Seconds 3
        
        # Check for any remaining Millennium installer processes
        $remainingProcesses = Get-Process | Where-Object { $_.Path -like "*Millennium*" } -ErrorAction SilentlyContinue
        if ($remainingProcesses) {
            Write-Host "        Waiting for installer to finish..." -ForegroundColor Yellow
            $remainingProcesses | Wait-Process -Timeout 120 -ErrorAction SilentlyContinue
        }
        
        Remove-Item $installerPath -ErrorAction SilentlyContinue
        
        # Verify installation
        $extPath = Join-Path $steamPath "ext"
        if (Test-Path $extPath) {
            Write-Host "        Millennium installed!" -ForegroundColor Green
        } else {
            Write-Host "        Please verify Millennium installation" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "        Millennium installation failed: $_" -ForegroundColor Red
}
Write-Host ""

# ============================================
# STEP 7: Install PolarTools Plugin
# ============================================
Write-Host "  [7/9] Installing $pluginName plugin..." -ForegroundColor Yellow

# Ensure plugins folder exists
$pluginsFolder = Join-Path $steamPath "plugins"
if (-not (Test-Path $pluginsFolder)) {
    New-Item -Path $pluginsFolder -ItemType Directory | Out-Null
}

$pluginPath = Join-Path $pluginsFolder $pluginName
$tempZip = Join-Path $env:TEMP "$pluginName.zip"
$tempExtract = Join-Path $env:TEMP "$pluginName-extract"

try {
    Write-Host "        Downloading $pluginName..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $pluginLink -OutFile $tempZip -UseBasicParsing -TimeoutSec 120
    
    Write-Host "        Extracting $pluginName..." -ForegroundColor DarkGray
    
    # Remove old plugin folder if exists
    if (Test-Path $pluginPath) {
        Remove-Item $pluginPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Remove temp extract folder if exists
    if (Test-Path $tempExtract) {
        Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Extract to temp folder first
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    
    # Check if there's a nested folder inside (like PolarTools inside the zip)
    $extractedItems = Get-ChildItem -Path $tempExtract -Force
    if ($extractedItems.Count -eq 1 -and $extractedItems[0].PSIsContainer) {
        # Single folder inside - move its contents to the plugin path
        $innerFolder = $extractedItems[0].FullName
        Move-Item -Path $innerFolder -Destination $pluginPath -Force
    } else {
        # Multiple items or files - move the whole temp folder
        Move-Item -Path $tempExtract -Destination $pluginPath -Force
    }
    
    # Cleanup
    Remove-Item $tempZip -ErrorAction SilentlyContinue
    Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "        Plugin installed!" -ForegroundColor Green
} catch {
    Write-Host "        Plugin installation failed: $_" -ForegroundColor Red
}
Write-Host ""

# ============================================
# STEP 8: Clean Steam Cache
# ============================================
Write-Host "  [8/9] Cleaning Steam cache..." -ForegroundColor Yellow

$backupPath = Join-Path $steamPath "cache-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# Backup and clean appcache
$appcachePath = Join-Path $steamPath "appcache"
if (Test-Path $appcachePath) {
    $appcacheBackupPath = Join-Path $backupPath "appcache"
    New-Item -ItemType Directory -Path $appcacheBackupPath -Force | Out-Null
    Get-ChildItem -Path $appcachePath -Force -Exclude "stats" | Move-Item -Destination $appcacheBackupPath -Force -ErrorAction SilentlyContinue
    Write-Host "        Cleaned appcache" -ForegroundColor DarkGray
}

# Clean user config cache (preserve playtime)
$userdataPath = Join-Path $steamPath "userdata"
if (Test-Path $userdataPath) {
    $userFolders = Get-ChildItem -Path $userdataPath -Directory -ErrorAction SilentlyContinue
    foreach ($userFolder in $userFolders) {
        $userConfigPath = Join-Path $userFolder.FullName "config"
        if (Test-Path $userConfigPath) {
            $userBackupPath = Join-Path $backupPath "userdata\$($userFolder.Name)"
            New-Item -ItemType Directory -Path $userBackupPath -Force | Out-Null
            
            # Backup config
            Move-Item -Path $userConfigPath -Destination (Join-Path $userBackupPath "config") -Force -ErrorAction SilentlyContinue
            
            # Restore only localconfig.vdf (contains playtime)
            New-Item -ItemType Directory -Path $userConfigPath -Force | Out-Null
            $localConfigPath = Join-Path $userBackupPath "config\localconfig.vdf"
            if (Test-Path $localConfigPath) {
                Copy-Item $localConfigPath -Destination (Join-Path $userConfigPath "localconfig.vdf") -Force -ErrorAction SilentlyContinue
            }
            Write-Host "        Cleaned cache for user: $($userFolder.Name)" -ForegroundColor DarkGray
        }
    }
}

Write-Host "        Cache cleaned! (Backup: $backupPath)" -ForegroundColor Green
Write-Host ""

# ============================================
# STEP 9: Launch Steam & Enable Plugin
# ============================================
Write-Host "  [9/9] Starting Steam & Enabling Plugin..." -ForegroundColor Yellow

# Enable plugin by modifying Millennium config file BEFORE launching Steam
$millenniumConfigPath = Join-Path $steamPath "ext\config.json"
if (Test-Path $millenniumConfigPath) {
    try {
        $config = Get-Content $millenniumConfigPath -Raw | ConvertFrom-Json
        
        # Initialize plugins object if not exists
        if (-not $config.PSObject.Properties['plugins']) {
            $config | Add-Member -NotePropertyName 'plugins' -NotePropertyValue @{} -Force
        }
        
        # Enable plugin using the correct name from plugin.json ("PolarCommunity")
        $config.plugins | Add-Member -NotePropertyName 'PolarCommunity' -NotePropertyValue $true -Force
        
        # Save config
        $config | ConvertTo-Json -Depth 10 | Set-Content $millenniumConfigPath -Encoding UTF8
        Write-Host "        Plugin enabled in config!" -ForegroundColor Green
    } catch {
        Write-Host "        Could not modify config file: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "        Config file not found, will enable via URI..." -ForegroundColor Yellow
}

Write-Host "        Launching Steam..." -ForegroundColor DarkGray
Start-Process -FilePath $steamExePath -ArgumentList "-clearbeta -dev"

Write-Host "        Waiting for Steam to load (15 seconds)..." -ForegroundColor DarkGray
Start-Sleep -Seconds 15

# Also try the URI method as backup with correct plugin name
Write-Host "        Enabling plugin via Millennium..." -ForegroundColor DarkGray
Start-Process "steam://millennium/settings/plugins/enable/PolarCommunity" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

Write-Host "        Restarting Steam..." -ForegroundColor DarkGray
Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Start-Process -FilePath $steamExePath -ArgumentList "-clearbeta"

# ============================================
# DONE!
# ============================================
Write-Host ""
Write-Host "  =========================================" -ForegroundColor Green
Write-Host "        Installation Complete!             " -ForegroundColor Green
Write-Host "  =========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Everything installed successfully!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Notes:" -ForegroundColor Yellow
Write-Host "    - First Steam startup may be slower" -ForegroundColor DarkGray
Write-Host "    - If Steam crashes, try running it again" -ForegroundColor DarkGray
Write-Host "    - Cache backup saved to: cache-backup-*" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey()
