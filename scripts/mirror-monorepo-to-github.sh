#!/usr/bin/env bash
# Mirror personal-os monorepo → GitHub (Android + iOS GitHub Actions).
#
# Usage (from repo root):
#   export GITHUB_MIRROR_URL=https://github.com/OWNER/personal-os.git
#   bash scripts/mirror-monorepo-to-github.sh
#
# Optional:
#   GITHUB_MIRROR_BRANCH=main
#   GITHUB_MIRROR_TOKEN=ghp_...   (or use gh auth login)
set -euo pipefail

MONOREPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRANCH="${GITHUB_MIRROR_BRANCH:-main}"
REMOTE_URL="${GITHUB_MIRROR_URL:-https://github.com/333gih/personal-os.git}"

cd "${MONOREPO_ROOT}"
SOURCE_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "==> Mirror personal-os @ ${SOURCE_SHA} → ${REMOTE_URL} (${BRANCH})"

PUSH_URL="${REMOTE_URL}"
if [[ -n "${GITHUB_MIRROR_TOKEN:-}" ]]; then
  PUSH_URL="$(echo "${REMOTE_URL}" | sed -E "s#https://#https://x-access-token:${GITHUB_MIRROR_TOKEN}@#")"
  git push "${PUSH_URL}" "HEAD:${BRANCH}" --force
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "error: gh not found or set GITHUB_MIRROR_TOKEN" >&2
    exit 1
  fi
  gh auth setup-git
  REMOTE_NAME="personal-os-github"
  git remote remove "${REMOTE_NAME}" 2>/dev/null || true
  git remote add "${REMOTE_NAME}" "${REMOTE_URL}"
  git push "${REMOTE_NAME}" "HEAD:${BRANCH}" --force
  git remote remove "${REMOTE_NAME}" 2>/dev/null || true
fi

echo "==> Done. Workflows on GitHub:"
echo "    Android closed testing: push releases/* or gh workflow run Android Release"
echo "    iOS TestFlight:         push releases/* or gh workflow run \"iOS Release\""
