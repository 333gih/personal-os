# Trigger Android Release → Google Play closed testing (POS-closed).
param(
    [string]$Repo = "333gih/personal-os",
    [string]$Ref = "releases/1.0",
    [string]$PlayTrack = "POS-closed"
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "Install GitHub CLI: https://cli.github.com/ then gh auth login"
}

Write-Host "Trigger Android Release on $Repo @ $Ref → track $PlayTrack"
gh workflow run "Android Release" -R $Repo --ref $Ref -f upload_play=true -f play_track=$PlayTrack
Start-Sleep -Seconds 3
gh run list -R $Repo --workflow "Android Release" --limit 1
Write-Host ""
Write-Host "Play Console checklist: docs/PLAY-CLOSED-TESTING-VI.md"
Write-Host "If Package not found → create app com.personalos.mobile on Play Console first."
