export interface ApiConfig {
  baseUrl: string;
  timeout: number;
  endpoints: ApiEndpoints;
}

export interface ApiEndpoints {
  readingProgress: string;
  readingProgressCurrent: string;
}

export interface ApiErrorBody {
  message?: string;
  code?: string;
  error?: string;
  detail?: string;
  [key: string]: unknown;
}

export interface ReadingProgressPayload {
  storyId: string;
  storyTitle: string;
  chapterId?: string;
  chapterTitle?: string;
  currentUrl: string;
  progress: {
    percentage: number;
    scrollY: number;
    readingTimeSeconds: number;
  };
  metadata?: Record<string, unknown>;
  clientTimestamp: number;
}

export interface ReadingProgressCurrentResponse {
  items: ReadingProgressPayload[];
}
