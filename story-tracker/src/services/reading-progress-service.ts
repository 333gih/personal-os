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
    const raw = await this.client.get<{ items: Array<Record<string, unknown>> }>(
      config.endpoints.readingProgressCurrent,
    );

    return {
      items: (raw.items ?? []).map((item) => ({
        storyId: String(item.story_id ?? ''),
        storyTitle: String(item.story_title ?? ''),
        chapterId: item.chapter_id ? String(item.chapter_id) : undefined,
        chapterTitle: item.chapter_title ? String(item.chapter_title) : undefined,
        currentUrl: String(item.current_url ?? ''),
        progress: {
          percentage: Number(item.progress_percentage ?? 0),
          scrollY: Number(item.scroll_y ?? 0),
          readingTimeSeconds: Number(item.reading_time_seconds ?? 0),
        },
        metadata: (item.metadata as Record<string, unknown> | undefined) ?? undefined,
        clientTimestamp: item.last_read_at
          ? Date.parse(String(item.last_read_at))
          : Date.now(),
      })),
    };
  }
}

export function createGatewayClient(): ApiClient {
  return new ApiClient({
    config: createGatewayApiConfig(),
    getAccessToken: () => tokenManager.requireAccessToken(),
    onUnauthorized: async () => {
      const refreshed = await authService.refreshTokens();
      return refreshed !== null;
    },
    requireAuth: true,
  });
}

let sharedGatewayClient: ApiClient | null = null;

export function getGatewayClient(): ApiClient {
  if (!sharedGatewayClient) {
    sharedGatewayClient = createGatewayClient();
  }
  return sharedGatewayClient;
}

export function createReadingProgressService(): ReadingProgressService {
  return new ReadingProgressService(getGatewayClient());
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
