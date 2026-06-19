import { useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { ActionButton } from '../components/ActionButton';
import { BrandLogo } from '../components/BrandLogo';
import { HistoryStoryRow } from '../components/HistoryStoryRow';
import { useAuth } from '../hooks/useAuth';
import { useGuestStatus } from '../hooks/useGuestStatus';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { useActionFeedback } from '../hooks/useActionFeedback';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';
import { formatChapterDisplay, formatPartLabel } from '../utils/reading-display';
import { formatSyncResultMessage } from '../utils/sync-messages';
import { isVtqReading, openVtqChapter } from '../popup/vtq-open';
import { SafariSetupBanner } from './SafariSetupBanner';

type CompanionHomeProps = {
  onOpenHistory: () => void;
};

export function CompanionHome({ onOpenHistory }: CompanionHomeProps) {
  const { auth, loading: authLoading, error, startWebAuth, logout } = useAuth();
  const isGuest = !authLoading && !auth;
  const { guestStatus } = useGuestStatus(isGuest);
  const { session, loading: readingLoading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const syncAction = useActionFeedback();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);

  useEffect(() => {
    void browser.runtime
      .sendMessage({ type: MESSAGE_TYPES.GET_READING_HISTORY })
      .then((res) => {
        if (res?.success) setHistory(res.data as ReadingHistoryEntry[]);
      });
  }, [session]);

  const preview = history.slice(0, 3);
  const modeLabel = auth ? (auth.mode === 'internal' ? 'Internal' : 'Commercial') : 'Local only';
  const modeBadge = auth
    ? auth.mode === 'internal'
      ? 'st-badge--internal'
      : 'st-badge--commercial'
    : 'st-badge--guest';

  return (
    <div className="companion-page">
      <section className="companion-hero st-card">
        <div className="companion-hero__brand">
          <BrandLogo size={48} />
          <div>
            <p className="companion-hero__title">Story Tracker</p>
            <p className="companion-hero__sub">
              {auth ? auth.user.email : `Guest · ${guestStatus.storyCount}/${guestStatus.maxStories} truyện`}
            </p>
          </div>
        </div>
        <div className="companion-hero__chips">
          <span className={`st-badge ${modeBadge}`}>{modeLabel}</span>
          {auth ? (
            <span className={`st-badge ${status.online !== false ? 'st-badge--online' : 'st-badge--offline'}`}>
              {status.online !== false ? 'Online' : 'Offline'}
              {status.pendingCount > 0 ? ` · ${status.pendingCount} pending` : ''}
            </span>
          ) : (
            <span className="st-badge st-badge--guest-muted">Chỉ lưu máy</span>
          )}
        </div>
        <div className="companion-hero__actions">
          {auth ? (
            <ActionButton variant="ghost" onClick={() => void logout()}>
              Đăng xuất
            </ActionButton>
          ) : (
            <ActionButton
              variant="primary"
              block
              loading={authLoading}
              loadingLabel="Đang mở Personal OS…"
              onClick={() => void startWebAuth()}
            >
              Đăng nhập Personal OS
            </ActionButton>
          )}
          {auth ? (
            <ActionButton
              variant="secondary"
              block
              loading={syncAction.isLoading}
              success={syncAction.isSuccess}
              loadingLabel="Đang đồng bộ…"
              successLabel="Đã đồng bộ"
              disabled={status.online === false && !syncAction.isLoading}
              onClick={() => {
                void syncAction.run(async () => {
                  const result = await syncNow();
                  setSyncMessage(formatSyncResultMessage(result));
                });
              }}
            >
              Đồng bộ tất cả lên DB
            </ActionButton>
          ) : null}
        </div>
        {syncMessage ? (
          <p className="companion-tip__body" role="status">
            {syncMessage}
          </p>
        ) : null}
        {error ? (
          <p className="companion-error" role="alert">
            {error}
          </p>
        ) : null}
      </section>

      <SafariSetupBanner />

      <section className="st-card companion-tip" aria-label="Safari usage">
        <p className="st-card__eyebrow">Đọc & lưu tiến độ</p>
        <p className="companion-tip__body">
          Mở truyện trong <strong>Safari</strong>, bấm nút <strong>aA</strong> trên thanh địa chỉ → chọn{' '}
          <strong>Story Tracker</strong> để Save / Sync trang đang đọc. App này không thay thế bước đó.
        </p>
      </section>

      {readingLoading ? (
        <section className="st-card companion-skeleton" aria-hidden>
          <div className="st-skeleton" style={{ height: 12, width: '35%' }} />
          <div className="st-skeleton" style={{ height: 18, width: '85%', marginTop: 10 }} />
          <div className="st-skeleton" style={{ height: 8, width: '100%', marginTop: 12 }} />
        </section>
      ) : session ? (
        <section className="st-card st-card--featured">
          <p className="st-card__eyebrow">Đang đọc (gần nhất)</p>
          <h2 className="companion-reading__title">{session.readingInfo.storyTitle}</h2>
          {formatPartLabel(session.readingInfo) ? (
            <p className="companion-reading__meta">{formatPartLabel(session.readingInfo)}</p>
          ) : null}
          <p className="companion-reading__chapter">{formatChapterDisplay(session.readingInfo)}</p>
          <div className="st-progress" aria-hidden>
            <div
              className="st-progress__fill"
              style={{ width: `${session.readingInfo.progress.percentage}%` }}
            />
          </div>
          <p className="companion-reading__pct">{session.readingInfo.progress.percentage}%</p>
          {session.readingInfo.currentUrl ? (
            isVtqReading(session.readingInfo) ? (
              <button
                type="button"
                className="companion-link-btn"
                onClick={() => void openVtqChapter(session.readingInfo)}
              >
                Mở chương trong Safari
              </button>
            ) : (
              <a
                className="companion-link-btn"
                href={session.readingInfo.currentUrl}
                target="_blank"
                rel="noopener noreferrer"
              >
                Mở chương trong Safari
              </a>
            )
          ) : null}
        </section>
      ) : (
        <section className="st-card companion-empty">
          <p className="companion-empty__title">Chưa có tiến độ</p>
          <p className="companion-empty__hint">
            Đọc một chương trong Safari với extension đã bật — dữ liệu sẽ hiện ở đây.
          </p>
        </section>
      )}

      {preview.length > 0 ? (
        <section className="st-card">
          <div className="st-card__header">
            <p className="st-card__eyebrow">Gần đây</p>
            <button type="button" className="companion-link-btn companion-link-btn--inline" onClick={onOpenHistory}>
              Xem tất cả ({history.length})
            </button>
          </div>
          <ul className="history-list history-list--full">
            {preview.map((entry) => (
              <HistoryStoryRow key={`${entry.storyId}:${entry.lastReadAt}`} entry={entry} isGuest={isGuest} />
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
