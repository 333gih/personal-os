# Story Tracker — iOS Safari wrapper

Standalone Xcode project for the Safari Web Extension on iPhone/iPad. Lives inside `personal-os/story-tracker` and is **not** tied to other mobile apps.

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
