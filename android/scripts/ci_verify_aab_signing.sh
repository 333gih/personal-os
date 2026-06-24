#!/usr/bin/env bash
# Verify prod AAB signing certificate SHA-1 before Google Play upload.
set -euo pipefail

AAB="${1:-}"
if [[ -z "${AAB}" || ! -f "${AAB}" ]]; then
  echo "::error::AAB not found: ${AAB:-<missing>}"
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
unzip -q "${AAB}" "META-INF/*" -d "${WORK}" 2>/dev/null || true

CERT_FILE=""
for candidate in "${WORK}"/META-INF/*.RSA "${WORK}"/META-INF/*.DSA "${WORK}"/META-INF/*.EC; do
  if [[ -f "${candidate}" ]]; then
    CERT_FILE="${candidate}"
    break
  fi
done

if [[ -z "${CERT_FILE}" ]]; then
  echo "::error::Could not extract signing certificate from AAB META-INF"
  exit 1
fi

SHA1="$(keytool -printcert -file "${CERT_FILE}" 2>/dev/null | awk -F': ' '/SHA1:/ {print $2; exit}')"
if [[ -z "${SHA1}" ]]; then
  echo "::error::Could not read SHA-1 from AAB signing certificate"
  exit 1
fi

echo "AAB upload certificate SHA-1: ${SHA1}"

EXPECTED="${PLAY_EXPECTED_UPLOAD_SHA1:-}"
if [[ -n "${EXPECTED}" ]]; then
  NORM_ACTUAL="$(echo "${SHA1}" | tr '[:lower:]' '[:upper:]' | tr -d ' ')"
  NORM_EXPECTED="$(echo "${EXPECTED}" | tr '[:lower:]' '[:upper:]' | tr -d ' ')"
  if [[ "${NORM_ACTUAL}" != "${NORM_EXPECTED}" ]]; then
    echo "::error::AAB signing SHA-1 mismatch."
    echo "  AAB signed with: ${SHA1}"
    echo "  Play expects:    ${EXPECTED}"
    exit 1
  fi
  echo "Upload certificate matches PLAY_EXPECTED_UPLOAD_SHA1"
else
  echo "::warning::PLAY_EXPECTED_UPLOAD_SHA1 not set — skipping pre-upload fingerprint check"
fi
