# Mirror only story-tracker/ from monorepo personal-os to standalone GitHub repo.
# Usage (from personal-os repo root):
#   $env:GITHUB_MIRROR_URL = "https://github.com/YOU/story-tracker.git"
#   $env:GITHUB_MIRROR_TOKEN = "ghp_..."
#   .\story-tracker\scripts\mirror-to-github.ps1
param(
    [string]$MirrorUrl = $env:GITHUB_MIRROR_URL,
    [string]$Token = $env:GITHUB_MIRROR_TOKEN,
    [string]$Branch = $(if ($env:GITHUB_MIRROR_BRANCH) { $env:GITHUB_MIRROR_BRANCH } else { "main" })
)

$ErrorActionPreference = "Stop"
$Prefix = "story-tracker"
$SplitBranch = "story-tracker-mirror-split"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MonorepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

if ([string]::IsNullOrWhiteSpace($MirrorUrl)) {
    Write-Error "Set GITHUB_MIRROR_URL (e.g. https://github.com/you/story-tracker.git)"
}

Set-Location $MonorepoRoot

Write-Host "==> Split subtree $Prefix/"
git subtree split --prefix=$Prefix -b $SplitBranch

$PushUrl = $MirrorUrl
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $PushUrl = $MirrorUrl -replace "^https://", "https://x-access-token:${Token}@"
}

Write-Host "==> Push to GitHub ($Branch)"
git push $PushUrl "${SplitBranch}:${Branch}" --force

Write-Host "Done. Open GitHub repo and verify Actions + push iOS secrets to that repo."
