import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  define: {
    __DEFAULT_SYNC_INTERVAL_MS__: '30000',
    __PERSONAL_OS_FE_URL__: JSON.stringify('https://personal-os-fe.fashandcurious.com'),
    __API_BASE_URL__: JSON.stringify('https://api-personal-os.fashandcurious.com/api/v1'),
    __AUTH_API_URL__: JSON.stringify('https://api-auth.fashandcurious.com'),
    __BROWSER_TARGET__: JSON.stringify('firefox'),
    __API_TIMEOUT__: '30000',
    __AUTH_LOCALE__: JSON.stringify('vi'),
    __INTERNAL_APPLICATION_ID__: JSON.stringify(''),
    __COMMERCIAL_APPLICATION_ID__: JSON.stringify(''),
    __API_READING_PROGRESS__: JSON.stringify('/reading-progress'),
    __API_READING_PROGRESS_CURRENT__: JSON.stringify('/reading-progress/current'),
  },
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['src/**/*.test.ts'],
    setupFiles: ['src/test-setup.ts'],
  },
});
