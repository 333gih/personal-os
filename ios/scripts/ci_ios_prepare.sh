#!/usr/bin/env bash
# GitHub Actions: xcodegen + sanity checks for Personal OS iOS (monorepo root ios/).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/.." && pwd)"
cd "$ROOT"

RESOURCES="StoryTrackerExtension/Resources"
if [[ ! -f "${RESOURCES}/manifest.json" ]]; then
  echo "error: missing ${RESOURCES}/manifest.json — run: npm run build:safari && npm run sync:safari-ios" >&2
  exit 1
fi

BRIDGE="PersonalOSApp/Resources/connect-bridge.js"
if [[ ! -f "${BRIDGE}" ]]; then
  echo "error: missing ${BRIDGE} — run: npm run build:ios-bridge && npm run sync:ios-bridge" >&2
  exit 1
fi

ICON_SCRIPT=""
if [[ -f "${REPO_ROOT}/scripts/generate-pos-app-icons.mjs" ]]; then
  ICON_SCRIPT="${REPO_ROOT}/scripts/generate-pos-app-icons.mjs"
elif [[ -f "${REPO_ROOT}/story-tracker/scripts/generate-ios-app-icons.mjs" ]]; then
  ICON_SCRIPT="${REPO_ROOT}/story-tracker/scripts/generate-ios-app-icons.mjs"
elif [[ -f "${ROOT}/../scripts/generate-ios-app-icons.mjs" ]]; then
  ICON_SCRIPT="${ROOT}/../scripts/generate-ios-app-icons.mjs"
else
  echo "error: generate-ios-app-icons.mjs not found" >&2
  exit 1
fi

echo "==> Generate Personal OS app icons"
node "${ICON_SCRIPT}"

echo "==> Install XcodeGen"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen --version

echo "==> Generate Xcode project"
xcodegen generate

object_version="$(sed -n 's/.*objectVersion = \([0-9]*\);.*/\1/p' PersonalOS.xcodeproj/project.pbxproj | head -1)"
echo "objectVersion=${object_version}"

echo "==> Personal OS iOS project ready (scheme=PersonalOS)"
