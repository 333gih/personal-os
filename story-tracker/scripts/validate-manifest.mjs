/**
 * Validates built manifest match patterns (catches invalid Firefox patterns like localhost:*).
 * Run: node scripts/validate-manifest.mjs [dist/firefox-dev/manifest.json]
 */
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const manifestPath = process.argv[2] ?? resolve(__dirname, '../dist/firefox-dev/manifest.json');

const INVALID_PORT_WILDCARD = /:\/\/[^/]+:\*\//;

function checkPatterns(label, patterns) {
  if (!Array.isArray(patterns)) return;
  for (const pattern of patterns) {
    if (typeof pattern !== 'string') continue;
    if (INVALID_PORT_WILDCARD.test(pattern) || pattern.includes(':*')) {
      throw new Error(`Invalid ${label} pattern (port wildcard): ${pattern}`);
    }
    if (pattern.includes('0.0.0.0')) {
      throw new Error(`Invalid ${label} pattern (0.0.0.0): ${pattern}`);
    }
  }
}

const manifest = JSON.parse(readFileSync(manifestPath, 'utf-8'));

checkPatterns('host_permissions', manifest.host_permissions);
for (const script of manifest.content_scripts ?? []) {
  checkPatterns('content_scripts.matches', script.matches);
}

console.log(`[validate-manifest] OK: ${manifestPath}`);
