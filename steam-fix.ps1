#Requires -Version 5.1
# Abo Hassan - Steam Fix

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$steam = "C:\Program Files (x86)\Steam"

Write-Host "`n  Fixing Steam...`n" -ForegroundColor Cyan

# Kill Steam
Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Get-Process -Name "steam*" -ErrorAction SilentlyContinue | Stop-Process -Force

# Remove Millennium + Steamtools
Remove-Item "$steam\user32.dll", "$steam\user32.dll.bak" -Force -ErrorAction SilentlyContinue
Remove-Item "$steam\version.dll", "$steam\version.dll.bak" -Force -ErrorAction SilentlyContinue
Remove-Item "$steam\xinput1_4.dll" -Force -ErrorAction SilentlyContinue
Remove-Item "$steam\ext", "$steam\plugins", "$steam\stplug-in" -Recurse -Force -ErrorAction SilentlyContinue

# Clear cache
Remove-Item "$steam\appcache", "$steam\depotcache", "$steam\config\htmlcache" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  Done! Starting Steam..." -ForegroundColor Green
Start-Process "$steam\steam.exe"

Start-Sleep -Seconds 2
