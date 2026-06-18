import type { ReadingInfo } from '../types/reading';

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
}
