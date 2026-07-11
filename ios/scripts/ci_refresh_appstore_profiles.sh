#!/usr/bin/env bash
# Regenerate App Store provisioning profiles so they include the latest App ID
# capabilities (e.g. Push Notifications / aps-environment). Stale profiles in
# GitHub secrets often predate capability changes and break archive.
set -euo pipefail

TEAM_ID="${APPLE_TEAM_ID:?APPLE_TEAM_ID required}"
KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:?APP_STORE_CONNECT_API_KEY_ID required}"
ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:?APP_STORE_CONNECT_ISSUER_ID required}"
KEY_CONTENT="${APP_STORE_CONNECT_API_PRIVATE_KEY:?APP_STORE_CONNECT_API_PRIVATE_KEY required}"

APP_BUNDLE="${APP_BUNDLE_ID:-com.personalos.story-tracker}"
EXT_BUNDLE="${EXT_BUNDLE_ID:-com.personalos.story-tracker.extension}"
APP_PROFILE_NAME="${APP_PROFILE_NAME:?APP_PROFILE_NAME required}"
EXT_PROFILE_NAME="${EXT_PROFILE_NAME:?EXT_PROFILE_NAME required}"

KEY_DIR="${HOME}/.private_keys"
mkdir -p "${KEY_DIR}"
KEY_FILE="${KEY_DIR}/AuthKey_${KEY_ID}.p8"
printf '%s\n' "${KEY_CONTENT}" > "${KEY_FILE}"
chmod 600 "${KEY_FILE}"

API_KEY_JSON="${RUNNER_TEMP}/asc_api_key.json"
export KEY_ID ISSUER_ID KEY_FILE API_KEY_JSON
python3 - <<'PY'
import json, os
payload = {
    "key_id": os.environ["KEY_ID"],
    "issuer_id": os.environ["ISSUER_ID"],
    "key_filepath": os.environ["KEY_FILE"],
    "duration": 1200,
    "in_house": False,
}
with open(os.environ["API_KEY_JSON"], "w", encoding="utf-8") as fh:
    json.dump(payload, fh)
PY

echo "==> Install fastlane (profile refresh)"
if ! command -v fastlane >/dev/null 2>&1; then
  sudo gem install fastlane -N --silent
fi
fastlane --version

refresh_profile() {
  local bundle_id="$1"
  local profile_name="$2"
  local label="$3"
  local out_base="${RUNNER_TEMP}/${label}"

  echo "==> Refresh App Store profile: ${profile_name} (${bundle_id})"
  fastlane run get_provisioning_profile \
    api_key_path:"${API_KEY_JSON}" \
    app_identifier:"${bundle_id}" \
    team_id:"${TEAM_ID}" \
    provisioning_name:"${profile_name}" \
    filename:"${out_base}" \
    force:true \
    skip_install:false \
    include_mac_in_profiles:false

  local profile_path="${out_base}.mobileprovision"
  if [[ ! -f "${profile_path}" ]]; then
    echo "::error::fastlane did not produce ${profile_path}"
    exit 1
  fi
  cp "${profile_path}" "${RUNNER_TEMP}/${label}.mobileprovision"
  echo "Refreshed profile saved to ${RUNNER_TEMP}/${label}.mobileprovision"
}

refresh_profile "${APP_BUNDLE}" "${APP_PROFILE_NAME}" "personal-os-app"
refresh_profile "${EXT_BUNDLE}" "${EXT_PROFILE_NAME}" "story-tracker-extension"

echo "==> Verify Push entitlement on app profile"
PLIST="$(mktemp)"
trap 'rm -f "${PLIST}"' EXIT
security cms -D -i "${RUNNER_TEMP}/personal-os-app.mobileprovision" > "${PLIST}"
if ! /usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "${PLIST}" >/dev/null 2>&1; then
  echo "::error::Refreshed app profile still lacks aps-environment. Enable Push Notifications on App ID ${APP_BUNDLE} in Apple Developer, then re-run."
  exit 1
fi
APS_ENV="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "${PLIST}")"
echo "OK app profile aps-environment=${APS_ENV}"
