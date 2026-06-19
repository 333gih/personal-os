#!/usr/bin/env bash
# GitHub Actions: xcodegen + sanity checks for Story Tracker iOS wrapper.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RESOURCES="StoryTrackerExtension/Resources"
if [[ ! -f "${RESOURCES}/manifest.json" ]]; then
  echo "error: missing ${RESOURCES}/manifest.json — run from story-tracker/: npm run build:safari && npm run sync:safari-ios" >&2
  exit 1
fi

echo "==> Install XcodeGen"
if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi
xcodegen --version

echo "==> Generate Xcode project"
xcodegen generate

object_version="$(sed -n 's/.*objectVersion = \([0-9]*\);.*/\1/p' StoryTracker.xcodeproj/project.pbxproj | head -1)"
echo "objectVersion=${object_version}"
if [[ "${object_version}" -gt 60 ]]; then
  sed -i '' -E 's/objectVersion = [0-9]+/objectVersion = 60/' StoryTracker.xcodeproj/project.pbxproj
  echo "Downgraded objectVersion to 60 for Xcode 15/16 compatibility"
fi

echo "==> Story Tracker iOS project ready (scheme=StoryTracker)"
