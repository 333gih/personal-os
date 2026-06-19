#!/usr/bin/env bash
# Inject CI signing into project.yml before xcodegen (Release configs only).
# Usage: ci_patch_release_signing.sh <TEAM_ID> <APP_PROFILE_NAME> <EXT_PROFILE_NAME>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TEAM_ID="${1:?TEAM_ID required}"
APP_PROFILE="${2:?APP provisioning profile name required}"
EXT_PROFILE="${3:?EXTENSION provisioning profile name required}"

if [[ ! -f project.yml ]]; then
  echo "project.yml not found"
  exit 1
fi

for placeholder in __CI_TEAM_ID__ __CI_PROVISIONING_PROFILE__ __CI_EXTENSION_PROVISIONING_PROFILE__; do
  if ! grep -q "${placeholder}" project.yml; then
    echo "project.yml missing ${placeholder}"
    exit 1
  fi
done

sed -i '' "s|__CI_TEAM_ID__|${TEAM_ID}|g" project.yml
sed -i '' "s|__CI_PROVISIONING_PROFILE__|${APP_PROFILE}|g" project.yml
sed -i '' "s|__CI_EXTENSION_PROVISIONING_PROFILE__|${EXT_PROFILE}|g" project.yml

echo "Patched project.yml for manual signing (app + Safari extension Release)"
