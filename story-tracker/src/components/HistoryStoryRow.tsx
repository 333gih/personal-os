import type { ReadingHistoryEntry } from '../types/reading';
import { formatChapterDisplay, historyEntryToReadingInfo } from '../utils/reading-display';
import { isVtqReading, openVtqChapter } from '../popup/vtq-open';

type HistoryStoryRowProps = {
  entry: ReadingHistoryEntry;
  isGuest: boolean;
  onRemove?: (storyId: string, storyTitle: string) => void;
};

function siteLabel(siteId: string): string {
  if (siteId === 'vietnamthuquan') return 'VTQ';
  if (siteId === 'nettruyen') return 'NetTruyen';
  if (siteId === 'truyenfull') return 'TruyenFull';
  if (siteId === 'generic' || !siteId) return 'Web';
  return siteId.replace(/-/g, ' ');
}

export function HistoryStoryRow({ entry, isGuest, onRemove }: HistoryStoryRowProps) {
  const info = historyEntryToReadingInfo(entry);
  const vtq = isVtqReading(info);
  const pct = Math.max(0, Math.min(100, entry.progress.percentage));

  const openStory = () => {
    if (vtq) {
      void openVtqChapter(info);
      return;
    }
    if (entry.currentUrl) {
      window.open(entry.currentUrl, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <li className="history-row">
      <div className="history-row__body">
        <div className="history-row__top">
          <span className="history-row__site">{siteLabel(entry.siteId)}</span>
          <span className="history-row__pct">{pct}%</span>
        </div>
        {entry.currentUrl ? (
          <button type="button" className="history-row__title" onClick={openStory}>
            {entry.storyTitle}
          </button>
        ) : (
          <p className="history-row__title history-row__title--static">{entry.storyTitle}</p>
        )}
        <p className="history-row__chapter">{formatChapterDisplay(info)}</p>
        <div className="history-row__progress" aria-hidden>
          <div className="history-row__progress-fill" style={{ width: `${pct}%` }} />
        </div>
      </div>
      <div className="history-row__actions">
        {entry.currentUrl ? (
          <button
            type="button"
            className="history-row__open"
            title="Open story"
            aria-label={`Open ${entry.storyTitle}`}
            onClick={openStory}
          >
            Open
          </button>
        ) : null}
        {isGuest && onRemove ? (
          <button
            type="button"
            className="history-row__remove"
            title="Remove from local progress"
            aria-label={`Remove ${entry.storyTitle}`}
            onClick={() => onRemove(entry.storyId, entry.storyTitle)}
          >
            Remove
          </button>
        ) : null}
      </div>
    </li>
  );
}
