# ==============================================================================
# ZoneShift - Windhawk Mod Installer Script
# ==============================================================================
# Copies zoneshift.wh.cpp into the Windhawk local mods directory.
# This makes the mod immediately accessible in the Windhawk UI for compilation
# and activation.
# ==============================================================================

[CmdletBinding()]
param(
    [string]$WindhawkDataPath = "C:\ProgramData\Windhawk",
    [switch]$AutoCompile
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  ZoneShift - Windhawk Mod Installer                " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$sourceModPath = Join-Path $PSScriptRoot "zoneshift.wh.cpp"
if (-not (Test-Path $sourceModPath)) {
    Write-Error "Source file 'zoneshift.wh.cpp' not found in $PSScriptRoot!"
    exit 1
}

# Check for Administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsPrincipal]::WindowsBuiltInRole::Administrator)
if (-not $isAdmin) {
    Write-Host "[INFO] Administrator rights required to write to '$WindhawkDataPath'." -ForegroundColor Yellow
    Write-Host "Relaunching installer with Administrator privileges..." -ForegroundColor Cyan
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($AutoCompile) { $arguments += " -AutoCompile" }
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit 0
}

$modsSourceDir = Join-Path $WindhawkDataPath "ModsSource"
if (-not (Test-Path $modsSourceDir)) {
    Write-Warning "Windhawk ModsSource directory not found at '$modsSourceDir'."
    Write-Host "Creating '$modsSourceDir'..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $modsSourceDir -Force | Out-Null
}

$destModFile = Join-Path $modsSourceDir "local@zoneshift.wh.cpp"
Copy-Item -Path $sourceModPath -Destination $destModFile -Force
Write-Host "[SUCCESS] Copied mod source to:" -ForegroundColor Green
Write-Host "          $destModFile" -ForegroundColor White

if ($AutoCompile) {
    Write-Host "`n[Auto-Compile] Compiling mod with Windhawk toolchain..." -ForegroundColor Cyan
    $compilerBin = "C:\Program Files\Windhawk\Compiler\bin\clang++.exe"
    $includeDir  = "C:\Program Files\Windhawk\Compiler\include"
    $libDir      = "C:\Program Files\Windhawk\Compiler\lib"
    
    # Check Windhawk engine version
    $engineDir = Get-ChildItem "C:\Program Files\Windhawk\Engine" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1

    if ($engineDir -and (Test-Path $compilerBin)) {
        $engine64 = Join-Path $engineDir.FullName "64"
        $engine32 = Join-Path $engineDir.FullName "32"
        $out64Dir = Join-Path $WindhawkDataPath "Engine\Mods\64"
        $out32Dir = Join-Path $WindhawkDataPath "Engine\Mods\32"

        if (-not (Test-Path $out64Dir)) { New-Item -ItemType Directory -Path $out64Dir -Force | Out-Null }
        if (-not (Test-Path $out32Dir)) { New-Item -ItemType Directory -Path $out32Dir -Force | Out-Null }

        $out64 = Join-Path $out64Dir "local@zoneshift_1.0.0.dll"
        $out32 = Join-Path $out32Dir "local@zoneshift_1.0.0.dll"

        Write-Host "  Compiling x86_64..." -ForegroundColor Gray
        & $compilerBin -shared -std=c++20 -target x86_64-w64-mingw32 `
            -DUNICODE -D_UNICODE -DWH_MOD `
            -I $includeDir $sourceModPath -o $out64 `
            -L $libDir -L $engine64 -lwindhawk -ladvapi32

        Write-Host "  Compiling i686 (32-bit)..." -ForegroundColor Gray
        & $compilerBin -shared -std=c++20 -target i686-w64-mingw32 `
            -DUNICODE -D_UNICODE -DWH_MOD `
            -I $includeDir $sourceModPath -o $out32 `
            -L $libDir -L $engine32 -lwindhawk -ladvapi32

        Write-Host "[SUCCESS] Compiled x64 and x86 binaries into Windhawk Engine!" -ForegroundColor Green
    } else {
        Write-Warning "Windhawk Compiler toolchain not found at standard path. Please compile via Windhawk UI."
    }
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Open the Windhawk application (or click the Windhawk tray icon)." -ForegroundColor White
Write-Host "2. Go to 'Developer Channel' or 'Mods'." -ForegroundColor White
Write-Host "3. You will see 'ZoneShift - Per-App Timezone Spoofer' under Local Mods." -ForegroundColor White
Write-Host "4. Open ZoneShift, click 'Compile Mod', and toggle it to ENABLED." -ForegroundColor White
Write-Host "5. Configure your target timezone (e.g. Tokyo, London, EST) in the Settings tab." -ForegroundColor White
Write-Host "6. Any targeted app (Wallpaper Engine, Chrome, etc.) will instantly use the spoofed timezone!" -ForegroundColor Green
