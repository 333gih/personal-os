/**
 * Package extension builds for store upload.
 * Uses forward slashes in zip paths (required by Firefox AMO).
 *
 * Usage: node scripts/package-release.mjs [firefox|chrome|all]
 */
import archiver from 'archiver';
import { createWriteStream } from 'fs';
import { mkdir, readdir, stat } from 'fs/promises';
import { join, posix, relative } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');

const EXCLUDE_DIRS = new Set(['manifest']);
const EXCLUDE_FILES = new Set([
  'popup.js',
  'options.js',
]);

async function collectFiles(dir, baseDir, files = []) {
  const entries = await readdir(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    const relPath = relative(baseDir, fullPath);

    if (entry.isDirectory()) {
      if (EXCLUDE_DIRS.has(entry.name)) continue;
      await collectFiles(fullPath, baseDir, files);
      continue;
    }

    if (EXCLUDE_FILES.has(entry.name)) continue;
    files.push({ fullPath, relPath: relPath.split('\\').join('/') });
  }

  return files;
}

async function zipDirectory(sourceDir, outFile) {
  const files = await collectFiles(sourceDir, sourceDir);

  await mkdir(dirname(outFile), { recursive: true });

  return new Promise((resolve, reject) => {
    const output = createWriteStream(outFile);
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', () => {
      console.log(`Created ${outFile} (${archive.pointer()} bytes, ${files.length} files)`);
      resolve();
    });

    archive.on('error', reject);
    archive.pipe(output);

    for (const file of files) {
      archive.file(file.fullPath, { name: posix.normalize(file.relPath) });
    }

    void archive.finalize();
  });
}

async function main() {
  const target = process.argv[2] ?? 'all';
  const targets =
    target === 'all' ? ['firefox', 'chrome']
    : target === 'firefox' || target === 'chrome' ? [target]
    : null;

  if (!targets) {
    console.error('Usage: node scripts/package-release.mjs [firefox|chrome|all]');
    process.exit(1);
  }

  for (const browser of targets) {
    const sourceDir = join(root, 'dist', browser);
    try {
      await stat(sourceDir);
    } catch {
      console.error(`Missing build output: ${sourceDir}. Run npm run build:${browser} first.`);
      process.exit(1);
    }

    const outFile = join(root, 'release', `story-tracker-${browser}.zip`);
    await zipDirectory(sourceDir, outFile);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
