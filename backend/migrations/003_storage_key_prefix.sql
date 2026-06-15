-- Prefix legacy storage keys with personal-os/ for SeaweedFS layout.
-- Run once after switching from MinIO standalone to fash SeaweedFS.
-- Objects must be copied/re-uploaded separately (see migrate-storage-to-seaweedfs.sh).

UPDATE files
SET storage_key = 'personal-os/' || storage_key
WHERE storage_key NOT LIKE 'personal-os/%'
  AND storage_key ~ '^[0-9a-f]{8}-[0-9a-f]{4}-';

-- Optional: update entity metadata referencing old keys
UPDATE entities
SET metadata = jsonb_set(
  metadata,
  '{storage_key}',
  to_jsonb('personal-os/' || (metadata->>'storage_key'))
)
WHERE metadata ? 'storage_key'
  AND metadata->>'storage_key' NOT LIKE 'personal-os/%';
