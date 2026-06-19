# Assemble story-tracker + ios + workflows → push to standalone GitHub repo (TestFlight).
# Usage (from personal-os repo root):
#   .\story-tracker\scripts\mirror-to-github.ps1
param(
    [string]$MirrorUrl = $env:GITHUB_MIRROR_URL,
    [string]$Token = $env:GITHUB_MIRROR_TOKEN,
    [string]$Branch = $(if ($env:GITHUB_MIRROR_BRANCH) { $env:GITHUB_MIRROR_BRANCH } else { "main" })
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MonorepoRoot = Resolve-Path (Join-Path $ScriptDir "..\..")
$RemoteName = "story-tracker-github"

if ([string]::IsNullOrWhiteSpace($MirrorUrl)) {
    $MirrorUrl = "https://github.com/333gih/story-tracker.git"
    Write-Host "Using default GITHUB_MIRROR_URL: $MirrorUrl"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then run: gh auth login"
}

$SourceSha = (git -C $MonorepoRoot rev-parse --short HEAD 2>$null)
if (-not $SourceSha) { $SourceSha = "unknown" }

$Staging = Join-Path ([System.IO.Path]::GetTempPath()) ("personal-os-mirror-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Path $Staging | Out-Null
Write-Host "==> Staging mirror at $Staging (personal-os @ $SourceSha)"

function Copy-Tree($Src, $Dest, [string[]]$Exclude = @()) {
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    Get-ChildItem -Path $Src -Force | ForEach-Object {
        if ($Exclude -contains $_.Name) { return }
        $target = Join-Path $Dest $_.Name
        if ($_.PSIsContainer) {
            Copy-Tree $_.FullName $target $Exclude
        } else {
            Copy-Item $_.FullName $target -Force
        }
    }
}

Copy-Tree (Join-Path $MonorepoRoot "story-tracker") $Staging @("node_modules", "dist", "release", ".git")
Copy-Tree (Join-Path $MonorepoRoot "ios") (Join-Path $Staging "ios") @("DerivedData", "build")

New-Item -ItemType Directory -Force -Path (Join-Path $Staging ".github\workflows") | Out-Null
Copy-Item (Join-Path $MonorepoRoot "ios\github-workflows\*.yml") (Join-Path $Staging ".github\workflows\") -Force

New-Item -ItemType Directory -Force -Path (Join-Path $Staging "docs") | Out-Null
Copy-Item (Join-Path $MonorepoRoot "docs\CI-IOS.md") (Join-Path $Staging "docs\CI-IOS.md") -Force

New-Item -ItemType Directory -Force -Path (Join-Path $Staging "secrets") | Out-Null
$secretsExample = Join-Path $MonorepoRoot "secrets\ios-release.env.example"
if (Test-Path $secretsExample) {
    Copy-Item $secretsExample (Join-Path $Staging "secrets\") -Force
}

Push-Location $Staging
git init -q
git config user.email "mirror@personal-os"
git config user.name "personal-os mirror"
git add -A
git commit -q -m "mirror personal-os@$SourceSha (story-tracker + ios)"
Pop-Location

$PushUrl = $MirrorUrl.TrimEnd('/')
if (-not [string]::IsNullOrWhiteSpace($Token)) {
    $PushUrl = $PushUrl -replace "^https://", "https://x-access-token:${Token}@"
    Write-Host "==> Push with GITHUB_MIRROR_TOKEN"
    git -C $Staging push $PushUrl "HEAD:${Branch}" --force
} else {
    gh auth setup-git | Out-Null
    Write-Host "==> Push via gh auth ($Branch)"
    git -C $Staging push $PushUrl "HEAD:${Branch}" --force
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Remove-Item -Recurse -Force $Staging
Write-Host "Done: $MirrorUrl (branch $Branch)"
Write-Host "TestFlight: gh workflow run `"iOS Release`" -R owner/story-tracker"
