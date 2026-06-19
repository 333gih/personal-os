# Mirror only story-tracker/ from monorepo personal-os to standalone GitHub repo.
# Usage (from personal-os repo root):
#   $env:GITHUB_MIRROR_URL = "https://github.com/fashandcurious14052026-dotcom/story-tracker.git"
#   .\story-tracker\scripts\mirror-to-github.ps1
#
# Auth (pick one):
#   A) gh auth login  (recommended — script uses gh credential helper)
#   B) $env:GITHUB_MIRROR_TOKEN = "github_pat_..." or "ghp_..."
param(
    [string]$MirrorUrl = $env:GITHUB_MIRROR_URL,
    [string]$Token = $env:GITHUB_MIRROR_TOKEN,
    [string]$Branch = $(if ($env:GITHUB_MIRROR_BRANCH) { $env:GITHUB_MIRROR_BRANCH } else { "main" })
)

$ErrorActionPreference = "Stop"
$Prefix = "story-tracker"
$SplitBranch = "story-tracker-mirror-split"
$RemoteName = "story-tracker-github"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MonorepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")

if ([string]::IsNullOrWhiteSpace($MirrorUrl)) {
    $MirrorUrl = "https://github.com/333gih/story-tracker.git"
    Write-Host "Using default GITHUB_MIRROR_URL: $MirrorUrl"
}

Set-Location $MonorepoRoot

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then run: gh auth login"
}

$ghUser = (gh api user -q .login 2>$null)
if (-not $ghUser) {
    Write-Error "gh not authenticated. Run: gh auth login"
}
Write-Host "GitHub account: $ghUser"

Write-Host "==> Split subtree $Prefix/"
git subtree split --prefix=$Prefix -b $SplitBranch

$PushUrl = $MirrorUrl.TrimEnd('/')
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    # Explicit PAT (GitLab CI or manual)
    if ($PushUrl -notmatch '^https://') {
        Write-Error "GITHUB_MIRROR_URL must be https://github.com/owner/repo.git"
    }
    $PushUrl = $PushUrl -replace "^https://", "https://x-access-token:${Token}@"
    Write-Host "==> Push with GITHUB_MIRROR_TOKEN"
    git push $PushUrl "${SplitBranch}:${Branch}" --force
} else {
    gh auth setup-git | Out-Null
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    git remote remove $RemoteName *> $null
    $ErrorActionPreference = $prevEap
    git remote add $RemoteName $PushUrl
    Write-Host "==> Push via gh auth ($Branch)"
    git push $RemoteName "${SplitBranch}:${Branch}" --force
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $ErrorActionPreference = "SilentlyContinue"
    git remote remove $RemoteName *> $null
    $ErrorActionPreference = $prevEap
}

Write-Host "Done: $PushUrl (branch $Branch)"
Write-Host "Actions: https://github.com/333gih/story-tracker/actions"
