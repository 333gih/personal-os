#!/usr/bin/env bash
# Writes upload keystore + local.properties for CI (GitHub Actions).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

KEYSTORE_B64="${KEYSTORE_B64:-${ANDROID_UPLOAD_KEYSTORE_BASE64:-}}"
STORE_PW="${STORE_PW:-${ANDROID_UPLOAD_KEYSTORE_PASSWORD:-}}"
KEY_ALIAS="${KEY_ALIAS:-${ANDROID_UPLOAD_KEY_ALIAS:-}}"
KEY_PW="${KEY_PW:-${ANDROID_UPLOAD_KEY_PASSWORD:-}}"

for var in KEYSTORE_B64 STORE_PW KEY_ALIAS KEY_PW; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::Missing env ${var} (set ANDROID_UPLOAD_* secrets)."
    exit 1
  fi
done

KEYSTORE_PATH="${RUNNER_TEMP:-/tmp}/pos-upload.keystore"
echo "${KEYSTORE_B64}" | base64 --decode > "${KEYSTORE_PATH}"

REL_PATH="ci-upload.keystore"
cp "${KEYSTORE_PATH}" "${ROOT}/${REL_PATH}"

{
  echo "POS_RELEASE_STORE_FILE=${REL_PATH}"
  echo "POS_RELEASE_STORE_PASSWORD=${STORE_PW}"
  echo "POS_RELEASE_KEY_ALIAS=${KEY_ALIAS}"
  echo "POS_RELEASE_KEY_PASSWORD=${KEY_PW}"
} >> local.properties

echo "Release signing configured (alias=${KEY_ALIAS}, store=${REL_PATH})"
