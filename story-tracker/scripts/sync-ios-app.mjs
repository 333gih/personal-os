/**
 * Copy iOS container app web UI into story-tracker/ios/StoryTrackerApp/Resources.
 */
import { cp, mkdir, rm, stat } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const sourceDir = join(root, 'dist', 'ios-app');
const defaultDest = join(root, 'ios', 'StoryTrackerApp', 'Resources');
const destDir = process.env.STORY_TRACKER_IOS_APP_RESOURCES ?? defaultDest;

async function main() {
  try {
    await stat(sourceDir);
  } catch {
    console.error(`Missing iOS app build: ${sourceDir}`);
    console.error('Run: npm run build:ios-app');
    process.exit(1);
  }

  await rm(destDir, { recursive: true, force: true });
  await mkdir(destDir, { recursive: true });
  await cp(sourceDir, destDir, { recursive: true });

  console.log(`Synced ${sourceDir} -> ${destDir}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
