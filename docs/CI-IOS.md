# CI & App Store — Personal OS iOS

Monorepo layout:

| Path | Role |
|------|------|
| `ios/` | Native **Personal OS** app (WKWebView) + embedded **Story Tracker** Safari extension |
| `story-tracker/` | Extension JS build only (`build:safari`, `build:ios-bridge`) |
| `frontend/` | Hosted web UI loaded by the iOS app |
| `.github/workflows/ios-*.yml` | GitHub Actions (Simulator + TestFlight) |

## Pipeline build

```text
story-tracker/
  npm run build:safari      → dist/safari/
  npm run sync:safari-ios   → ../ios/StoryTrackerExtension/Resources/
  npm run build:ios-bridge  → dist/ios-bridge/connect-bridge.js
  npm run sync:ios-bridge   → ../ios/PersonalOSApp/Resources/

ios/
  xcodegen generate
  xcodebuild archive      → Personal OS.app + embedded Story Tracker extension
  export IPA (app-store)  → PersonalOS.ipa
```

## GitHub Actions

| Workflow | Mục đích |
|----------|----------|
| **iOS Build** | Compile Simulator, không cần signing secrets |
| **iOS Release** | Archive thiết bị thật + IPA + TestFlight (cần secrets) |

Trigger release: nhánh `release/**` / `releases/**`, tag `ios/v*`, hoặc **Run workflow** thủ công.

Repo GitHub: monorepo `personal-os` (không cần mirror story-tracker riêng cho iOS).

## GitHub Secrets (bắt buộc cho Release)

Copy `secrets/ios-release.env.example` → `secrets/ios-release.env`, điền giá trị, rồi:

```powershell
# Windows (từ repo root)
.\scripts\push_github_ios_secrets.ps1
```

```bash
# macOS/Linux
./scripts/push_github_ios_secrets.sh
```

Tùy chọn chỉ định repo: `.\scripts\push_github_ios_secrets.ps1 -Repo owner/personal-os`

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

**Lưu ý:** Cần **2 provisioning profile** (app container + Safari extension).

## Checklist Apple Developer

### App IDs

| Bundle ID | Loại | Capability |
|-----------|------|------------|
| `com.personalos.story-tracker` | App (Personal OS) | **App Groups** → `group.com.personalos.story-tracker` |
| `com.personalos.story-tracker.extension` | Safari Web Extension | **App Groups**, **Safari Web Extensions** |

Entitlements:

- `ios/PersonalOSApp/PersonalOSApp.entitlements`
- `ios/StoryTrackerExtension/StoryTrackerExtension.entitlements`

### Provisioning Profiles (App Store)

1. **Personal OS App Store** — `com.personalos.story-tracker`
2. **Story Tracker Extension App Store** — `com.personalos.story-tracker.extension`

Lưu vào `secrets/` và cập nhật `secrets/ios-release.env`.

### App Store Connect

- App record bundle ID: `com.personalos.story-tracker` (display name: **Personal OS**)
- Extension không có listing riêng — embedded trong app

## Local build

```bash
# Repo root
cd story-tracker
npm ci
npm run build:safari && npm run sync:safari-ios
npm run build:ios-bridge && npm run sync:ios-bridge

cd ../ios
xcodegen generate
open PersonalOS.xcodeproj
```

Cấu hình frontend URL: `ios/PersonalOSApp/Info.plist` → `PERSONAL_OS_FE_URL`.

## Test trên thiết bị

1. Cài app (TestFlight hoặc Xcode)
2. Đăng nhập Personal OS trong app
3. **Settings → Safari → Extensions** → bật **Story Tracker**
4. Settings trong app → **Connect extension in Safari**

## Chi phí GitHub Actions

Repo **private** → runner `macos-26` tính phí. Sửa billing tại https://github.com/settings/billing nếu job fail sớm.

## Tham khảo

- `ios/README.md` — layout Xcode
- `story-tracker/docs/SAFARI-IOS.md` — extension dev
