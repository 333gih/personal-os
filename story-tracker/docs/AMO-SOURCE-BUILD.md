# AMO Source Code Build Instructions

This document is for Mozilla add-on reviewers to reproduce the signed extension package from source.

## Answer on AMO form

**Do you use code generators, minifiers, bundlers, etc.?** → **Yes**

This extension is written in TypeScript and built with Vite. The submitted `.zip` contains bundled/minified JavaScript produced from human-readable source in `src/`.

## Requirements

| Tool | Version |
|------|---------|
| Node.js | 20.x or later |
| npm | 10.x or later |
| OS | Windows, macOS, or Linux |

## Step-by-step build (Firefox — exact submitted package)

```bash
# 1. Enter extension source directory
cd story-tracker

# 2. Install dependencies (uses package-lock.json for reproducible versions)
npm ci

# 3. Configure environment (no secrets required for build output structure)
cp .env.example .env
# Optional: set INTERNAL_APPLICATION_ID / COMMERCIAL_APPLICATION_ID for runtime auth.
# Build output is identical regardless of these values.

# 4. Build Firefox extension
npm run build:firefox

# 5. Package for AMO upload (forward-slash zip paths)
npm run package:firefox
```

**Output file:** `release/story-tracker-firefox.zip`

**Unpacked output:** `dist/firefox/` (load via `about:debugging` → `dist/firefox/manifest.json`)

## Build scripts reference

| Command | Purpose |
|---------|---------|
| `npm ci` | Install exact dependency versions |
| `npm run build:firefox` | Vite production build → `dist/firefox/` |
| `npm run package:firefox` | Create AMO-compatible zip |
| `npm run test` | Run unit tests (optional verification) |

## What gets transformed

- **TypeScript** (`.ts`, `.tsx`) in `src/` → bundled JavaScript
- **React JSX** in popup/options → compiled JS
- **Vite** bundles background, content, popup, and options entry points
- **Production build** minifies output

Human-readable source is in `src/`. Do not review `dist/` or `release/` — they are build artifacts.

## Third-party libraries (not included as separate source)

Installed via npm, listed in `package.json`:

- `react`, `react-dom` — popup/options UI
- `webextension-polyfill` — cross-browser WebExtensions API

## Verify build

```bash
npm run test
npm run lint
```

## Repository layout

```
story-tracker/
  src/              ← extension source (TypeScript)
  public/           ← manifests, icons, host permissions
  scripts/          ← build helpers (icons, zip packaging)
  package.json
  package-lock.json
  vite.config.ts
  tsconfig.json
  .env.example
```

## Contact

If reviewers need a test account, see **Notes to Reviewer** on the AMO submission page.
