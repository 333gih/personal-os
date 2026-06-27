/**
 * Generate Personal OS app icons from assets/brand/pos-logo-app.png
 * Usage: node scripts/generate-pos-app-icons.mjs
 */
import { mkdirSync, writeFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { createRequire } from 'module';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const sourcePath = resolve(repoRoot, 'assets/brand/pos-logo-app.png');

if (!existsSync(sourcePath)) {
  console.error(`Missing source: ${sourcePath}`);
  process.exit(1);
}

const require = createRequire(import.meta.url);
const sharp = require(resolve(repoRoot, 'story-tracker/node_modules/sharp'));

const iosIcons = [
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

const androidDensities = [
  { folder: 'mipmap-mdpi', size: 48 },
  { folder: 'mipmap-hdpi', size: 72 },
  { folder: 'mipmap-xhdpi', size: 96 },
  { folder: 'mipmap-xxhdpi', size: 144 },
  { folder: 'mipmap-xxxhdpi', size: 192 },
];

const iosOut = resolve(repoRoot, 'ios/PersonalOSApp/Assets.xcassets/AppIcon.appiconset');
mkdirSync(iosOut, { recursive: true });
for (const { name, size } of iosIcons) {
  await sharp(sourcePath)
    .resize(size, size, { fit: 'cover' })
    .png({ compressionLevel: 9 })
    .toFile(resolve(iosOut, name));
  console.log(`[ios] ${name}`);
}

for (const { folder, size } of androidDensities) {
  const dir = resolve(repoRoot, `android/app/src/main/res/${folder}`);
  mkdirSync(dir, { recursive: true });
  for (const name of ['ic_launcher.png', 'ic_launcher_round.png']) {
    await sharp(sourcePath)
      .resize(size, size, { fit: 'cover' })
      .png()
      .toFile(resolve(dir, name));
  }
  console.log(`[android] ${folder}`);
}

// Foreground for adaptive icon (432dp safe zone → 108dp vector equivalent at xxxhdpi)
const fgDir = resolve(repoRoot, 'android/app/src/main/res/drawable-nodpi');
mkdirSync(fgDir, { recursive: true });
await sharp(sourcePath)
  .resize(432, 432, { fit: 'contain', background: { r: 249, g: 247, b: 242, alpha: 1 } })
  .png()
  .toFile(resolve(fgDir, 'ic_launcher_foreground.png'));

console.log('Done — PoS app icons generated');
