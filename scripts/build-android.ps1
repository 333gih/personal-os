# Build Personal OS Android (devDebug). Run from repo root or anywhere.
$ErrorActionPreference = "Stop"
$androidRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot "..") "android")).Path

Write-Host "Building from: $androidRoot"
Set-Location $androidRoot

Write-Host "Stopping stale Gradle daemons..."
& .\gradlew.bat --stop 2>$null

Write-Host "Assembling devDebug (no daemon)..."
& .\gradlew.bat :app:assembleDevDebug --no-daemon @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkDir = Join-Path $androidRoot "app\build\outputs\apk\dev\debug"
$apk = Get-ChildItem -Path $apkDir -Filter "*.apk" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($apk) {
    Write-Host "OK: $($apk.FullName)"
} else {
    Write-Host "Build finished. Check app/build/outputs/apk/"
}
