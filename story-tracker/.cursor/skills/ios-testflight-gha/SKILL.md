---
name: story-tracker-ios-testflight-gha
description: >-
  Build Story Tracker Safari iOS via GitHub Actions and ship to TestFlight without
  local Xcode. Use when setting up iOS CI, mirroring story-tracker to GitHub,
  provisioning profiles, GitHub secrets, fixing Actions failures, or TestFlight upload.
---

# Story Tracker iOS → TestFlight (GitHub Actions only)

No local Xcode. Flow: GitLab monorepo `personal-os/story-tracker/` → subtree mirror → GitHub repo → Actions.

## Architecture

```text
personal-os/story-tracker/  --git subtree split-->  github.com/.../story-tracker (root)
                                                          |
                    npm build:safari + sync:safari-ios + xcodegen + xcodebuild
                                                          |
                                                    IPA → TestFlight
```

| Item | Value |
|------|--------|
| Team ID | `4JA75SPHD9` |
| App bundle | `com.personalos.story-tracker` |
| Extension bundle | `com.personalos.story-tracker.extension` |
| App Group | `group.com.personalos.story-tracker` |
| GitHub repo | `333gih/story-tracker` |

## Apple Developer (portal has NO Safari checkbox)

1. **App Group** first: `group.com.personalos.story-tracker`
2. **App ID** `com.personalos.story-tracker` — capability: **App Groups only**
3. **App ID** `com.personalos.story-tracker.extension` — **App Groups only** (Safari = `NSExtensionPointIdentifier` in Info.plist, not portal)
4. **Two App Store profiles** (Distribution → App Store Connect):
   - `Story Tracker App Store` → `secrets/Story_Tracker_App_Store.mobileprovision`
   - `Story Tracker Extension App Store` → `secrets/Story_Tracker_Extension_App_Store.mobileprovision`
5. Profile **names** must match `IOS_*_PROVISIONING_PROFILE_SPECIFIER` in `secrets/ios-release.env` exactly.

Fash `Fash_App_Store.mobileprovision` **cannot** be reused (wrong bundle `com.pc.fash-ios-mobile`).

## GitHub secrets (10)

Push from `story-tracker/` (never commit `ios-release.env` or `.mobileprovision`):

```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/story-tracker
```

Required: `APPLE_TEAM_ID`, cert base64 + password, **two** profile base64 + specifiers, App Store Connect API (3).

Script skips missing `.mobileprovision` with warning — re-run after files exist.

## Mirror to GitHub

**Do NOT** use expired/wrong `GITHUB_MIRROR_TOKEN`.

```powershell
cd D:\Project\personal-os
gh auth login   # account fashandcurious14052026-dotcom
.\story-tracker\scripts\mirror-to-github.ps1
```

Uses `gh auth setup-git` when token unset. GitLab CI needs valid `GITHUB_MIRROR_TOKEN` (fine-grained PAT, Contents write).

## Workflows

| Workflow | Trigger | Signing |
|----------|---------|---------|
| `iOS Build` | push `main` | None (Simulator) |
| `iOS Release` | **Run workflow** / `ios/v*` tag / `release/**` | Full (2 profiles) |

Release command:

```powershell
gh workflow run "iOS Release" -R fashandcurious14052026-dotcom/story-tracker -f upload_testflight=true
```

Monitor:

```powershell
gh run list -R fashandcurious14052026-dotcom/story-tracker --limit 5
gh run view <run-id> -R fashandcurious14052026-dotcom/story-tracker
gh run watch <run-id> -R fashandcurious14052026-dotcom/story-tracker
```

After fix: mirror → re-run workflow (secrets already on GitHub unless profiles changed).

## Known failures (fix before blaming Xcode/project)

### 1. Billing — macOS job never starts (~3–7s failure)

**Message:** `recent account payments have failed or your spending limit needs to be increased`

**Cause:** Repo is **private**; `macos-14` costs ~10× Linux minutes.

**Fix:** https://github.com/settings/billing — fix payment, raise spending limit, or make repo **public** (macOS free on public repos).

**Not fixable in code.** Re-run workflow after billing OK.

### 2. Mirror auth failed

**Message:** `Invalid username or token. Password authentication is not supported`

**Fix:** Unset bad `GITHUB_MIRROR_TOKEN`; use `gh auth login` + updated `mirror-to-github.ps1`.

### 3. push_github_ios_secrets — file not found

**Cause:** `ios-release.env` paths ≠ actual filenames (e.g. `Story_Tracker_App_Store.mobileprovision` vs `StoryTracker_AppStore.mobileprovision`).

**Fix:** Align `IOS_PROVISIONING_PROFILE_PATH` in `ios-release.env`.

### 4. App Group mismatch on archive (exit 65)

**Message:** `Provisioning profile doesn't match the entitlements file's value for com.apple.security.application-groups`

**Cause:** Extension profile missing `group.com.personalos.story-tracker` while entitlements request it (or vice versa).

**Fix:** Regenerate **both** profiles with App Group on portal, **or** remove unused App Groups from entitlements (Story Tracker Safari handler does not use shared container).

### 5. Duplicate Resources (index.js / index.html)

**Cause:** Xcode flattens `Resources/` — use `type: folder` in `ios/project.yml` for extension resources.

### 6. TestFlight 90382

Daily upload limit — archive OK; re-run after ~24h.

## Agent fix loop

1. `gh run list` → find failed `iOS Release` or `iOS Build`
2. Read annotations; if billing → tell user billing URL, stop code changes
3. If macOS ran: `gh run view <id> --log-failed`
4. Fix in `personal-os/story-tracker/`, commit GitLab, `mirror-to-github.ps1`, re-trigger workflow
5. Document new failure mode in this skill

## Post-TestFlight (device)

Settings → Safari → Extensions → enable **Story Tracker** (Simulator insufficient).

## Reference files

- `docs/CI-IOS.md`, `docs/MIRROR-GITHUB.md`, `docs/SAFARI-IOS.md`
- `ios/project.yml`, `ios/Config/ExportOptions-AppStore.plist`
- `.github/workflows/ios-build.yml`, `ios-release.yml`
