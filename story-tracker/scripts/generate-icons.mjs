/**
 * Generates extension toolbar/store icons from public/icons/brand-mark.svg.
 * Run: node scripts/generate-icons.mjs
 */
import { mkdirSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(__dirname, '../public/icons');
const sourcePath = resolve(outDir, 'brand-mark.svg');

mkdirSync(outDir, { recursive: true });

if (!existsSync(sourcePath)) {
  console.warn('[generate-icons] brand-mark.svg not found — skipping');
  process.exit(0);
}

async function writeIcon(size) {
  await sharp(sourcePath)
    .resize(size, size, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(resolve(outDir, `icon-${size}.png`));
  console.log(`[generate-icons] icon-${size}.png`);
}

await writeIcon(16);
await writeIcon(48);
await writeIcon(128);
