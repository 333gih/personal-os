# Mirror personal-os → GitHub (story-tracker repo + ios/)

Monorepo **GitLab** `personal-os` → repo GitHub **`story-tracker`** (root = extension + `ios/`).

## Luồng TestFlight (giữ như cũ)

```text
personal-os (GitLab)
  story-tracker/  ──┐
  ios/              ──┼── mirror-to-github ──► github.com/.../story-tracker
  .github (monorepo)  │                              │
                      │                              ▼
                      │                    GitHub Actions ios-release
                      │                              │
                      └──────────────────────► TestFlight
```

Script `story-tracker/scripts/mirror-to-github.*` **ghép**:

- Nội dung `story-tracker/` → root repo GitHub
- `ios/` → `ios/` trên GitHub
- `ios/github-workflows/*.yml` → `.github/workflows/`

## Mirror thủ công

```powershell
cd D:\Project\personal-os
gh auth login
.\story-tracker\scripts\mirror-to-github.ps1
```

```bash
export GITHUB_MIRROR_URL=https://github.com/fashandcurious14052026-dotcom/story-tracker.git
bash story-tracker/scripts/mirror-to-github.sh
```

## Secrets (repo GitHub, không GitLab)

```powershell
# Dùng secrets local trong story-tracker/secrets/ (không commit)
cd story-tracker
.\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/story-tracker
```

Hoặc từ repo root (nếu đã copy env):

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo owner/story-tracker
```

## Trigger TestFlight

```powershell
gh workflow run "iOS Release" -R fashandcurious14052026-dotcom/story-tracker -f upload_testflight=true
```

Tag: `ios/v1.4.0` trên repo GitHub.

Chi tiết: [CI-IOS.md](../CI-IOS.md)
