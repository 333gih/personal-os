import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import webExtension from 'vite-plugin-web-extension';
import { resolve } from 'path';
import { readFileSync } from 'fs';

const target = process.env.TARGET ?? 'firefox';
const isFirefox = target === 'firefox';

function loadJsonFile<T>(path: string, fallback: T): T {
  try {
    return JSON.parse(readFileSync(path, 'utf-8')) as T;
  } catch {
    return fallback;
  }
}

function loadHostPermissions(): string[] {
  const story = loadJsonFile<{ hostPermissions: string[] }>(
    resolve(__dirname, 'public/manifest/host-permissions.json'),
    { hostPermissions: [] },
  );
  const api = loadJsonFile<{ apiHostPermissions: string[] }>(
    resolve(__dirname, 'public/manifest/api-host-permissions.json'),
    { apiHostPermissions: [] },
  );
  return [...story.hostPermissions, ...api.apiHostPermissions];
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const outDir = `dist/${target}`;

  const baseManifest = JSON.parse(
    readFileSync(
      resolve(__dirname, `public/manifest/${target}.manifest.json`),
      'utf-8',
    ),
  );

  const hostPermissions = loadHostPermissions();

  const manifest = {
    ...baseManifest,
    host_permissions: hostPermissions,
    content_scripts: [
      {
        matches: hostPermissions.filter((p) => !p.includes('api-')),
        js: ['src/content/index.ts'],
        run_at: 'document_idle',
      },
    ],
  };

  return {
    define: {
      __API_BASE_URL__: JSON.stringify(
        env.API_BASE_URL ?? 'https://api-personal-os.fashandcurious.com/api/v1',
      ),
      __API_TIMEOUT__: JSON.stringify(Number(env.API_TIMEOUT ?? 30000)),
      __AUTH_API_URL__: JSON.stringify(
        env.AUTH_API_URL ?? 'https://api-auth.fashandcurious.com',
      ),
      __AUTH_LOCALE__: JSON.stringify(env.AUTH_LOCALE ?? 'vi'),
      __INTERNAL_APPLICATION_ID__: JSON.stringify(env.INTERNAL_APPLICATION_ID ?? ''),
      __COMMERCIAL_APPLICATION_ID__: JSON.stringify(env.COMMERCIAL_APPLICATION_ID ?? ''),
      __API_READING_PROGRESS__: JSON.stringify(env.API_READING_PROGRESS ?? '/reading-progress'),
      __API_READING_PROGRESS_CURRENT__: JSON.stringify(
        env.API_READING_PROGRESS_CURRENT ?? '/reading-progress/current',
      ),
      __DEFAULT_SYNC_INTERVAL_MS__: JSON.stringify(
        Number(env.DEFAULT_SYNC_INTERVAL_MS ?? 30000),
      ),
      __BROWSER_TARGET__: JSON.stringify(target),
    },
    resolve: {
      alias: {
        '@': resolve(__dirname, 'src'),
      },
    },
    plugins: [
      react(),
      webExtension({
        manifest: () => manifest,
        disableAutoLaunch: true,
        browser: isFirefox ? 'firefox' : 'chrome',
      }),
    ],
    build: {
      outDir,
      emptyOutDir: true,
      sourcemap: mode === 'development',
    },
  };
});
