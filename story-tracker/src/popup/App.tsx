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
import {
  GUEST_LIMIT_CODE,
  GUEST_LIMIT_MESSAGE,
  GUEST_UPSELL_BODY,
  GUEST_UPSELL_TITLE,
} from '../guest/guest-mode';
import { isIosAppTarget } from '../platform/capabilities';
import { MESSAGE_TYPES } from '../shared/messages';
import type { MessageResponse } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';
import { formatChapterDisplay, formatPartLabel } from '../utils/reading-display';
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
    else if (syncAction.isError) {
      setToast(
        syncAction.lastError ??
          status.lastError ??
          'Sync failed. Check login or network.',
      );
    }
    else if (saveAction.isSuccess) {
      setToast(isGuest ? 'Progress saved locally.' : 'Progress saved.');
    } else if (syncAction.isSuccess) setToast('Synced to Personal OS.');
    else setToast(null);
  }, [saveAction.isError, saveAction.isSuccess, syncAction.isError, syncAction.isSuccess, syncAction.lastError, status.lastError, isGuest]);

  const handleGuestLimit = (response: MessageResponse) => {
    if (response?.code === GUEST_LIMIT_CODE) {
      window.alert(response.error ?? GUEST_LIMIT_MESSAGE);
      return true;
    }
    return false;
  };

  const handleSync = () => {
    if (isIosAppTarget) {
      setToast('Mở Safari, bật extension Story Tracker, rồi Sync trên trang chương.');
      return;
    }
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
    if (isIosAppTarget) {
      setToast('Mở Safari, bật extension Story Tracker, rồi Save trên trang chương.');
      return;
    }
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

  const visibleHistory = history.slice(0, isGuest ? guestStatus.maxStories : 5);

  return (
    <div className="popup">
      <div className="popup__topbar">
        <div className="popup__brand">
          <BrandLogo size={36} />
          <div>
            <h1 className="popup__title">Story Tracker</h1>
            <p className="popup__meta">{subtitle}</p>
          </div>
        </div>
        <ActionButton variant="icon" onClick={openOptions} title="Settings" aria-label="Settings">
          ⚙
        </ActionButton>
      </div>

      <div className="popup__chips">
        <span className={`st-badge ${modeBadge}`}>{modeLabel}</span>
        {auth ? (
          <span className={`st-badge ${status.online !== false ? 'st-badge--online' : 'st-badge--offline'}`}>
            <span className={`status-dot ${status.online !== false ? 'online' : 'offline'}`} />
            {status.online !== false ? 'Online' : 'Offline'}
            {status.pendingCount > 0 ? ` · ${status.pendingCount}` : ''}
          </span>
        ) : (
          <span className="st-badge st-badge--guest-muted">Local</span>
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

      <div className="popup__body">

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
        <section className="st-card st-card--featured reading-card">
          <p className="st-card__eyebrow">Reading</p>
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
                Open chapter
              </button>
            ) : (
              <a
                className="reading-card__open-link"
                href={session.readingInfo.currentUrl}
                target="_blank"
                rel="noopener noreferrer"
              >
                Open chapter
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
          <p className="empty-card__title">Chưa nhận diện chương</p>
          <p className="empty-card__hint">
            {isIosAppTarget
              ? 'Mở chương truyện trong Safari (vd. /chuong-26/) với extension đã bật.'
              : 'Mở URL chương (vd. /chuong-26/) rồi bấm Save.'}
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
          {isIosAppTarget ? 'Save trong Safari' : 'Save progress'}
        </ActionButton>
        <ActionButton
          variant="primary"
          block
          loading={syncAction.isLoading}
          success={syncAction.isSuccess}
          loadingLabel={isGuest ? 'Opening…' : 'Syncing…'}
          successLabel={isGuest ? 'Done' : 'Synced'}
          disabled={!isGuest && status.online === false && !syncAction.isLoading}
          onClick={handleSync}
        >
          {isIosAppTarget ? 'Sync trong Safari' : isGuest ? 'Sign in to sync' : 'Sync to Personal OS'}
        </ActionButton>
      </div>

      {visibleHistory.length > 0 ? (
        <section className="st-card history-card">
          <div className="st-card__header">
            <p className="st-card__eyebrow">History</p>
            <span className="st-card__count">{visibleHistory.length}</span>
          </div>
          {isGuest ? (
            <p className="history-card__hint">
              Local only · max {guestStatus.maxStories}. Remove a story to free a slot.
            </p>
          ) : null}
          <ul className="history-list">
            {visibleHistory.map((entry) => (
              <HistoryStoryRow
                key={`${entry.storyId}:${entry.lastReadAt}`}
                entry={entry}
                isGuest={isGuest}
                onRemove={handleRemoveStory}
              />
            ))}
          </ul>
        </section>
      ) : null}

        <p className="popup__footer">
          <strong>Fash</strong> · Personal OS
        </p>
      </div>
    </div>
  );
}
