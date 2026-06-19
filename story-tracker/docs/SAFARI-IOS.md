# Safari Web Extension — iOS

Story Tracker extension ships inside the **Personal OS** iOS app at **repo root `ios/`**.

| Component | Path |
|-----------|------|
| Extension JS build | `story-tracker/` (`npm run build:safari`) |
| Native Xcode project | `../ios/` (PersonalOS + StoryTrackerExtension) |
| Hosted app UI | `../frontend/` (loaded in WKWebView) |

## Build flow

```bash
# From story-tracker/
npm run build:safari && npm run sync:safari-ios
npm run build:ios-bridge && npm run sync:ios-bridge

# From repo root
cd ios && xcodegen generate && open PersonalOS.xcodeproj
```

CI / TestFlight: [../docs/CI-IOS.md](../docs/CI-IOS.md)

## Prerequisites

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Apple Developer account (device testing / App Store)
- Node.js (same as extension development)

## Build & sync

From `story-tracker/`:

```bash
npm run build:safari
npm run sync:safari-ios
```

`sync:safari-ios` copies `dist/safari/` into `../ios/StoryTrackerExtension/Resources/`.

Override destination (optional):

```bash
STORY_TRACKER_IOS_RESOURCES=/path/to/Resources npm run sync:safari-ios
```

## Open in Xcode

```bash
cd ios
xcodegen generate
open PersonalOS.xcodeproj
```

1. Select your Team under Signing for **PersonalOS** and **StoryTrackerExtension**.
2. Run **PersonalOS** on a physical iPhone (Safari extensions do not work in Simulator).
3. On device: **Settings → Safari → Extensions** → enable **Story Tracker**.

## Safari limitations

Compared to Firefox/Chrome builds:

- No dynamic content-script registration (`optional_host_permissions` / `scripting.registerContentScripts`).
- Built-in sites from `site-profiles.json` are baked into the static manifest at build time.
- Custom origins discovered at runtime are stored but **not** injected on Safari until a new build adds them to host permissions.
- Auth handoff uses the static connect-page content script (no `scripting.executeScript` fallback).

## Bundle IDs (defaults)

| Target | Bundle ID |
|--------|-----------|
| Container app | `com.personalos.story-tracker` |
| Safari extension | `com.personalos.story-tracker.extension` |

Change these in `ios/project.yml` if you use a different team namespace.

## CI & App Store

See [CI-IOS.md](./CI-IOS.md) for GitHub Actions workflows, required secrets (including **two** App Store provisioning profiles), and Apple Developer setup for Safari tracking on iPhone.
