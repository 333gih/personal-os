/**
 * Build connect-bridge.js for the iOS container app (WKWebView auth handoff).
 */
import { cp, mkdir, rm } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { resolveIosRoot } from './ios-paths.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const sourceFile = join(root, 'dist', 'ios-bridge', 'connect-bridge.js');
const defaultDestDir = join(resolveIosRoot(), 'PersonalOSApp', 'Resources');
const destDir = process.env.STORY_TRACKER_IOS_APP_RESOURCES ?? defaultDestDir;
const destFile = join(destDir, 'connect-bridge.js');

async function main() {
  await rm(destDir, { recursive: true, force: true });
  await mkdir(destDir, { recursive: true });
  await cp(sourceFile, destFile);
  console.log(`Synced ${sourceFile} -> ${destFile}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
