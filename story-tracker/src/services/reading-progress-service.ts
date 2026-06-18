import type {
  ReadingProgressCurrentResponse,
  ReadingProgressPayload,
} from '../types/api';
import { ApiClient } from './api-client';
import { createGatewayApiConfig } from './api-config';
import { authService } from '../auth/auth-service';
import { tokenManager } from '../auth/token-manager';

export class ReadingProgressService {
  constructor(private readonly client: ApiClient) {}

  async saveProgress(payload: ReadingProgressPayload): Promise<void> {
    const config = createGatewayApiConfig();
    await this.client.post(config.endpoints.readingProgress, {
      story_id: payload.storyId,
      story_title: payload.storyTitle,
      chapter_id: payload.chapterId,
      chapter_title: payload.chapterTitle,
      current_url: payload.currentUrl,
      progress: {
        percentage: payload.progress.percentage,
        scroll_y: payload.progress.scrollY,
        reading_time_seconds: payload.progress.readingTimeSeconds,
      },
      metadata: payload.metadata,
      client_timestamp: payload.clientTimestamp,
    });
  }

  async getCurrentProgress(): Promise<ReadingProgressCurrentResponse> {
    const config = createGatewayApiConfig();
    return this.client.get<ReadingProgressCurrentResponse>(
      config.endpoints.readingProgressCurrent,
    );
  }
}

export function createGatewayClient(): ApiClient {
  return new ApiClient({
    config: createGatewayApiConfig(),
    getAccessToken: () => tokenManager.getAccessToken(),
    onUnauthorized: async () => {
      const refreshed = await authService.refreshTokens();
      return refreshed !== null;
    },
    requireAuth: true,
  });
}

export function createReadingProgressService(): ReadingProgressService {
  return new ReadingProgressService(createGatewayClient());
}

export async function isOnline(): Promise<boolean> {
  return navigator.onLine;
}

export function onConnectivityChange(callback: (online: boolean) => void): () => void {
  const handleOnline = () => callback(true);
  const handleOffline = () => callback(false);
  self.addEventListener('online', handleOnline);
  self.addEventListener('offline', handleOffline);
  return () => {
    self.removeEventListener('online', handleOnline);
    self.removeEventListener('offline', handleOffline);
  };
}
