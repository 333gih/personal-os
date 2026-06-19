#!/usr/bin/env bash
# Mirror only story-tracker/ from monorepo personal-os → standalone GitHub repo.
#
# Usage (from personal-os repo root):
#   export GITHUB_MIRROR_URL=https://github.com/YOU/story-tracker.git
#   export GITHUB_MIRROR_TOKEN=ghp_...   # or use SSH remote
#   bash story-tracker/scripts/mirror-to-github.sh
#
# One-time setup on GitHub:
#   1. Create empty repo (no README) e.g. github.com/YOU/story-tracker
#   2. Fine-grained PAT: Contents read/write on that repo
#   3. GitLab CI: set GITHUB_MIRROR_URL + GITHUB_MIRROR_TOKEN as masked variables
set -euo pipefail

MONOREPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PREFIX="story-tracker"
BRANCH="${GITHUB_MIRROR_BRANCH:-main}"
SPLIT_BRANCH="story-tracker-mirror-split"
REMOTE_URL="${GITHUB_MIRROR_URL:-}"

if [[ -z "${REMOTE_URL}" ]]; then
  echo "error: set GITHUB_MIRROR_URL (e.g. https://github.com/you/story-tracker.git)" >&2
  exit 1
fi

cd "${MONOREPO_ROOT}"

if [[ ! -d "${PREFIX}" ]]; then
  echo "error: ${PREFIX}/ not found under ${MONOREPO_ROOT}" >&2
  exit 1
fi

echo "==> Fetch full history (subtree split needs it)"
git fetch origin "${BRANCH}" 2>/dev/null || true

echo "==> Split subtree ${PREFIX}/"
git subtree split --prefix="${PREFIX}" -b "${SPLIT_BRANCH}"

PUSH_URL="${REMOTE_URL}"
if [[ -n "${GITHUB_MIRROR_TOKEN:-}" ]]; then
  PUSH_URL="$(echo "${REMOTE_URL}" | sed -E "s#https://#https://x-access-token:${GITHUB_MIRROR_TOKEN}@#")"
  echo "==> Push with GITHUB_MIRROR_TOKEN"
  git push "${PUSH_URL}" "${SPLIT_BRANCH}:${BRANCH}" --force
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
  git push "${REMOTE_NAME}" "${SPLIT_BRANCH}:${BRANCH}" --force
  git remote remove "${REMOTE_NAME}" 2>/dev/null || true
fi

echo "==> Done. GitHub repo root = former monorepo/${PREFIX}/"
echo "    Workflows: .github/workflows/ios-*.yml"
echo "    iOS secrets: push via scripts/push_github_ios_secrets.sh -R owner/story-tracker"
