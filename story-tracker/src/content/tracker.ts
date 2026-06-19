import browser from 'webextension-polyfill';
import { extractReadingInfo } from '../parsers';
import type { ReadingInfo } from '../types/reading';
import type { SiteProfile } from '../types/site-profile';
import { MESSAGE_TYPES } from '../shared/messages';
import { SCROLL_THROTTLE_MS, SYNC_DEBOUNCE_MS } from '../shared/constants';
import { debounce, throttle } from '../utils/debounce';
import { logger } from '../utils/logger';
import { isChapterPage } from '../parsers/page-classifier';
import { getActiveProfiles } from '../config/site-profile-store';
import { ChapterObserver } from './chapter-observer';
import { getChapterClickHint } from './chapter-hint';

export class ReadingTracker {
  private readingTimeSeconds = 0;
  private lastStoryId: string | null = null;
  private lastChapterKey: string | null = null;
  private isVisible = !document.hidden;
  private timerInterval: ReturnType<typeof setInterval> | null = null;
  private latestInfo: ReadingInfo | null = null;
  private profiles: SiteProfile[] = [];
  private chapterObserver: ChapterObserver | null = null;

  private readonly sendUpdate = debounce(() => {
    void this.flushUpdate();
  }, SYNC_DEBOUNCE_MS);

  private readonly onScroll = throttle(() => {
    this.sendUpdate();
  }, SCROLL_THROTTLE_MS);

  async start(): Promise<void> {
    this.profiles = await getActiveProfiles();

    if (!isChapterPage(window.location.href, this.profiles)) {
      logger.debug('Skipping tracker — not a chapter page', window.location.href);
      return;
    }

    logger.debug('Reading tracker started on chapter page');
    window.addEventListener('scroll', this.onScroll, { passive: true });
    window.addEventListener('hashchange', this.onHashChange);
    document.addEventListener('visibilitychange', this.onVisibilityChange);
    window.addEventListener('beforeunload', this.onUnload);
    window.addEventListener('pagehide', this.onUnload);

    this.chapterObserver = new ChapterObserver(() => {
      void this.extractAndNotify(true);
    });
    this.chapterObserver.start();

    this.timerInterval = setInterval(() => {
      if (this.isVisible) this.readingTimeSeconds += 1;
    }, 1000);

    void this.extractAndNotify(true);
  }

  stop(): void {
    window.removeEventListener('scroll', this.onScroll);
    window.removeEventListener('hashchange', this.onHashChange);
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    window.removeEventListener('beforeunload', this.onUnload);
    window.removeEventListener('pagehide', this.onUnload);
    this.chapterObserver?.stop();
    this.chapterObserver = null;
    if (this.timerInterval) clearInterval(this.timerInterval);
  }

  async manualSave(syncMode = false): Promise<import('../shared/messages').MessageResponse> {
    try {
      const info = await extractReadingInfo({
        document,
        window,
        url: window.location.href,
        chapterHint: getChapterClickHint(),
        syncMode,
      });

      if (!info) {
        return { success: false, error: 'No chapter detected on this page.' };
      }

      info.progress.readingTimeSeconds = this.readingTimeSeconds;
      this.lastStoryId = info.storyId;
      this.lastChapterKey = `${info.storyId}:${info.chapterId ?? ''}`;
      this.latestInfo = info;

      return await this.postUpdate(info, true, false);
    } catch (error) {
      logger.error('Failed to extract reading info', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Save failed',
      };
    }
  }

  private onHashChange = (): void => {
    if (!isChapterPage(window.location.href, this.profiles)) return;
    void this.extractAndNotify(true);
  };

  private onVisibilityChange = (): void => {
    const nowVisible = !document.hidden;
    if (!nowVisible && this.isVisible) void this.flushUpdate();
    this.isVisible = nowVisible;
  };

  private onUnload = (): void => {
    void this.flushUpdate(true);
  };

  private async extractAndNotify(
    force = false,
    manual = false,
    syncMode = false,
  ): Promise<ReadingInfo | null> {
    try {
      const info = await extractReadingInfo({
        document,
        window,
        url: window.location.href,
        chapterHint: getChapterClickHint(),
        syncMode,
      });

      if (!info) {
        logger.debug('No chapter reading info for this page');
        return null;
      }

      info.progress.readingTimeSeconds = this.readingTimeSeconds;

      const chapterKey = `${info.storyId}:${info.chapterId ?? ''}`;
      const storyChanged = this.lastStoryId !== null && this.lastStoryId !== info.storyId;
      const chapterChanged =
        this.lastChapterKey !== null && this.lastChapterKey !== chapterKey && !storyChanged;

      if (storyChanged || chapterChanged) {
        await browser.runtime.sendMessage({
          type: MESSAGE_TYPES.CHAPTER_CHANGED,
          payload: info,
        });
      }

      this.lastStoryId = info.storyId;
      this.lastChapterKey = chapterKey;
      this.latestInfo = info;

      if (force || manual) {
        await this.postUpdate(info, manual);
      } else {
        this.sendUpdate();
      }

      return info;
    } catch (error) {
      logger.error('Failed to extract reading info', error);
      return null;
    }
  }

  private async flushUpdate(isUnload = false): Promise<void> {
    if (!this.latestInfo) {
      const info = await this.extractAndNotify(true);
      if (!info) return;
    }

    const info = this.latestInfo!;
    info.progress.readingTimeSeconds = this.readingTimeSeconds;
    await this.postUpdate(info, false, isUnload);
  }

  private async postUpdate(
    info: ReadingInfo,
    manual = false,
    isUnload = false,
  ): Promise<import('../shared/messages').MessageResponse> {
    try {
      return (await browser.runtime.sendMessage({
        type: manual ? MESSAGE_TYPES.MANUAL_SAVE : MESSAGE_TYPES.READING_UPDATE,
        payload: { ...info, isUnload },
      })) as import('../shared/messages').MessageResponse;
    } catch (error) {
      logger.error('Failed to send reading update', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to send reading update',
      };
    }
  }
}
