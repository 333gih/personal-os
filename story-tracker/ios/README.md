# Story Tracker — iOS Safari wrapper

Standalone Xcode project for the Safari Web Extension on iPhone/iPad.

**Build & release:** GitHub Actions only — no local Xcode required. See [../docs/CI-IOS.md](../docs/CI-IOS.md).

## CI pipeline (GitHub Actions)

| Workflow | Trigger | Signing |
|----------|---------|---------|
| `iOS Build` | push `main` | None (Simulator compile) |
| `iOS Release` | **Run workflow** / tag `ios/v*` / `release/**` | Apple Distribution + 2 profiles |

Flow on each release job:

1. `npm run build:safari` + `sync:safari-ios`
2. `xcodegen generate` (from `project.yml`)
3. `xcodebuild archive` + export IPA + TestFlight

Bundle IDs (must match Apple Developer):

| Target | Bundle ID |
|--------|-----------|
| App | `com.personalos.story-tracker` |
| Extension | `com.personalos.story-tracker.extension` |
| App Group | `group.com.personalos.story-tracker` |
## Quick start

```bash
# From story-tracker/
npm run build:safari
npm run sync:safari-ios

cd ios
xcodegen generate
open StoryTracker.xcodeproj
```

Sign both targets, run on a **physical device**, then enable the extension in **Settings → Safari → Extensions**.

See [../docs/SAFARI-IOS.md](../docs/SAFARI-IOS.md) for details.

## Layout

```
ios/
  project.yml                 # XcodeGen spec
  StoryTrackerApp/            # Thin container app (onboarding UI)
  StoryTrackerExtension/      # Safari Web Extension target
    Resources/                # Populated by npm run sync:safari-ios (gitignored)
```

`Resources/` is generated from `dist/safari/` — do not edit by hand.

## CI / App Store

GitHub Actions workflows live in **this folder** (`.github/workflows/`) — dùng sau khi mirror sang repo GitHub riêng. Xem [../docs/MIRROR-GITHUB.md](../docs/MIRROR-GITHUB.md).

1. Push secrets: copy `secrets/ios-release.env.example` → `secrets/ios-release.env`, then `.\scripts\push_github_ios_secrets.ps1`
2. Full checklist (2 provisioning profiles, App Groups, TestFlight): [../docs/CI-IOS.md](../docs/CI-IOS.md)
