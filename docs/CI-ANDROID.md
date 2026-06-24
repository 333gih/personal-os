# Personal OS — Android CI & Google Play

Same pattern as [fash-android-mobile](https://gitlab.com/fash3194512/fash-android-mobile): GitLab origin → mirror GitHub → GitHub Actions → Play Console.

## Architecture

```text
GitLab personal-os1/personal-os
  └── push main / releases/*
        └── scripts/mirror-monorepo-to-github.sh
                  └── GitHub fashandcurious14052026-dotcom/personal-os
                        ├── Android Release → AAB → Play (closed: POS-closed)
                        └── iOS Release     → IPA → TestFlight
```

## Workflows

| Workflow | Trigger | Output |
|----------|---------|--------|
| **Android Build** | `develop`, PR | dev APK artifact |
| **Android Release** | `releases/**`, `main`, tag `android/v*` | prod AAB + Play upload |
| **iOS Release** | `releases/**`, tag `ios/v*` | IPA + TestFlight |

### Play track mapping (Android Release)

| Branch | Track |
|--------|-------|
| `releases/**`, `release/**` | `POS-closed` (closed testing — create this track in Play Console) |
| `main` | `production` |
| Manual | choose track |

Package: **`com.personalos.mobile`**

## One-time setup

### 1. Google Play Console

1. Create app **Personal OS** with package `com.personalos.mobile`.
2. Complete store listing checklist (content rating, privacy, etc.).
3. **Setup → API access** → link GCP project → create service account → grant **Release manager**.
4. Download service account JSON → `secrets/play-service-account.json` (gitignored).
5. **Closed testing** → create track **`POS-closed`** (or use `internal` in workflow dispatch).
6. Generate upload keystore:
   ```powershell
   keytool -genkey -v -keystore secrets/personal-os-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```
7. Register upload key SHA-1 in Play Console (App signing → Upload key).

### 2. GitHub repo

Create empty repo `personal-os` on GitHub (org `fashandcurious14052026-dotcom` or your org).

### 3. GitHub secrets

```powershell
copy secrets\android-release.env.example secrets\android-release.env
# Fill passwords, paths, PLAY_EXPECTED_UPLOAD_SHA1 after keytool -list -keystore ...

.\scripts\push_github_android_secrets.ps1 -Repo fashandcurious14052026-dotcom/personal-os
```

Also push iOS secrets (see [docs/CI-IOS.md](CI-IOS.md)):
```powershell
.\scripts\push_github_ios_secrets.ps1 -Repo fashandcurious14052026-dotcom/personal-os
```

### 4. GitLab mirror (optional auto)

GitLab CI variable `GITHUB_MIRROR_URL` = `https://github.com/OWNER/personal-os.git`  
`GITHUB_MIRROR_TOKEN` = fine-grained PAT with Contents write.

On push to `main` (android/ios/workflow changes), job `mirror-monorepo-github` runs.

Manual mirror:
```powershell
gh auth login
bash scripts/mirror-monorepo-to-github.sh
```

## Release flow (Android closed testing + iOS TestFlight)

1. Bump versions:
   - Android: `android/app/build.gradle.kts` → `versionCode` / `versionName`
   - iOS: `ios/project.yml` → marketing + build number
2. Update `android/distribution/whatsnew/*` if needed.
3. Commit to branch `releases/1.0.1` (example).
4. Push GitLab → mirror GitHub:
   ```powershell
   git push origin releases/1.0.1
   bash scripts/mirror-monorepo-to-github.sh
   # or set GITHUB_MIRROR_BRANCH=releases/1.0.1
   ```
5. GitHub Actions runs automatically:
   - **Android Release** → track `POS-closed`
   - **iOS Release** → TestFlight
6. Or manual:
   ```powershell
   gh workflow run "Android Release" -R fashandcurious14052026-dotcom/personal-os `
     -f upload_play=true -f play_track=POS-closed
   gh workflow run "iOS Release" -R fashandcurious14052026-dotcom/personal-os `
     -f upload_testflight=true
   ```

## Local build

```powershell
cd android
.\gradlew.bat :app:assembleDevDebug
.\gradlew.bat :app:bundleProdRelease   # needs POS_RELEASE_* in local.properties
```

## Required GitHub secrets (Android)

| Secret | Description |
|--------|-------------|
| `ANDROID_DEV_ENV` | Full `android/env/dev.env` |
| `ANDROID_PROD_ENV` | Full `android/env/prod.env` |
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Upload keystore base64 |
| `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | Store password |
| `ANDROID_UPLOAD_KEY_ALIAS` | e.g. `upload` |
| `ANDROID_UPLOAD_KEY_PASSWORD` | Key password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play API service account |
| `PLAY_EXPECTED_UPLOAD_SHA1` | Recommended — pre-upload cert check |

## Troubleshooting

| Error | Fix |
|-------|-----|
| Wrong signing key on Play | Match alias/keystore to Play upload key; set `PLAY_EXPECTED_UPLOAD_SHA1` |
| Track `POS-closed` not found | Create closed testing track in Play Console or use `internal` |
| Missing env file in CI | Push `ANDROID_DEV_ENV` / `ANDROID_PROD_ENV` secrets |
| versionCode already used | Increment `versionCode` in `build.gradle.kts` |
