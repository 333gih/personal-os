/**
 * Generates PersonalOSApp AppIcon.appiconset PNGs from public/icons/brand-mark.svg.
 * Run: node scripts/generate-ios-app-icons.mjs
 */
import { mkdirSync, writeFileSync } from 'fs';
import { resolve, dirname, join } from 'path';
import { fileURLToPath } from 'url';
import sharp from 'sharp';
import { resolveIosRoot } from './ios-paths.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');
const sourcePath = resolve(root, 'public/icons/brand-mark.svg');
const outDir = resolve(resolveIosRoot(), 'PersonalOSApp/Assets.xcassets/AppIcon.appiconset');
const bg = { r: 255, g: 255, b: 255 };

const icons = [
  { name: 'Icon-20@2x.png', size: 40 },
  { name: 'Icon-20@3x.png', size: 60 },
  { name: 'Icon-29@2x.png', size: 58 },
  { name: 'Icon-29@3x.png', size: 87 },
  { name: 'Icon-40@2x.png', size: 80 },
  { name: 'Icon-40@3x.png', size: 120 },
  { name: 'Icon-60@2x.png', size: 120 },
  { name: 'Icon-60@3x.png', size: 180 },
  { name: 'Icon-ipad-20.png', size: 20 },
  { name: 'Icon-ipad-20@2x.png', size: 40 },
  { name: 'Icon-ipad-29.png', size: 29 },
  { name: 'Icon-ipad-29@2x.png', size: 58 },
  { name: 'Icon-ipad-40.png', size: 40 },
  { name: 'Icon-ipad-40@2x.png', size: 80 },
  { name: 'Icon-ipad-76.png', size: 76 },
  { name: 'Icon-ipad-76@2x.png', size: 152 },
  { name: 'Icon-ipad-83.5@2x.png', size: 167 },
  { name: 'Icon-Marketing-1024.png', size: 1024 },
];

mkdirSync(outDir, { recursive: true });

for (const { name, size } of icons) {
  await sharp(sourcePath)
    .resize(size, size, { fit: 'contain', background: { ...bg, alpha: 1 } })
    .flatten({ background: bg })
    .png({ compressionLevel: 9, force: true })
    .toFile(resolve(outDir, name));
  console.log(`[generate-ios-app-icons] ${name}`);
}

writeFileSync(
  resolve(outDir, '.gitignore'),
  '# Generated in CI via scripts/generate-ios-app-icons.mjs\n*.png\n',
);
