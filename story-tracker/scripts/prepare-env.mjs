/**
 * Copy env profile into .env for Vite build (bakes __API_*__ / __PERSONAL_OS_FE_URL__).
 *
 * Usage:
 *   node scripts/prepare-env.mjs prod         # .env.prod → .env (default for all builds)
 *   node scripts/prepare-env.mjs local-prod   # .env.local.prod → .env (alias of prod hosts)
 */
import { copyFileSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const profile = process.argv[2] || 'local';

const source =
  profile === 'prod' || profile === 'local' ? '.env.prod'
  : profile === 'local-prod' ? '.env.local.prod'
  : '.env.prod';

const sourcePath = join(root, source);
const destPath = join(root, '.env');

if (!existsSync(sourcePath)) {
  console.error(`[story-tracker env] Missing ${source}`);
  process.exit(1);
}

copyFileSync(sourcePath, destPath);
console.log(`[story-tracker env] ${source} → .env (${profile} profile)`);
