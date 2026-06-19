# CI & App Store — Story Tracker iOS (Safari)

Tham khảo luồng từ `fash-ios-mobile`, rút gọn cho Safari Web Extension (không FCM / Google Sign-In).

## Pipeline build

```text
story-tracker/
  npm run build:safari      → dist/safari/
  npm run sync:safari-ios   → ios/StoryTrackerExtension/Resources/
  ios/
    xcodegen generate
    xcodebuild archive      → Story Tracker.app + embedded extension
    export IPA (app-store)
```

GitHub Actions (repo GitHub `story-tracker` sau mirror):

| Workflow | Mục đích |
|----------|----------|
| **Story Tracker iOS Build** | Compile Simulator, không cần signing secrets |
| **Story Tracker iOS Release** | Archive thiết bị thật + IPA + TestFlight (cần secrets) |

Trigger release: push `main`/`master`, nhánh `release/**` / `releases/**`, tag `story-tracker/ios/v*`, hoặc **Run workflow** thủ công.

## GitHub repo (mirror)

Monorepo `personal-os` trên GitLab; chỉ `story-tracker/` mirror sang GitHub để chạy Actions. Xem [MIRROR-GITHUB.md](./MIRROR-GITHUB.md).

Workflows (trong repo GitHub sau mirror): `.github/workflows/ios-build.yml`, `ios-release.yml`.

## GitHub Secrets (bắt buộc cho Release)

Copy `secrets/ios-release.env.example` → `secrets/ios-release.env`, điền giá trị, rồi:

```powershell
# Windows (từ story-tracker/)
.\scripts\push_github_ios_secrets.ps1
```

```bash
# macOS/Linux
./scripts/push_github_ios_secrets.sh
```

| Secret | Mô tả |
|--------|--------|
| `APPLE_TEAM_ID` | Team ID (Apple Developer → Membership) |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | File `.p12` Apple Distribution (base64) |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | Mật khẩu export `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Profile App Store cho **app** `com.personalos.story-tracker` |
| `IOS_PROVISIONING_PROFILE_SPECIFIER` | Tên profile app (đúng như trên Developer Portal) |
| `IOS_EXTENSION_PROVISIONING_PROFILE_BASE64` | Profile App Store cho **extension** `com.personalos.story-tracker.extension` |
| `IOS_EXTENSION_PROVISIONING_PROFILE_SPECIFIER` | Tên profile extension |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect API (TestFlight) |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Nội dung file `.p8` |

**Khác Fash:** Story Tracker cần **2 provisioning profile** (app + Safari extension). Fash chỉ có 1 target app.

## Checklist Apple Developer (bạn cần setup)

### 1. App IDs (Identifiers)

Tạo **hai** App ID (hoặc đổi bundle trong `ios/project.yml` sang namespace team của bạn):

| Bundle ID | Loại | Capability bắt buộc |
|-----------|------|---------------------|
| `com.personalos.story-tracker` | App | **App Groups** → `group.com.personalos.story-tracker` |
| `com.personalos.story-tracker.extension` | App Extension (Safari Web Extension) | **App Groups** (cùng group), **Safari Web Extensions** |

Trên [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list): **+** → App IDs → chọn capabilities trên cho từng ID.

### 2. App Group

**Identifiers → App Groups** → tạo `group.com.personalos.story-tracker`, gắn vào cả hai App ID.

Entitlements đã có trong repo:

- `ios/StoryTrackerApp/StoryTrackerApp.entitlements`
- `ios/StoryTrackerExtension/StoryTrackerExtension.entitlements`

### 3. Certificates

**Certificates → +** → **Apple Distribution** (hoặc dùng cert hiện có của team). Export `.p12` → đặt vào `secrets/AppleDistribution.p12`.

### 4. Provisioning Profiles (App Store)

Tạo **hai** profile kiểu **App Store**:

1. **Story Tracker App Store** — App ID `com.personalos.story-tracker`, cert Distribution
2. **Story Tracker Extension App Store** — App ID `com.personalos.story-tracker.extension`, cert Distribution

Tải `.mobileprovision` → `secrets/StoryTracker_AppStore.mobileprovision` và `secrets/StoryTrackerExtension_AppStore.mobileprovision`.

Tên profile (`IOS_*_PROVISIONING_PROFILE_SPECIFIER`) phải **khớp chính xác** tên trên portal.

### 5. App Store Connect

1. **My Apps → +** → New App — platform iOS, bundle ID `com.personalos.story-tracker`
2. Metadata: mô tả app container (hướng dẫn bật extension Safari)
3. **Users and Access → Integrations → App Store Connect API** → tạo key (Admin hoặc App Manager), tải `.p8` một lần

### 6. Review / compliance

- Safari extension: khai báo quyền đọc trang web (privacy policy URL)
- Export compliance: thường chọn **No** nếu chỉ HTTPS client
- Ảnh screenshot: container app (onboarding) — extension không có màn hình App Store riêng

## Test trên thiết bị thật

**Simulator không chạy Safari Web Extension đầy đủ.**

Sau cài TestFlight hoặc build Xcode:

1. **Settings → Safari → Extensions** → bật **Story Tracker**
2. **Settings → Safari → Extensions → Story Tracker** → cho phép trên các site
3. Mở Safari → toolbar → bật extension

## Đổi bundle ID / team

Sửa `ios/project.yml`:

- `PRODUCT_BUNDLE_IDENTIFIER` (cả hai target)
- App Group trong entitlements (`group.<your-id>`)
- `Config/ExportOptions-AppStore.plist` (keys trong `provisioningProfiles`)
- Tạo lại App ID + profiles trên Developer Portal

## Chi phí GitHub Actions

Repo **private** → runner `macos-14` tính phí (~10× Linux). Nếu job fail trong **vài giây** với:

> *recent account payments have failed or your spending limit needs to be increased*

→ Sửa tại [GitHub Billing](https://github.com/settings/billing), sau đó **Re-run** workflow. Không phải lỗi Xcode/project.

Repo **public**: macOS runner miễn phí.

## Tham khảo

- Local dev: [SAFARI-IOS.md](./SAFARI-IOS.md)
- iOS layout: [../ios/README.md](../ios/README.md)
- Fash CI gốc: `fash-ios-mobile/docs/CI.md`
