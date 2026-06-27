# Personal OS Android — Thử nghiệm khép kín (Google Play)

CI đã **build + ký AAB thành công**. Upload Play fail vì app **`com.personalos.mobile` chưa được tạo** trên Play Console (lỗi: `Package not found`).

Google **không cho tạo app mới qua API** — bạn cần tạo app trên Console **một lần** (~10 phút), sau đó GitHub Actions upload tự động được.

## Thông tin app

| Mục | Giá trị |
|-----|---------|
| Package (prod) | `com.personalos.mobile` |
| Tên app | Personal OS |
| Upload key alias | `key0` (cùng keystore Fash) |
| Upload key SHA-1 | `5C:E7:3A:D0:24:DA:46:3B:63:9A:23:90:6E:A5:1A:A5:D9:50:20:09` |
| Service account CI | `play-publisher@fash-3526e.iam.gserviceaccount.com` |
| Track CI (nhánh `releases/*`) | `POS-closed` |
| GitHub repo | [333gih/personal-os](https://github.com/333gih/personal-os) |

## Bước 1 — Tạo app trên Play Console

1. Mở [Google Play Console](https://play.google.com/console).
2. **Create app** → tên **Personal OS**, ngôn ngữ mặc định, app/game, free/paid.
3. Khi được hỏi package name / app id: **`com.personalos.mobile`** (phải khớp Gradle, không đổi sau này).

## Bước 2 — Quyền service account

1. **Users and permissions** → tìm `play-publisher@fash-3526e.iam.gserviceaccount.com`.
2. Đảm bảo account có quyền trên app **Personal OS** (Release manager / Admin app).
3. Nếu mới tạo app: **Invite user** → email service account → quyền release.

## Bước 3 — Kênh thử nghiệm khép kín

1. **Testing → Closed testing** → **Create track**.
2. Đặt tên track (Track name / ID): **`POS-closed`** — phải khớp workflow CI.
3. (Tuỳ chọn) Track khác: chạy workflow thủ công với `play_track=internal` hoặc `alpha`.

## Bước 4 — Upload bản đầu (chọn 1 cách)

### Cách A — Tự động qua GitHub Actions (khuyến nghị)

Sau khi app đã tạo trên Console:

```powershell
cd d:\Project\personal-os
.\scripts\trigger_android_play_release.ps1
```

Hoặc:

```powershell
gh workflow run "Android Release" -R 333gih/personal-os `
  --ref releases/1.0.1 `
  -f upload_play=true `
  -f play_track=POS-closed
```

Theo dõi: [Actions → Android Release](https://github.com/333gih/personal-os/actions/workflows/android-release.yml)

### Cách B — Upload AAB thủ công lần đầu

```powershell
.\scripts\download_android_aab.ps1
```

1. Play Console → **Testing → Closed testing → POS-closed → Create new release**.
2. Upload file `app-prod-release.aab` vừa tải.
3. Điền release notes → **Review release → Start rollout**.

Lần sau CI upload API sẽ chạy được.

## Bước 5 — Checklist bắt buộc trước khi publish closed

Play Console → **Dashboard** → hoàn thành các mục đỏ:

- Store listing (tên, mô tả ngắn, icon 512×512, feature graphic nếu cần)
- Content rating ( khảo sát IARC)
- Privacy policy URL (có thể dùng URL frontend/dashboard)
- Data safety form
- Target audience
- App access (login required → mô tả demo account nếu cần)

## Bước 6 — Thêm tester

**Closed testing → POS-closed → Testers**:

- Tạo danh sách email, hoặc
- Dùng Google Group

Tester mở link opt-in từ email → cài app từ Play Store.

## Release tiếp theo

1. Tăng `versionCode` trong `android/app/build.gradle.kts`.
2. Push nhánh `releases/x.y.z` → mirror GitHub.
3. Workflow tự upload track `POS-closed`.

```kotlin
versionCode = 3   // bắt buộc tăng mỗi lần upload
versionName = "1.0.2"
```

## Lỗi thường gặp

| Lỗi | Cách xử lý |
|-----|------------|
| `Package not found: com.personalos.mobile` | Chưa tạo app trên Play Console (bước 1) |
| Track `POS-closed` not found | Tạo track closed testing tên `POS-closed` (bước 3) |
| Wrong signing key | Keystore phải alias `key0`, SHA-1 khớp bảng trên |
| `versionCode already used` | Tăng `versionCode` trong `build.gradle.kts` |
| API disabled | GCP → bật **Google Play Android Developer API** (project `fash-3526e`) |
