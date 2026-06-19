import { useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { HistoryStoryRow } from '../components/HistoryStoryRow';
import { useAuth } from '../hooks/useAuth';
import { useGuestStatus } from '../hooks/useGuestStatus';
import { useReadingState } from '../hooks/useReadingState';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';

export function CompanionHistory() {
  const { auth, loading: authLoading } = useAuth();
  const isGuest = !authLoading && !auth;
  const { guestStatus, refresh: refreshGuest } = useGuestStatus(isGuest);
  const { session } = useReadingState();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);

  const loadHistory = () => {
    void browser.runtime
      .sendMessage({ type: MESSAGE_TYPES.GET_READING_HISTORY })
      .then((res) => {
        if (res?.success) setHistory(res.data as ReadingHistoryEntry[]);
      });
  };

  useEffect(() => {
    loadHistory();
  }, [session]);

  const handleRemoveStory = (storyId: string, storyTitle: string) => {
    if (!window.confirm(`Xóa "${storyTitle}" khỏi tiến độ local?`)) return;
    void browser.runtime
      .sendMessage({
        type: MESSAGE_TYPES.REMOVE_STORY_PROGRESS,
        payload: { storyId },
      })
      .then(() => {
        loadHistory();
        void refreshGuest();
      });
  };

  const visible = history.slice(0, isGuest ? guestStatus.maxStories : history.length);

  return (
    <div className="companion-page">
      <section className="st-card">
        <p className="st-card__eyebrow">Lịch sử đọc</p>
        <p className="companion-history__lead">
          {isGuest
            ? `Local only · tối đa ${guestStatus.maxStories} truyện. Mở từng mục trong Safari để tiếp tục đọc.`
            : 'Đồng bộ với Personal OS khi bạn Save / Sync trong Safari.'}
        </p>
        {visible.length === 0 ? (
          <p className="companion-empty__hint">Chưa có truyện nào. Hãy đọc và lưu trong Safari extension.</p>
        ) : (
          <ul className="history-list history-list--full">
            {visible.map((entry) => (
              <HistoryStoryRow
                key={`${entry.storyId}:${entry.lastReadAt}`}
                entry={entry}
                isGuest={isGuest}
                onRemove={isGuest ? handleRemoveStory : undefined}
              />
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
