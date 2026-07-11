#!/usr/bin/env bash
# Verify a decoded provisioning profile matches expected bundle ID and (optionally) profile name.
# Usage: ci_verify_provisioning_profile.sh <profile.mobileprovision> <expected-bundle-id> [expected-name]
set -euo pipefail

PROFILE="${1:?profile path required}"
EXPECTED_BUNDLE="${2:?expected bundle id required}"
EXPECTED_NAME="${3:-}"

if [[ ! -f "${PROFILE}" ]]; then
  echo "::error::Profile not found: ${PROFILE}"
  exit 1
fi

PLIST="$(mktemp)"
trap 'rm -f "${PLIST}"' EXIT
security cms -D -i "${PROFILE}" > "${PLIST}"

NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "${PLIST}")"
APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "${PLIST}")"
TEAM_PREFIX="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "${PLIST}")"

# application-identifier is TEAM.bundle (e.g. 4JA75SPHD9.com.personalos.story-tracker)
if [[ "${APP_ID}" != *".${EXPECTED_BUNDLE}" ]]; then
  echo "::error::Profile '${NAME}' has application-identifier '${APP_ID}', expected *'.${EXPECTED_BUNDLE}'"
  exit 1
fi

if [[ -n "${EXPECTED_NAME}" && "${NAME}" != "${EXPECTED_NAME}" ]]; then
  echo "::error::Profile name '${NAME}' does not match IOS_PROVISIONING_PROFILE_SPECIFIER '${EXPECTED_NAME}'"
  exit 1
fi

REQUIRE_PUSH="${4:-}"
if [[ "${REQUIRE_PUSH}" == "require-push" ]]; then
  if ! /usr/libexec/PlistBuddy -c 'Print :Entitlements:aps-environment' "${PLIST}" >/dev/null 2>&1; then
    echo "::error::Profile '${NAME}' is missing aps-environment (Push Notifications). Regenerate the App Store profile after enabling Push on the App ID."
    exit 1
  fi
fi

echo "OK profile: Name=${NAME} Team=${TEAM_PREFIX} AppId=${APP_ID}"
