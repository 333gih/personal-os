# Story Tracker — Android

## Firefox for Android (recommended)

The Firefox build is the same extension package used on desktop. Firefox for Android supports WebExtensions (MV3) from AMO or temporary install.

```bash
npm run build:firefox
npm run package:firefox
```

Install `release/story-tracker-firefox.xpi` (or load `dist/firefox` as temporary add-on in Firefox Nightly / Developer Edition with `about:debugging`).

`firefox.manifest.json` includes `browser_specific_settings.gecko_android` (min version 142).

## Chrome / Kiwi / other Chromium browsers

```bash
npm run build:chrome
```

Load unpacked `dist/chrome` via the browser’s extension developer mode. Behavior matches desktop Chrome; some APIs may differ on mobile Chromium.

## Not supported

- **Safari on Android** — no WebExtension support.
- **Native WebView wrapper** — out of scope; use Firefox or Chromium with extension sideloading.
