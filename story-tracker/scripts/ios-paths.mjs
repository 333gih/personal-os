/**
 * Resolve ios/ directory for monorepo (personal-os/ios) or mirrored GitHub repo (./ios).
 */
import { existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const packageRoot = join(__dirname, '..');

export function resolveIosRoot() {
  const siblingIos = join(packageRoot, 'ios');
  const monorepoIos = join(packageRoot, '..', 'ios');
  if (existsSync(join(siblingIos, 'project.yml'))) return siblingIos;
  if (existsSync(join(monorepoIos, 'project.yml'))) return monorepoIos;
  return siblingIos;
}

export function resolveIconScript() {
  const here = join(__dirname, 'generate-ios-app-icons.mjs');
  if (existsSync(here)) return here;
  const monorepo = join(packageRoot, '..', 'story-tracker', 'scripts', 'generate-ios-app-icons.mjs');
  if (existsSync(monorepo)) return monorepo;
  return here;
}
