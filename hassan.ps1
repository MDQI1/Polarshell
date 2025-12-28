#Requires -Version 5.1
# ================================================
# أبو حسن - المثبت الشامل
# المطور: أبو حسن (Abo Hassan)
# السنة: 2025
# ================================================
# هذا السكربت يقوم بـ:
#   1. تثبيت Millennium
#   2. تثبيت Steamtools
#   3. تثبيت إضافة Luatools
# ================================================

# التحقق من صلاحيات المدير وإعادة التشغيل إذا لزم
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "جاري طلب صلاحيات المدير..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"iwr -useb 'https://raw.githubusercontent.com/MDQI1/Abo-hassan-fix/main/Abo-hassan-steam-fix.ps1' | iex`""
    exit
}

Clear-Host

# الإعدادات
$pluginName = "luatools"
$pluginLink = "https://github.com/madoiscool/ltsteamplugin/releases/latest/download/ltsteamplugin.zip"

# إخفاء شريط التقدم
$ProgressPreference = 'SilentlyContinue'

# العنوان الرئيسي
Write-Host ""
Write-Host "  أبو حسن - المثبت الشامل" -ForegroundColor Cyan
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  سيتم تثبيت:" -ForegroundColor DarkGray
Write-Host "    1. Millennium" -ForegroundColor DarkGray
Write-Host "    2. Steamtools" -ForegroundColor DarkGray
Write-Host "    3. إضافة Luatools" -ForegroundColor DarkGray
Write-Host ""

# دالة للحصول على مسار Steam
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
# الخطوة 1: البحث عن Steam
# ============================================
Write-Host "  [1/8] جاري البحث عن Steam..." -ForegroundColor Yellow -NoNewline
$steamPath = Get-SteamPath

if (-not $steamPath) {
    Write-Host " فشل" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Steam غير موجود. الرجاء تثبيت Steam أولاً." -ForegroundColor Red
    Write-Host ""
    Write-Host "  اضغط أي مفتاح للخروج..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

$steamExePath = Join-Path $steamPath "steam.exe"
if (-not (Test-Path $steamExePath)) {
    Write-Host " فشل" -ForegroundColor Red
    Write-Host ""
    Write-Host "  steam.exe غير موجود." -ForegroundColor Red
    Write-Host ""
    Write-Host "  اضغط أي مفتاح للخروج..."
    $null = $Host.UI.RawUI.ReadKey()
    exit 1
}

Write-Host " تم" -ForegroundColor Green
Write-Host "        المسار: $steamPath" -ForegroundColor DarkGray
Write-Host ""

# ============================================
# الخطوة 2: إغلاق Steam
# ============================================
Write-Host "  [2/8] جاري إغلاق Steam..." -ForegroundColor Yellow -NoNewline
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
Write-Host " تم" -ForegroundColor Green
Write-Host ""

# ============================================
# الخطوة 3: حذف steam.cfg (السماح بالتحديثات و Millennium)
# ============================================
Write-Host "  [3/8] جاري حذف steam.cfg..." -ForegroundColor Yellow -NoNewline
$steamCfgPath = Join-Path $steamPath "steam.cfg"

if (Test-Path $steamCfgPath) {
    try {
        Remove-Item -Path $steamCfgPath -Force -ErrorAction Stop
        Write-Host " تم" -ForegroundColor Green
        Write-Host "        تم حذف مانع التحديثات" -ForegroundColor DarkGray
    } catch {
        Write-Host " فشل" -ForegroundColor Red
        Write-Host "        الرجاء حذف steam.cfg يدوياً" -ForegroundColor DarkGray
    }
} else {
    Write-Host " تم" -ForegroundColor Green
    Write-Host "        لا يوجد مانع تحديثات" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# الخطوة 4: تنظيف إعدادات Millennium (إصلاح JSON الخاطئ)
# ============================================
Write-Host "  [4/8] جاري تنظيف إعدادات Millennium..." -ForegroundColor Yellow -NoNewline
$extConfigPath = Join-Path $steamPath "ext\config.json"

if (Test-Path $extConfigPath) {
    try {
        Remove-Item -Path $extConfigPath -Force -ErrorAction Stop
        Write-Host " تم" -ForegroundColor Green
        Write-Host "        تم حذف الإعدادات التالفة" -ForegroundColor DarkGray
    } catch {
        Write-Host " فشل" -ForegroundColor Red
        Write-Host "        الرجاء حذف ext\config.json يدوياً" -ForegroundColor DarkGray
    }
} else {
    Write-Host " تم" -ForegroundColor Green
    Write-Host "        لا توجد إعدادات للتنظيف" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# الخطوة 5: تثبيت Millennium
# ============================================
Write-Host "  [5/8] جاري تثبيت Millennium..." -ForegroundColor Yellow
Write-Host "        انتظر قليلاً، جاري التحميل من steambrew.app..." -ForegroundColor DarkGray
Write-Host ""

try {
    & { Invoke-Expression (Invoke-WebRequest 'https://steambrew.app/install.ps1' -UseBasicParsing).Content }
    Write-Host ""
    Write-Host "        تم تثبيت Millennium!" -ForegroundColor Green
} catch {
    Write-Host "        فشل تثبيت Millennium!" -ForegroundColor Red
    Write-Host "        الخطأ: $_" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# الخطوة 6: تثبيت Steamtools
# ============================================
Write-Host "  [6/8] جاري التحقق من Steamtools..." -ForegroundColor Yellow -NoNewline
$steamtoolsPath = Join-Path $steamPath "xinput1_4.dll"

if (Test-Path $steamtoolsPath) {
    Write-Host " مثبت مسبقاً" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host " غير موجود" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [6/8] جاري تثبيت Steamtools..." -ForegroundColor Yellow
    Write-Host "        انتظر قليلاً..." -ForegroundColor DarkGray
    
    try {
        # تحميل وتصفية سكربت التثبيت
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
            Write-Host "        تم تثبيت Steamtools!" -ForegroundColor Green
        } else {
            Write-Host "        فشل تثبيت Steamtools!" -ForegroundColor Red
        }
    } catch {
        Write-Host "        فشل تثبيت Steamtools!" -ForegroundColor Red
        Write-Host "        الخطأ: $_" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# ============================================
# الخطوة 7: تثبيت الإضافة
# ============================================
Write-Host "  [7/8] جاري تثبيت إضافة $pluginName..." -ForegroundColor Yellow

# التأكد من وجود مجلد الإضافات
$pluginsFolder = Join-Path $steamPath "plugins"
if (-not (Test-Path $pluginsFolder)) {
    New-Item -Path $pluginsFolder -ItemType Directory *> $null
}

$pluginPath = Join-Path $pluginsFolder $pluginName

# التحقق من وجود الإضافة مسبقاً
foreach ($plugin in Get-ChildItem -Path $pluginsFolder -Directory -ErrorAction SilentlyContinue) {
    $jsonPath = Join-Path $plugin.FullName "plugin.json"
    if (Test-Path $jsonPath) {
        $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
        if ($json.name -eq $pluginName) {
            Write-Host "        الإضافة موجودة، جاري التحديث..." -ForegroundColor DarkGray
            $pluginPath = $plugin.FullName
            break
        }
    }
}

# تحميل وتثبيت الإضافة
$tempZip = Join-Path $env:TEMP "$pluginName.zip"

try {
    Write-Host "        جاري تحميل $pluginName..." -ForegroundColor DarkGray
    Invoke-WebRequest -Uri $pluginLink -OutFile $tempZip *> $null
    
    Write-Host "        جاري فك الضغط $pluginName..." -ForegroundColor DarkGray
    Expand-Archive -Path $tempZip -DestinationPath $pluginPath -Force *> $null
    Remove-Item $tempZip -ErrorAction SilentlyContinue
    
    Write-Host "  [7/8] تم تثبيت الإضافة!" -ForegroundColor Green
} catch {
    Write-Host "  [7/8] فشل تثبيت الإضافة!" -ForegroundColor Red
    Write-Host "        الخطأ: $_" -ForegroundColor DarkGray
}
Write-Host ""

# ============================================
# الخطوة 8: تشغيل Steam
# ============================================
Write-Host "  [8/8] جاري تشغيل Steam..." -ForegroundColor Yellow -NoNewline
Write-Host " تم" -ForegroundColor Green
Write-Host ""

# رسالة النجاح
Write-Host "  ===================================" -ForegroundColor DarkGray
Write-Host "  اكتمل التثبيت!" -ForegroundColor Green
Write-Host ""
Write-Host "  ملاحظة: أول تشغيل لـ Steam سيكون أبطأ." -ForegroundColor Yellow
Write-Host "  لا تقلق وانتظر حتى يتم تحميل Steam!" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  اضغط أي مفتاح لتشغيل Steam..."
$null = $Host.UI.RawUI.ReadKey()

# تشغيل Steam وتفعيل الإضافة
Start-Process "steam://millennium/settings/plugins/enable/$pluginName"

Write-Host ""
Write-Host "  تم! Steam يعمل الآن مع Millennium." -ForegroundColor Green
Write-Host "  اضغط أي مفتاح للخروج..."
$null = $Host.UI.RawUI.ReadKey()
