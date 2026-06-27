# Download latest prod AAB artifact from GitHub Actions (for manual Play upload).
param(
    [string]$Repo = "333gih/personal-os",
    [string]$OutDir = "dist/android"
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then gh auth login"
}

$runId = gh run list -R $Repo --workflow "Android Release" --limit 1 --json databaseId,conclusion -q `
    '.[0] | select(.conclusion=="success" or .conclusion=="failure") | .databaseId'
if (-not $runId) {
    Write-Error "No Android Release run found on $Repo"
}

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$dest = Join-Path $Root ($OutDir -replace "/", "\")
New-Item -ItemType Directory -Force -Path $dest | Out-Null

Write-Host "Downloading artifacts from run $runId ..."
Push-Location $dest
try {
    gh run download $runId -R $Repo
    Get-ChildItem -Recurse -Filter "*.aab" | ForEach-Object { Write-Host "AAB: $($_.FullName)" }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Manual upload: Play Console → Testing → Closed testing → POS-closed → Create release"
