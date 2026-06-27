# Personal OS — Android

Native Android app mirroring the iOS Personal OS shell: **5-tab journal UI**, **WebView login + refresh token handoff**, and **native screens** for Home, Work, Learning, Search, CV, Jobs, Entity detail, and more.

Structure follows [`fash-android-mobile`](../../fash/fash-android-mobile): single module, Jetpack Compose, MVVM, manual DI on `Application`, OkHttp + Moshi, env files → `BuildConfig`.

## Requirements

- Android Studio Ladybug+ / JDK 11+
- Android SDK 35

## Setup

1. Copy env templates (already in `env/`):
   - `env/dev.env` — local/dev frontend URL
   - `env/prod.env` — production frontend URL

2. Open `android/` in Android Studio, sync Gradle, run **`devDebug`** or **`prodDebug`**.

3. **Local frontend (emulator)** — add to `android/local.properties` (gitignored), then rebuild `devDebug`:
   ```properties
   PERSONAL_OS_FE_URL=http://10.0.2.2:3000/dashboard
   ```
   Start the Next.js app on your PC (`frontend/` on port 3000). `10.0.2.2` is the emulator’s alias for host `localhost`.

4. **Production URL / DNS errors** — if login shows `ERR_NAME_NOT_RESOLVED`, the device cannot resolve `personal-os-fe.fashandcurious.com`. Use step 3 for local dev, or fix emulator DNS (cold boot, or `-dns-server 8.8.8.8`).

## Build variants

| Flavor | Application ID | Env file |
|--------|----------------|----------|
| dev | `com.personalos.mobile.dev` | `env/dev.env` |
| prod | `com.personalos.mobile` | `env/prod.env` |

## Architecture

```
com.personalos.mobile/
├── PersonalOSApplication.kt    # Moshi, SessionManager, ApiClient, Repository
├── MainActivity.kt             # Auth gate + 5 tabs + overlays
├── config/AppEnvironment.kt    # BuildConfig → URLs
├── data/auth/                  # Encrypted session, refresh (like iOS SessionManager)
├── data/models/                # JSON models (parity with iOS POS* models)
├── data/repository/            # All /api/mobile/v1 endpoints
├── network/                    # OkHttp + 401 refresh retry
└── ui/                         # Compose screens by feature
```

## Auth flow (same as iOS)

1. `LoginWebScreen` loads `{PERSONAL_OS_FE_URL}/login`
2. After redirect to dashboard/inbox, JS calls `/api/auth/mobile/handoff`
3. Tokens stored in **EncryptedSharedPreferences**
4. Proactive + foreground refresh via `SessionManager`
5. Logout calls `/api/auth/mobile/logout`

## Screens (iOS parity)

| Area | Android | iOS |
|------|---------|-----|
| Tabs | Home, Work, Learning, Search, More | Same |
| Login | WebView + JS bridge | WKWebView |
| Entity detail | Native overlay | fullScreenCover |
| CV Hub | Native sheet | POSCVHubView |
| Job Scout | Native sheet | POSJobScoutView |
| Work import / add | Native | POSWorkImportView |
| Learning lesson | Native | POSLearningLessonView |
| Inbox, Settings, Entertainment | Embedded WebView | WebAppView |
| Interview prep | Native | POSInterviewPrepView |
| Startup board | Native + web | StartupView |

## API surface

All data calls go to `{frontend}/api/mobile/v1/*` with Bearer token — see `PersonalOSRepository.kt` for the full endpoint list (dashboard, entities, CV, jobs, learning, work, startup, search).

## Env variables

| Key | Description |
|-----|-------------|
| `PERSONAL_OS_FE_URL` | Hosted Next.js frontend (origin used for BFF + login WebView) |
| `FASH_AUTH_BASE_URL` | Auth service for FCM registration (future) |
| `FASH_AUTH_FCM_REGISTER_PATH` | FCM register path |

## Gradle wrapper

If `gradlew` is missing, generate from Android Studio or:

```bash
cd android
gradle wrapper --gradle-version 8.13
```

## CI / release

Signing and Play upload can follow the same pattern as `fash-android-mobile` (`env/`, Jenkinsfile, `scripts/`). Not included in v1 scaffold — add when ready for Play Store.
