/**
 * Generates extension toolbar/store icons from public/icons/icon-source.png.
 * Run: node scripts/generate-icons.mjs
 */
import { mkdirSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outDir = resolve(__dirname, '../public/icons');
const sourcePath = resolve(outDir, 'icon-source.png');

mkdirSync(outDir, { recursive: true });

if (!existsSync(sourcePath)) {
  console.warn('[generate-icons] icon-source.png not found — skipping');
  process.exit(0);
}

/** Book + flag region (omit small "Personal OS" text for toolbar clarity). */
const TOOLBAR_CROP = { left: 80, top: 40, width: 864, height: 720 };

async function writeIcon(size, crop) {
  let pipeline = sharp(sourcePath);
  if (crop) {
    pipeline = pipeline.extract(crop);
  }
  await pipeline
    .resize(size, size, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 1 },
    })
    .png()
    .toFile(resolve(outDir, `icon-${size}.png`));
  console.log(`[generate-icons] icon-${size}.png`);
}

await writeIcon(16, TOOLBAR_CROP);
await writeIcon(48, TOOLBAR_CROP);
await writeIcon(128, null);
