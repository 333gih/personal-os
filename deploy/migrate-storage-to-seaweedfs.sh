#!/usr/bin/env bash
# Migrate file objects from legacy MinIO to fash SeaweedFS.
# Requires: mc (MinIO Client) configured for source and destination.
#
# Usage:
#   export SRC_ALIAS=minio-old
#   export DST_ALIAS=seaweedfs
#   export SRC_BUCKET=personal-os
#   export DST_BUCKET=personal-os
#   ./deploy/migrate-storage-to-seaweedfs.sh
#
# Then run SQL migration:
#   psql $DATABASE_URL -f backend/migrations/003_storage_key_prefix.sql

set -euo pipefail

SRC_ALIAS="${SRC_ALIAS:-minio-old}"
DST_ALIAS="${DST_ALIAS:-seaweedfs}"
SRC_BUCKET="${SRC_BUCKET:-personal-os}"
DST_BUCKET="${DST_BUCKET:-personal-os}"
PREFIX="${PREFIX:-personal-os}"

echo "Listing objects in ${SRC_ALIAS}/${SRC_BUCKET}..."
mc ls --recursive "${SRC_ALIAS}/${SRC_BUCKET}/" | while read -r line; do
  key=$(echo "$line" | awk '{print $NF}')
  [ -z "$key" ] && continue
  dest="${PREFIX}/${key}"
  echo "Copy: $key -> $dest"
  mc cp "${SRC_ALIAS}/${SRC_BUCKET}/${key}" "${DST_ALIAS}/${DST_BUCKET}/${dest}"
done

echo "Done. Run 003_storage_key_prefix.sql if keys changed."
