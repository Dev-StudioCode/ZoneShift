# ==============================================================================
# ZoneShift - Build & Test Verification Script
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  ZoneShift - Build & Test Suite                    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$compiler = "C:\Program Files\Windhawk\Compiler\bin\clang++.exe"
$include  = "C:\Program Files\Windhawk\Compiler\include"
$libDir   = "C:\Program Files\Windhawk\Compiler\lib"

if (-not (Test-Path $compiler)) {
    Write-Error "Windhawk clang++ compiler not found at '$compiler'!"
    exit 1
}

$engineDir = Get-ChildItem "C:\Program Files\Windhawk\Engine" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
$engine64 = Join-Path $engineDir.FullName "64"
$engine32 = Join-Path $engineDir.FullName "32"

$buildDir = Join-Path $PSScriptRoot "build"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

# 1. Compile 64-bit Mod DLL
Write-Host "[1/3] Compiling 64-bit Mod DLL (x86_64)..." -ForegroundColor Yellow
$modSrc = Join-Path $PSScriptRoot "zoneshift.wh.cpp"
$dll64  = Join-Path $buildDir "zoneshift64.dll"
& $compiler -shared -std=c++20 -target x86_64-w64-mingw32 `
    -DUNICODE -D_UNICODE -DWH_MOD `
    -I $include $modSrc -o $dll64 `
    -L $libDir -L $engine64 -lwindhawk -ladvapi32

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Successfully built 64-bit DLL: $dll64" -ForegroundColor Green
} else {
    Write-Error "Failed to compile 64-bit DLL!"
}

# 2. Compile 32-bit Mod DLL
Write-Host "[2/3] Compiling 32-bit Mod DLL (i686)..." -ForegroundColor Yellow
$dll32  = Join-Path $buildDir "zoneshift32.dll"
& $compiler -shared -std=c++20 -target i686-w64-mingw32 `
    -DUNICODE -D_UNICODE -DWH_MOD `
    -I $include $modSrc -o $dll32 `
    -L $libDir -L $engine32 -lwindhawk -ladvapi32

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Successfully built 32-bit DLL: $dll32" -ForegroundColor Green
} else {
    Write-Error "Failed to compile 32-bit DLL!"
}

# 3. Compile & Run Verification Test
Write-Host "[3/3] Compiling & Running Verification Test Harness..." -ForegroundColor Yellow
$testSrc = Join-Path $PSScriptRoot "tests\test_verification.cpp"
$testExe = Join-Path $buildDir "test_verification.exe"
& $compiler -target x86_64-w64-mingw32 $testSrc -o $testExe -ladvapi32

if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Test compiled successfully. Running test output:`n" -ForegroundColor Green
    & $testExe
} else {
    Write-Error "Failed to compile test harness!"
}

Write-Host "`nAll build and test steps completed successfully!" -ForegroundColor Green
