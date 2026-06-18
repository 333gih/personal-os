/**
 * Package extension SOURCE for Mozilla AMO submission.
 * Excludes node_modules, dist, release, and secrets.
 *
 * Usage: node scripts/package-source.mjs
 */
import archiver from 'archiver';
import { createWriteStream } from 'fs';
import { mkdir, readdir, stat } from 'fs/promises';
import { join, posix, relative, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const outDir = join(root, 'release');
const outFile = join(outDir, 'story-tracker-source.zip');

const EXCLUDE_DIRS = new Set([
  'node_modules',
  'dist',
  'release',
  '.git',
]);

const EXCLUDE_FILES = new Set([
  '.env',
  '.DS_Store',
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
    if (entry.name.endsWith('.log')) continue;

    files.push({ fullPath, relPath: relPath.split('\\').join('/') });
  }

  return files;
}

async function main() {
  const files = await collectFiles(root, root);
  await mkdir(outDir, { recursive: true });

  await new Promise((resolve, reject) => {
    const output = createWriteStream(outFile);
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', () => {
      console.log(`Created ${outFile}`);
      console.log(`Files: ${files.length}, Size: ${archive.pointer()} bytes`);
      resolve();
    });

    archive.on('error', reject);
    archive.pipe(output);

    for (const file of files) {
      archive.file(file.fullPath, { name: posix.join('story-tracker', file.relPath) });
    }

    void archive.finalize();
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
