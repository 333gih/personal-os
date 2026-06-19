# Copy downloaded .mobileprovision files into story-tracker/secrets/ with expected names.
# Usage: .\scripts\install-ios-profiles.ps1 [-AppProfile path] [-ExtProfile path]
param(
    [string]$AppProfile = "",
    [string]$ExtProfile = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Secrets = Join-Path $Root "secrets"

function Show-ProfileInfo([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.Encoding]::ASCII.GetString($bytes)
    $name = if ($text -match '<key>Name</key>\s*<string>([^<]+)</string>') { $matches[1] } else { "?" }
    $appId = if ($text -match 'application-identifier</key>\s*<string>([^<]+)</string>') { $matches[1] } else { "?" }
    Write-Host "  $([IO.Path]::GetFileName($Path)) -> Name='$name' AppId='$appId'"
}

function Find-RecentProfiles() {
    $dirs = @(
        [Environment]::GetFolderPath("UserProfile") + "\Downloads",
        [Environment]::GetFolderPath("Desktop")
    )
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            Get-ChildItem $dir -Filter "*.mobileprovision" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
        }
    }
}

New-Item -ItemType Directory -Force -Path $Secrets | Out-Null

if (-not $AppProfile -or -not $ExtProfile) {
    $found = @(Find-RecentProfiles | Select-Object -Unique FullName)
    if ($found.Count -ge 2 -and -not $AppProfile -and -not $ExtProfile) {
        Write-Host "Found $($found.Count) profile(s) in Downloads/Desktop:"
        foreach ($p in $found) { Show-ProfileInfo $p.FullName }
        Write-Host ""
        Write-Host "Pass explicitly: -AppProfile <path> -ExtProfile <path>"
        exit 1
    }
}

$destApp = Join-Path $Secrets "Story_Tracker_App_Store.mobileprovision"
$destExt = Join-Path $Secrets "Story_Tracker_Extension_App_Store.mobileprovision"

if ($AppProfile) {
    Copy-Item $AppProfile $destApp -Force
    Write-Host "App profile -> $destApp"
    Show-ProfileInfo $destApp
}
if ($ExtProfile) {
    Copy-Item $ExtProfile $destExt -Force
    Write-Host "Extension profile -> $destExt"
    Show-ProfileInfo $destExt
}

if ((Test-Path $destApp) -and (Test-Path $destExt)) {
    Write-Host ""
    Write-Host "Next: .\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/story-tracker"
} else {
    Write-Warning "Still missing one or both profiles under secrets/"
}
