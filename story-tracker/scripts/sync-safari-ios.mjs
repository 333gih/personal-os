/**
 * Copy Safari Web Extension build into the standalone iOS wrapper (story-tracker/ios).
 *
 * Usage:
 *   node scripts/sync-safari-ios.mjs
 *   STORY_TRACKER_IOS_RESOURCES=/custom/path node scripts/sync-safari-ios.mjs
 */
import { cp, mkdir, rm, stat } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const sourceDir = join(root, 'dist', 'safari');
const defaultDest = join(root, 'ios', 'StoryTrackerExtension', 'Resources');
const destDir = process.env.STORY_TRACKER_IOS_RESOURCES ?? defaultDest;

async function main() {
  try {
    await stat(sourceDir);
  } catch {
    console.error(`Missing Safari build: ${sourceDir}`);
    console.error('Run: npm run build:safari');
    process.exit(1);
  }

  await rm(destDir, { recursive: true, force: true });
  await mkdir(destDir, { recursive: true });
  await cp(sourceDir, destDir, { recursive: true });

  console.log(`Synced ${sourceDir} -> ${destDir}`);
  console.log('Open ios/ in Xcode (xcodegen generate) and run StoryTracker on a device.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
