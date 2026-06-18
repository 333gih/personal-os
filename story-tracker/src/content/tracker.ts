import browser from 'webextension-polyfill';
import { extractReadingInfo } from '../parsers';
import type { ReadingInfo } from '../types/reading';
import { MESSAGE_TYPES } from '../shared/messages';
import { SCROLL_THROTTLE_MS, SYNC_DEBOUNCE_MS } from '../shared/constants';
import { debounce, throttle } from '../utils/debounce';
import { logger } from '../utils/logger';
import { isChapterPage } from '../parsers/page-classifier';

export class ReadingTracker {
  private readingTimeSeconds = 0;
  private lastStoryId: string | null = null;
  private isVisible = !document.hidden;
  private timerInterval: ReturnType<typeof setInterval> | null = null;
  private latestInfo: ReadingInfo | null = null;

  private readonly sendUpdate = debounce(() => {
    void this.flushUpdate();
  }, SYNC_DEBOUNCE_MS);

  private readonly onScroll = throttle(() => {
    this.sendUpdate();
  }, SCROLL_THROTTLE_MS);

  start(): void {
    if (!isChapterPage(window.location.href)) {
      logger.debug('Skipping tracker — not a chapter page', window.location.href);
      return;
    }

    logger.debug('Reading tracker started on chapter page');
    window.addEventListener('scroll', this.onScroll, { passive: true });
    document.addEventListener('visibilitychange', this.onVisibilityChange);
    window.addEventListener('beforeunload', this.onUnload);
    window.addEventListener('pagehide', this.onUnload);

    this.timerInterval = setInterval(() => {
      if (this.isVisible) {
        this.readingTimeSeconds += 1;
      }
    }, 1000);

    void this.extractAndNotify(true);
  }

  stop(): void {
    window.removeEventListener('scroll', this.onScroll);
    document.removeEventListener('visibilitychange', this.onVisibilityChange);
    window.removeEventListener('beforeunload', this.onUnload);
    window.removeEventListener('pagehide', this.onUnload);
    if (this.timerInterval) clearInterval(this.timerInterval);
  }

  async manualSave(): Promise<ReadingInfo | null> {
    return this.extractAndNotify(true, true);
  }

  private onVisibilityChange = (): void => {
    const nowVisible = !document.hidden;
    if (!nowVisible && this.isVisible) {
      void this.flushUpdate();
    }
    this.isVisible = nowVisible;
  };

  private onUnload = (): void => {
    void this.flushUpdate(true);
  };

  private async extractAndNotify(
    force = false,
    manual = false,
  ): Promise<ReadingInfo | null> {
    try {
      const info = await extractReadingInfo({
        document,
        window,
        url: window.location.href,
      });

      if (!info) {
        logger.debug('No chapter reading info for this page');
        return null;
      }

      info.progress.readingTimeSeconds = this.readingTimeSeconds;

      const storyChanged = this.lastStoryId !== null && this.lastStoryId !== info.storyId;

      if (storyChanged) {
        await browser.runtime.sendMessage({
          type: MESSAGE_TYPES.CHAPTER_CHANGED,
          payload: info,
        });
      }

      this.lastStoryId = info.storyId;
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
  ): Promise<void> {
    try {
      await browser.runtime.sendMessage({
        type: manual ? MESSAGE_TYPES.MANUAL_SAVE : MESSAGE_TYPES.READING_UPDATE,
        payload: { ...info, isUnload },
      });
    } catch (error) {
      logger.error('Failed to send reading update', error);
    }
  }
}
