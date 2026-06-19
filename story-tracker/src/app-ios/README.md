# Deprecated — iOS companion UI

The native iOS app now loads the hosted **Personal OS frontend** (`frontend/`) in WKWebView.

This folder (`src/app-ios/`) was the old Story Tracker companion shell. It is **no longer built** for release (`npm run build:ios-app` is deprecated).

**Still used:**
- `src/platform/ios-app-browser.ts` — WebExtension shim for `connect-bridge.js` in the iOS app
- Safari extension code under `src/background`, `src/content`, `src/popup` — unchanged

**iOS build:** `npm run build:ios-bridge && npm run sync:ios-bridge` (auth handoff script only)
