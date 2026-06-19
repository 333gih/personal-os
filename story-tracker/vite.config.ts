import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import webExtension from 'vite-plugin-web-extension';
import { resolve } from 'path';
import { readFileSync } from 'fs';
import type { SiteRegistry } from './src/types/site-registry';
import { listBuiltinHostPatterns } from './src/config/site-profile-builtin';

const target = process.env.TARGET ?? 'firefox';
const isFirefox = target === 'firefox' || target === 'firefox-dev';
const isSafari = target === 'safari';
const isIosApp = target === 'ios-app';
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
  return listBuiltinHostPatterns();
}

function connectMatchForOrigin(origin: string): string | null {
  try {
    const url = new URL(origin);
    const port = url.port || (url.protocol === 'https:' ? '443' : '80');
    if (port === '80' || port === '443') {
      return `${url.protocol}//${url.hostname}/extension/connect*`;
    }
    return `${url.protocol}//${url.hostname}:${port}/extension/connect*`;
  } catch {
    return null;
  }
}

function loadPersonalOsFeConnectMatches(env: Record<string, string>): string[] {
  const origin = personalOsFeOrigin(env);
  const match = connectMatchForOrigin(origin);
  return [match ?? `${origin}/extension/connect*`];
}

function loadHostPermissions(env: Record<string, string>): string[] {
  const api = loadJsonFile<{ apiHostPermissions: string[] }>(
    resolve(__dirname, 'public/manifest/api-host-permissions.json'),
    { apiHostPermissions: [] },
  );
  const feOrigin = personalOsFeOrigin(env);
  return [
    ...new Set([
      ...loadSiteRegistryHostPatterns(),
      ...api.apiHostPermissions,
      `${feOrigin}/*`,
    ]),
  ];
}

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const outDir = `dist/${target}`;

  if (isIosApp) {
    const appRoot = resolve(__dirname, 'src/app-ios');
    return {
      root: appRoot,
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
        __BROWSER_TARGET__: JSON.stringify('ios-app'),
      },
      resolve: {
        alias: {
          '@': resolve(__dirname, 'src'),
          'webextension-polyfill': resolve(__dirname, 'src/platform/ios-app-browser.ts'),
        },
      },
      plugins: [react()],
      build: {
        outDir: resolve(__dirname, 'dist/ios-app'),
        emptyOutDir: true,
        sourcemap: mode === 'development',
        rollupOptions: {
          input: {
            main: resolve(appRoot, 'index.html'),
            'connect-bridge': resolve(__dirname, 'src/content/extension-connect-bridge.ts'),
          },
          output: {
            entryFileNames: (chunk) =>
              chunk.name === 'connect-bridge' ? 'connect-bridge.js' : 'assets/[name]-[hash].js',
            chunkFileNames: 'assets/[name]-[hash].js',
            assetFileNames: 'assets/[name]-[hash][extname]',
          },
        },
      },
    };
  }

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
    ...(isSafari ? {} : { optional_host_permissions: ['*://*/*'] }),
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
        // Safari uses Chromium-style MV3 output; Apple converts at sync time.
      }),
    ],
    build: {
      outDir,
      emptyOutDir: true,
      sourcemap: mode === 'development',
    },
  };
});
