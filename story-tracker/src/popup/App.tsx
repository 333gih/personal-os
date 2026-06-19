import { useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { ActionButton } from '../components/ActionButton';
import { BrandLogo } from '../components/BrandLogo';
import { useAuth } from '../hooks/useAuth';
import { useGuestStatus } from '../hooks/useGuestStatus';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { useActionFeedback } from '../hooks/useActionFeedback';
import {
  GUEST_LIMIT_CODE,
  GUEST_LIMIT_MESSAGE,
  GUEST_UPSELL_BODY,
  GUEST_UPSELL_TITLE,
} from '../guest/guest-mode';
import { MESSAGE_TYPES } from '../shared/messages';
import type { MessageResponse } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';
import { formatChapterDisplay, formatPartLabel, historyEntryToReadingInfo } from '../utils/reading-display';
import { isVtqReading, openVtqChapter } from './vtq-open';

function ReadingSkeleton() {
  return (
    <div className="st-card" aria-hidden>
      <div className="st-skeleton" style={{ height: 12, width: '40%', marginBottom: 10 }} />
      <div className="st-skeleton" style={{ height: 16, width: '90%', marginBottom: 8 }} />
      <div className="st-skeleton" style={{ height: 12, width: '55%', marginBottom: 12 }} />
      <div className="st-skeleton" style={{ height: 8, width: '100%' }} />
    </div>
  );
}

export function App() {
  const { auth, loading: authLoading, error, startWebAuth, logout } = useAuth();
  const isGuest = !authLoading && !auth;
  const { guestStatus, refresh: refreshGuest } = useGuestStatus(isGuest);
  const { session, loading: readingLoading, refresh: refreshReading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const saveAction = useActionFeedback();
  const syncAction = useActionFeedback();
  const [toast, setToast] = useState<string | null>(null);

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

  useEffect(() => {
    if (saveAction.isError) setToast('Could not save on this page.');
    else if (syncAction.isError) setToast(status.lastError ?? 'Sync failed. Check login or network.');
    else if (saveAction.isSuccess) {
      setToast(isGuest ? 'Progress saved locally.' : 'Progress saved.');
    } else if (syncAction.isSuccess) setToast('Synced to Personal OS.');
    else setToast(null);
  }, [saveAction.isError, saveAction.isSuccess, syncAction.isError, syncAction.isSuccess, status.lastError, isGuest]);

  const handleGuestLimit = (response: MessageResponse) => {
    if (response?.code === GUEST_LIMIT_CODE) {
      window.alert(response.error ?? GUEST_LIMIT_MESSAGE);
      return true;
    }
    return false;
  };

  const handleSync = () => {
    if (isGuest) {
      void startWebAuth();
      setToast('Sign in to sync progress to Personal OS.');
      return;
    }

    void syncAction.run(async () => {
      const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
      if (tab?.id) {
        const res = (await browser.tabs.sendMessage(tab.id, {
          type: MESSAGE_TYPES.MANUAL_SAVE,
          payload: { sync: true },
        })) as MessageResponse | undefined;
        if (res && handleGuestLimit(res)) return;
      }
      await syncNow();
    });
  };

  const handleManualSave = () => {
    void saveAction.run(async () => {
      const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
      if (!tab?.id) throw new Error('No active tab');
      const response = (await browser.tabs.sendMessage(tab.id, {
        type: MESSAGE_TYPES.MANUAL_SAVE,
      })) as MessageResponse | undefined;
      if (!response?.success) {
        if (response && handleGuestLimit(response)) {
          throw new Error('Guest story limit reached');
        }
        throw new Error(response?.error ?? 'Save failed');
      }
      if (isGuest) void refreshGuest();
      loadHistory();
    });
  };

  const handleRemoveStory = (storyId: string, storyTitle: string) => {
    if (
      !window.confirm(
        `Remove "${storyTitle}" from local progress? This frees a slot in guest mode.`,
      )
    ) {
      return;
    }
    void browser.runtime
      .sendMessage({
        type: MESSAGE_TYPES.REMOVE_STORY_PROGRESS,
        payload: { storyId },
      })
      .then(() => {
        loadHistory();
        void refreshGuest();
        void refreshReading();
        setToast('Story removed from local progress.');
      });
  };

  const openOptions = () => {
    void browser.runtime.openOptionsPage();
  };

  const subtitle = auth
    ? auth.user.email
    : `Local only · ${guestStatus.storyCount}/${guestStatus.maxStories} stories`;

  const modeBadge = auth
    ? auth.mode === 'internal'
      ? 'st-badge--internal'
      : 'st-badge--commercial'
    : 'st-badge--guest';

  const modeLabel = auth ? auth.mode : 'Local only';

  return (
    <div className="popup">
      <header className="popup__header">
        <div className="popup__brand">
          <BrandLogo size={40} className="popup__logo" />
          <div>
            <h1 className="popup__title">Story Tracker</h1>
            <p className="popup__subtitle">{subtitle}</p>
          </div>
        </div>
        <ActionButton variant="icon" onClick={openOptions} title="Settings" aria-label="Settings">
          ⚙
        </ActionButton>
      </header>

      <div className="popup__toolbar">
        <span className={`st-badge ${modeBadge}`}>{modeLabel}</span>
        {auth ? (
          <span className={`st-badge ${status.online !== false ? 'st-badge--online' : 'st-badge--offline'}`}>
            <span className={`status-dot ${status.online !== false ? 'online' : 'offline'}`} />
            {status.online !== false ? 'Online' : 'Offline'}
            {status.pendingCount > 0 ? ` · ${status.pendingCount} pending` : ''}
            {status.lastError && status.state === 'error' ? ' · sync error' : ''}
          </span>
        ) : (
          <span className="st-badge st-badge--guest-muted">No cloud sync</span>
        )}
        {auth ? (
          <button type="button" className="link-btn" onClick={() => void logout()}>
            Log out
          </button>
        ) : (
          <button
            type="button"
            className="link-btn link-btn--primary"
            onClick={() => void startWebAuth()}
            disabled={authLoading}
          >
            Sign in
          </button>
        )}
      </div>

      {isGuest ? (
        <section className="st-card guest-upsell" aria-label="Sign in benefits">
          <p className="st-card__eyebrow">{GUEST_UPSELL_TITLE}</p>
          <p className="guest-upsell__body">{GUEST_UPSELL_BODY}</p>
          {guestStatus.atLimit ? (
            <p className="guest-upsell__limit" role="status">
              Limit reached ({guestStatus.maxStories} stories). Remove one below (×) or sign in.
            </p>
          ) : null}
          <ActionButton
            variant="primary"
            block
            loading={authLoading}
            loadingLabel="Opening Personal OS…"
            onClick={() => void startWebAuth()}
          >
            Sign in to Personal OS
          </ActionButton>
          {error ? (
            <p className="auth-card__error" role="alert">
              {error}
            </p>
          ) : null}
        </section>
      ) : null}

      {toast ? (
        <div
          className={`st-toast ${saveAction.isError || syncAction.isError ? 'st-toast--error' : 'st-toast--success'}`}
          role="status"
        >
          {toast}
        </div>
      ) : null}

      {readingLoading ? (
        <ReadingSkeleton />
      ) : session ? (
        <section className="st-card reading-card">
          <p className="st-card__eyebrow">Currently reading</p>
          <h2 className="reading-card__title">{session.readingInfo.storyTitle}</h2>
          {formatPartLabel(session.readingInfo) ? (
            <p className="reading-card__part">{formatPartLabel(session.readingInfo)}</p>
          ) : null}
          <p className="reading-card__chapter">{formatChapterDisplay(session.readingInfo)}</p>
          {session.readingInfo.currentUrl ? (
            isVtqReading(session.readingInfo) ? (
              <button
                type="button"
                className="reading-card__open-link"
                onClick={() => void openVtqChapter(session.readingInfo)}
              >
                Open at this chapter →
              </button>
            ) : (
              <a
                className="reading-card__open-link"
                href={session.readingInfo.currentUrl}
                target="_blank"
                rel="noopener noreferrer"
              >
                Open at this chapter →
              </a>
            )
          ) : null}
          <div className="st-progress" aria-hidden>
            <div
              className="st-progress__fill"
              style={{ width: `${session.readingInfo.progress.percentage}%` }}
            />
          </div>
          <div className="reading-card__meta">
            <span>{session.readingInfo.progress.percentage}% read</span>
            {session.readingInfo.progress.readingTimeSeconds > 0 ? (
              <span>{Math.round(session.readingInfo.progress.readingTimeSeconds / 60)} min</span>
            ) : null}
          </div>
        </section>
      ) : (
        <section className="st-card empty-card">
          <p className="empty-card__icon" aria-hidden>
            📖
          </p>
          <p className="empty-card__title">No chapter detected</p>
          <p className="empty-card__hint">
            Open a chapter page (e.g. TruyenFull <code>/chuong-26/</code>) on this tab, then use Save
            Now.
          </p>
        </section>
      )}

      <div className="popup__actions">
        <ActionButton
          variant="secondary"
          block
          loading={saveAction.isLoading}
          success={saveAction.isSuccess}
          loadingLabel="Saving…"
          successLabel="Saved"
          onClick={handleManualSave}
        >
          Save now
        </ActionButton>
        <ActionButton
          variant="primary"
          block
          loading={syncAction.isLoading}
          success={syncAction.isSuccess}
          loadingLabel={isGuest ? 'Opening sign-in…' : 'Syncing…'}
          successLabel={isGuest ? 'Sign in' : 'Synced'}
          disabled={!isGuest && status.online === false && !syncAction.isLoading}
          onClick={handleSync}
        >
          {isGuest ? 'Sign in to sync' : 'Sync'}
        </ActionButton>
      </div>

      {history.length > 0 ? (
        <section className="st-card history-card">
          <p className="st-card__eyebrow">Recent stories</p>
          {isGuest ? (
            <p className="history-card__hint">
              Local only · max {guestStatus.maxStories}. Tap × to remove a story and free a slot.
            </p>
          ) : null}
          <ul className="history-list">
            {history.slice(0, isGuest ? guestStatus.maxStories : 5).map((entry) => (
              <li key={`${entry.storyId}:${entry.lastReadAt}`} className="history-item">
                <div className="history-item__main">
                  {entry.currentUrl ? (
                    <a
                      className="history-item__link"
                      href={entry.currentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <strong>{entry.storyTitle}</strong>
                    </a>
                  ) : (
                    <strong>{entry.storyTitle}</strong>
                  )}
                  <span>{formatChapterDisplay(historyEntryToReadingInfo(entry))}</span>
                </div>
                <div className="history-item__aside">
                  <span className="history-item__pct">{entry.progress.percentage}%</span>
                  {isGuest ? (
                    <button
                      type="button"
                      className="history-item__remove"
                      title="Remove from local progress"
                      aria-label={`Remove ${entry.storyTitle}`}
                      onClick={() => handleRemoveStory(entry.storyId, entry.storyTitle)}
                    >
                      ×
                    </button>
                  ) : null}
                </div>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
    </div>
  );
}
