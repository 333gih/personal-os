#!/usr/bin/env bash
# Decode base64 provisioning profile and install under ~/Library/MobileDevice/Provisioning Profiles/
set -euo pipefail

PROFILE_B64="${1:?base64 provisioning profile required}"
LABEL="${2:-profile}"

PP_PATH="${RUNNER_TEMP}/${LABEL}.mobileprovision"
echo "${PROFILE_B64}" | base64 --decode > "${PP_PATH}"
UUID="$(/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< "$(security cms -D -i "${PP_PATH}")")"
NAME="$(/usr/libexec/PlistBuddy -c 'Print Name' /dev/stdin <<< "$(security cms -D -i "${PP_PATH}")")"
mkdir -p "${HOME}/Library/MobileDevice/Provisioning Profiles"
cp "${PP_PATH}" "${HOME}/Library/MobileDevice/Provisioning Profiles/${UUID}.mobileprovision"
echo "Installed ${LABEL}: Name=${NAME} UUID=${UUID}"
