import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import webExtension from 'vite-plugin-web-extension';
import { resolve } from 'path';
import { readFileSync } from 'fs';
import type { SiteRegistry } from './src/types/site-registry';

const target = process.env.TARGET ?? 'firefox';
const isFirefox = target === 'firefox' || target === 'firefox-dev';
const manifestFile =
  target === 'firefox-dev' ? 'firefox-dev.manifest.json' : `${target}.manifest.json`;

function loadJsonFile<T>(path: string, fallback: T): T {
  try {
    return JSON.parse(readFileSync(path, 'utf-8')) as T;
  } catch {
    return fallback;
  }
}

function personalOsFeOrigin(env: Record<string, string>): string {
  return (env.PERSONAL_OS_FE_URL ?? 'https://personal-os-fe.fashandcurious.com').replace(
    /\/+$/,
    '',
  );
}

function loadSiteRegistryHostPatterns(): string[] {
  const registry = loadJsonFile<SiteRegistry>(
    resolve(__dirname, 'src/config/site-registry.json'),
    { sites: [] },
  );
  return registry.sites.flatMap((site) => site.hostPatterns);
}

function loadHostPermissions(env: Record<string, string>): string[] {
  const api = loadJsonFile<{ apiHostPermissions: string[] }>(
    resolve(__dirname, 'public/manifest/api-host-permissions.json'),
    { apiHostPermissions: [] },
  );
  return [...loadSiteRegistryHostPatterns(), ...api.apiHostPermissions, `${personalOsFeOrigin(env)}/*`];
}

function loadPersonalOsFeConnectMatches(env: Record<string, string>): string[] {
  return [`${personalOsFeOrigin(env)}/extension/connect*`];
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const outDir = `dist/${target}`;

  const baseManifest = JSON.parse(
    readFileSync(
      resolve(__dirname, `public/manifest/${manifestFile}`),
      'utf-8',
    ),
  );

  const hostPermissions = loadHostPermissions(env);
  const storyMatches = loadSiteRegistryHostPatterns();
  const connectMatches = loadPersonalOsFeConnectMatches(env);

  const manifest = {
    ...baseManifest,
    host_permissions: hostPermissions,
    optional_host_permissions: ['*://*/*'],
    content_scripts: [
      {
        matches: storyMatches,
        js: ['src/content/index.ts'],
        run_at: 'document_idle',
      },
      {
        matches: connectMatches,
        js: ['src/content/extension-connect-bridge.ts'],
        run_at: 'document_start',
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
      __PERSONAL_OS_FE_URL__: JSON.stringify(
        env.PERSONAL_OS_FE_URL ?? 'https://personal-os-fe.fashandcurious.com',
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
