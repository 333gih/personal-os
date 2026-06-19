# Mirror story-tracker → GitHub (standalone repo)

Monorepo `personal-os` nằm trên **GitLab**. Chỉ thư mục `story-tracker/` được đẩy lên **một repo GitHub riêng** để chạy GitHub Actions (iOS build, TestFlight).

GitLab **không** mirror được subdirectory — dùng `git subtree split`.

## Luồng

```text
personal-os (GitLab)
  story-tracker/  ──subtree split──►  github.com/YOU/story-tracker (main)
                                              │
                                              ▼
                                        GitHub Actions (ios-build, ios-release)
```

## Bước 1 — Tạo repo GitHub

1. GitHub → **New repository** → `story-tracker`
2. **Không** tích README / .gitignore (repo trống)
3. Copy URL: `https://github.com/YOU/story-tracker.git`

## Bước 2 — Token

Fine-grained PAT: quyền **Contents** read/write trên repo `story-tracker`.

## Bước 3 — Mirror thủ công (lần đầu)

Từ **root** monorepo `personal-os/`:

```powershell
$env:GITHUB_MIRROR_URL = "https://github.com/YOU/story-tracker.git"
$env:GITHUB_MIRROR_TOKEN = "github_pat_..."
.\story-tracker\scripts\mirror-to-github.ps1
```

```bash
export GITHUB_MIRROR_URL=https://github.com/YOU/story-tracker.git
export GITHUB_MIRROR_TOKEN=github_pat_...
bash story-tracker/scripts/mirror-to-github.sh
```

Repo GitHub sẽ có **root = nội dung `story-tracker/`** (package.json, ios/, `.github/workflows/`, …).

## Bước 4 — Mirror tự động (GitLab CI)

File `.gitlab-ci.yml` ở root monorepo đã có job `mirror-story-tracker-github`.

GitLab → **Settings → CI/CD → Variables**:

| Variable | Giá trị |
|----------|---------|
| `GITHUB_MIRROR_URL` | `https://github.com/YOU/story-tracker.git` |
| `GITHUB_MIRROR_TOKEN` | PAT (masked) |

Mỗi push `main` có thay đổi trong `story-tracker/**` → job push lên GitHub.

## Bước 5 — Secrets trên GitHub

Secrets iOS đẩy vào **repo GitHub `story-tracker`**, không phải GitLab:

```powershell
cd story-tracker
.\scripts\push_github_ios_secrets.ps1 -Repo YOU/story-tracker
```

## Workflows

Trong repo GitHub (sau mirror):

| File | Mục đích |
|------|----------|
| `.github/workflows/ios-build.yml` | Compile Simulator |
| `.github/workflows/ios-release.yml` | IPA + TestFlight |

Tag release trên GitHub repo: `ios/v1.1.0` (không prefix `story-tracker/`).

## Lưu ý

- `git subtree split` cần **full git history** — CI dùng `GIT_DEPTH: 0`.
- Push mirror dùng `--force` trên nhánh `main` GitHub (repo mirror chỉ nhận subtree, không commit trực tiếp trên GitHub).
- Sửa code trong monorepo `personal-os/story-tracker/`, mirror lại — không sửa trên GitHub.
- Workflow ở `personal-os/.github/workflows/story-tracker-*` **không** đi theo mirror; canonical là `story-tracker/.github/workflows/`.

Chi tiết iOS / App Store: [CI-IOS.md](./CI-IOS.md).
