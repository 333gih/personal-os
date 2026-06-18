import type { ApiConfig } from '../types/api';

export function createGatewayApiConfig(): ApiConfig {
  return {
    baseUrl: __API_BASE_URL__,
    timeout: __API_TIMEOUT__,
    endpoints: {
      readingProgress: __API_READING_PROGRESS__,
      readingProgressCurrent: __API_READING_PROGRESS_CURRENT__,
    },
  };
}
