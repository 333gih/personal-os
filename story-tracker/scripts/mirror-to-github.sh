#!/usr/bin/env bash
# Assemble story-tracker + ios + workflows → push to standalone GitHub repo (TestFlight).
#
# Usage (from personal-os repo root):
#   export GITHUB_MIRROR_URL=https://github.com/YOU/story-tracker.git
#   bash story-tracker/scripts/mirror-to-github.sh
set -euo pipefail

MONOREPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BRANCH="${GITHUB_MIRROR_BRANCH:-main}"
REMOTE_URL="${GITHUB_MIRROR_URL:-https://github.com/333gih/story-tracker.git}"
STAGING="$(mktemp -d)"
SOURCE_SHA="$(git -C "${MONOREPO_ROOT}" rev-parse --short HEAD 2>/dev/null || echo unknown)"

cleanup() { rm -rf "${STAGING}"; }
trap cleanup EXIT

echo "==> Staging mirror at ${STAGING}"
echo "    Source: personal-os @ ${SOURCE_SHA}"

rsync -a \
  --exclude node_modules \
  --exclude dist \
  --exclude release \
  --exclude .git \
  "${MONOREPO_ROOT}/story-tracker/" "${STAGING}/"

rsync -a \
  --exclude DerivedData \
  --exclude build \
  --exclude '*.xcodeproj' \
  --exclude PersonalOSApp/Resources/connect-bridge.js \
  --exclude StoryTrackerExtension/Resources \
  "${MONOREPO_ROOT}/ios/" "${STAGING}/ios/"

mkdir -p "${STAGING}/.github/workflows"
cp "${MONOREPO_ROOT}/ios/github-workflows/"*.yml "${STAGING}/.github/workflows/"

mkdir -p "${STAGING}/docs"
cp "${MONOREPO_ROOT}/docs/CI-IOS.md" "${STAGING}/docs/"

mkdir -p "${STAGING}/secrets"
cp "${MONOREPO_ROOT}/secrets/ios-release.env.example" "${STAGING}/secrets/" 2>/dev/null || \
  cp "${MONOREPO_ROOT}/story-tracker/secrets/ios-release.env.example" "${STAGING}/secrets/" 2>/dev/null || true

cp "${MONOREPO_ROOT}/scripts/push_github_ios_secrets.sh" "${STAGING}/scripts/" 2>/dev/null || true
cp "${MONOREPO_ROOT}/scripts/push_github_ios_secrets.ps1" "${STAGING}/scripts/" 2>/dev/null || true

cd "${STAGING}"
git init -q
git config user.email "mirror@personal-os"
git config user.name "personal-os mirror"
git add -A
git commit -q -m "mirror personal-os@${SOURCE_SHA} (story-tracker + ios)"

PUSH_URL="${REMOTE_URL}"
if [[ -n "${GITHUB_MIRROR_TOKEN:-}" ]]; then
  PUSH_URL="$(echo "${REMOTE_URL}" | sed -E "s#https://#https://x-access-token:${GITHUB_MIRROR_TOKEN}@#")"
  echo "==> Push with GITHUB_MIRROR_TOKEN"
  git push "${PUSH_URL}" "HEAD:${BRANCH}" --force
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh not found or set GITHUB_MIRROR_TOKEN" >&2
    exit 1
  fi
  gh auth setup-git
  REMOTE_NAME="story-tracker-github"
  git remote remove "${REMOTE_NAME}" 2>/dev/null || true
  git remote add "${REMOTE_NAME}" "${REMOTE_URL}"
  echo "==> Push via gh auth (${BRANCH})"
  git push "${REMOTE_NAME}" "HEAD:${BRANCH}" --force
  git remote remove "${REMOTE_NAME}" 2>/dev/null || true
fi

echo "==> Done: ${REMOTE_URL} (branch ${BRANCH})"
echo "    Layout: extension at repo root + ios/ + .github/workflows/"
echo "    TestFlight: gh workflow run \"iOS Release\" -R owner/story-tracker"
