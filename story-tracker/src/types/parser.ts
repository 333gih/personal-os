import type { ReadingInfo } from '../types/reading';
import type { ChapterClickHint } from '../content/chapter-hint';

export interface StoryParser {
  readonly siteId: string;
  readonly priority: number;

  canHandle(url: string): boolean;
  extract(): Promise<ReadingInfo>;
}

export interface ParserContext {
  document: Document;
  window: Window;
  url: string;
  chapterHint?: ChapterClickHint | null;
  /** Manual sync: scan full mục lục + current title/select (VTQ postback). */
  syncMode?: boolean;
}
