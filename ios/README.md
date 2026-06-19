# Personal OS — iOS native app

Native iOS package at **monorepo root** (`personal-os/ios/`).

| Target | Product | Bundle ID |
|--------|---------|-----------|
| **PersonalOS** | Personal OS (WKWebView → hosted frontend) | `com.personalos.story-tracker` |
| **StoryTrackerExtension** | Story Tracker Safari Web Extension (embedded) | `com.personalos.story-tracker.extension` |

`story-tracker/` builds extension JS only — no `ios/` folder inside story-tracker.

## Quick start

```bash
# From repo root
cd story-tracker
npm ci
npm run build:safari && npm run sync:safari-ios
npm run build:ios-bridge && npm run sync:ios-bridge

cd ../ios
xcodegen generate
open PersonalOS.xcodeproj
```

Sign **both** targets, run on a **physical device**, enable extension in **Settings → Safari → Extensions**.

Frontend URL: `PersonalOSApp/Info.plist` → `PERSONAL_OS_FE_URL` (default: production dashboard).

## CI / TestFlight

GitHub Actions at repo root:

- `.github/workflows/ios-build.yml` — Simulator
- `.github/workflows/ios-release.yml` — IPA + TestFlight

Secrets: [../docs/CI-IOS.md](../docs/CI-IOS.md)

```powershell
# Repo root — after filling secrets/ios-release.env
.\scripts\push_github_ios_secrets.ps1
```

## Layout

```
ios/
  project.yml                 # XcodeGen → PersonalOS.xcodeproj
  PersonalOSApp/              # WKWebView shell
    WebAppView.swift
    PersonalOSAppConfig.swift
    Resources/connect-bridge.js   # from story-tracker build:ios-bridge
  StoryTrackerExtension/        # Safari Web Extension
    Resources/                  # from story-tracker build:safari
  scripts/                      # ci_* for GitHub Actions
  Config/ExportOptions-AppStore.plist
```

## Architecture

- **App**: loads `frontend` (Work, Learning, Startup, Search, Settings, …)
- **Extension**: reading progress on story sites in Safari (unchanged)
- **Auth**: login in app; extension connect via Safari (`/extension/connect`)

See [../story-tracker/docs/SAFARI-IOS.md](../story-tracker/docs/SAFARI-IOS.md) for extension development.
