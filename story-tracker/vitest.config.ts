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
  },
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['src/**/*.test.ts'],
    setupFiles: ['src/test-setup.ts'],
  },
});
