import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';
import reactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';

export default [
  js.configs.recommended,
  {
    files: ['src/**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsparser,
      parserOptions: { ecmaVersion: 'latest', sourceType: 'module', ecmaFeatures: { jsx: true } },
      globals: {
        ...globals.browser,
        ...globals.webextensions,
        ...globals.serviceworker,
        __API_BASE_URL__: 'readonly',
        __API_TIMEOUT__: 'readonly',
        __AUTH_API_URL__: 'readonly',
        __AUTH_LOCALE__: 'readonly',
        __INTERNAL_APPLICATION_ID__: 'readonly',
        __COMMERCIAL_APPLICATION_ID__: 'readonly',
        __API_READING_PROGRESS__: 'readonly',
        __API_READING_PROGRESS_CURRENT__: 'readonly',
        __DEFAULT_SYNC_INTERVAL_MS__: 'readonly',
        __BROWSER_TARGET__: 'readonly',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      'react-hooks': reactHooks,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      ...reactHooks.configs.recommended.rules,
      'no-undef': 'off',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
  {
    files: ['src/**/*.test.ts'],
    languageOptions: {
      globals: {
        ...globals.vitest,
      },
    },
  },
];
