# Push Android CI secrets from secrets/android-release.env to GitHub Actions.
# Usage: .\scripts\push_github_android_secrets.ps1 [-Repo owner/personal-os]
param(
    [string]$EnvFile = "secrets/android-release.env",
    [string]$Repo = "333gih/personal-os"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) not found. Install: https://cli.github.com/ then run: gh auth login"
}

if (-not (Test-Path $EnvFile)) {
    Write-Error "Missing $EnvFile - copy secrets/android-release.env.example and fill in."
}

function Read-DotEnv([string]$Path) {
    $map = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $eq = $line.IndexOf("=")
        if ($eq -lt 1) { return }
        $key = $line.Substring(0, $eq).Trim()
        $val = $line.Substring($eq + 1).Trim()
        $map[$key] = $val
    }
    return $map
}

function Read-RepoFile([string]$RelativePath) {
    $full = Join-Path $Root ($RelativePath -replace "/", "\")
    if (-not (Test-Path $full)) { Write-Error "File not found: $full" }
    return Get-Content -Raw -Encoding UTF8 $full
}

function To-Base64File([string]$RelativePath) {
    $full = Join-Path $Root ($RelativePath -replace "/", "\")
    if (-not (Test-Path $full)) { return $null }
    return [Convert]::ToBase64String([IO.File]::ReadAllBytes($full))
}

function Read-RepoFileOptional([string]$RelativePath) {
    if ([string]::IsNullOrWhiteSpace($RelativePath)) { return $null }
    $full = Join-Path $Root ($RelativePath -replace "/", "\")
    if (-not (Test-Path $full)) { Write-Host "skip file (not found): $RelativePath"; return $null }
    return Get-Content -Raw -Encoding UTF8 $full
}

$envMap = Read-DotEnv $EnvFile
$Repo = $Repo.Trim().TrimEnd('\', '/')
$repoArg = @("-R", $Repo)

function Set-GhSecret([string]$Name, [string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { Write-Host "skip $Name (empty)"; return }
    Write-Host "set  $Name"
    $Value | gh secret set $Name @repoArg
}

$devEnv = $envMap["ANDROID_DEV_ENV"]
if ([string]::IsNullOrWhiteSpace($devEnv) -and $envMap["ANDROID_DEV_ENV_PATH"]) {
    $devEnv = Read-RepoFile $envMap["ANDROID_DEV_ENV_PATH"]
}
Set-GhSecret "ANDROID_DEV_ENV" $devEnv

$prodEnv = $envMap["ANDROID_PROD_ENV"]
if ([string]::IsNullOrWhiteSpace($prodEnv) -and $envMap["ANDROID_PROD_ENV_PATH"]) {
    $prodEnv = Read-RepoFile $envMap["ANDROID_PROD_ENV_PATH"]
}
Set-GhSecret "ANDROID_PROD_ENV" $prodEnv

$keystoreB64 = $envMap["ANDROID_UPLOAD_KEYSTORE_BASE64"]
if ([string]::IsNullOrWhiteSpace($keystoreB64) -and $envMap["ANDROID_UPLOAD_KEYSTORE_PATH"]) {
    $keystoreB64 = To-Base64File $envMap["ANDROID_UPLOAD_KEYSTORE_PATH"]
}
Set-GhSecret "ANDROID_UPLOAD_KEYSTORE_BASE64" $keystoreB64
Set-GhSecret "ANDROID_UPLOAD_KEYSTORE_PASSWORD" $envMap["ANDROID_UPLOAD_KEYSTORE_PASSWORD"]
Set-GhSecret "ANDROID_UPLOAD_KEY_ALIAS" $envMap["ANDROID_UPLOAD_KEY_ALIAS"]
Set-GhSecret "ANDROID_UPLOAD_KEY_PASSWORD" $envMap["ANDROID_UPLOAD_KEY_PASSWORD"]

$playJson = $envMap["GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"]
if ([string]::IsNullOrWhiteSpace($playJson) -and $envMap["GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"]) {
    $playJson = Read-RepoFileOptional $envMap["GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH"]
}
Set-GhSecret "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON" $playJson
Set-GhSecret "PLAY_EXPECTED_UPLOAD_SHA1" $envMap["PLAY_EXPECTED_UPLOAD_SHA1"]
Set-GhSecret "PLAY_TRACK" $envMap["PLAY_TRACK"]

Write-Host ""
Write-Host "Done. Verify: gh secret list -R $Repo"
Write-Host "Release: gh workflow run `"Android Release`" -R $Repo -f upload_play=true -f play_track=POS-closed"
