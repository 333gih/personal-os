import { useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { ActionButton } from '../components/ActionButton';
import { BrandLogo } from '../components/BrandLogo';
import { useAuth } from '../hooks/useAuth';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { useActionFeedback } from '../hooks/useActionFeedback';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';

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
  const { session, loading: readingLoading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const saveAction = useActionFeedback();
  const syncAction = useActionFeedback();
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    void browser.runtime
      .sendMessage({ type: MESSAGE_TYPES.GET_READING_HISTORY })
      .then((res) => {
        if (res?.success) setHistory(res.data as ReadingHistoryEntry[]);
      });
  }, [session]);

  useEffect(() => {
    if (saveAction.isError) setToast('Could not save on this page.');
    else if (syncAction.isError) setToast(status.lastError ?? 'Sync failed. Check login or network.');
    else if (saveAction.isSuccess) setToast('Progress saved.');
    else if (syncAction.isSuccess) setToast('Synced to Personal OS.');
    else setToast(null);
  }, [saveAction.isError, saveAction.isSuccess, syncAction.isError, syncAction.isSuccess, status.lastError]);

  const handleSync = () => {
    void syncAction.run(async () => {
      await syncNow();
    });
  };

  const handleManualSave = () => {
    void saveAction.run(async () => {
      const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
      if (!tab?.id) throw new Error('No active tab');
      await browser.tabs.sendMessage(tab.id, { type: MESSAGE_TYPES.MANUAL_SAVE });
    });
  };

  const openOptions = () => {
    void browser.runtime.openOptionsPage();
  };

  if (!auth) {
    return (
      <div className="popup">
        <header className="popup__header">
          <div className="popup__brand">
            <BrandLogo size={40} className="popup__logo" />
            <div>
              <h1 className="popup__title">Story Tracker</h1>
              <p className="popup__subtitle">Personal OS reading sync</p>
            </div>
          </div>
        </header>

        <section className="st-card auth-card">
          <p className="st-card__eyebrow">Sign in</p>
          <h2 className="auth-card__heading">Continue with Personal OS</h2>
          <p className="auth-card__hint">
            Same login as the web app: Internal SSO (Admin Portal) or Commercial (Google, email,
            password).
          </p>
          {error ?
            <p className="auth-card__error" role="alert">
              {error}
            </p>
          : null}
          <ActionButton
            variant="primary"
            block
            loading={authLoading}
            loadingLabel="Opening Personal OS…"
            onClick={() => void startWebAuth()}
            style={{ marginTop: 14 }}
          >
            Continue to Personal OS
          </ActionButton>
          <p className="auth-card__meta">
            Channel <code>story_tracker_extension</code>
          </p>
        </section>
      </div>
    );
  }

  const modeBadge =
    auth.mode === 'internal' ? 'st-badge--internal' : 'st-badge--commercial';

  return (
    <div className="popup">
      <header className="popup__header">
        <div className="popup__brand">
          <BrandLogo size={40} className="popup__logo" />
          <div>
            <h1 className="popup__title">Story Tracker</h1>
            <p className="popup__subtitle">{auth.user.email}</p>
          </div>
        </div>
        <ActionButton variant="icon" onClick={openOptions} title="Settings" aria-label="Settings">
          ⚙
        </ActionButton>
      </header>

      <div className="popup__toolbar">
        <span className={`st-badge ${modeBadge}`}>{auth.mode}</span>
        <span className={`st-badge ${status.online !== false ? 'st-badge--online' : 'st-badge--offline'}`}>
          <span className={`status-dot ${status.online !== false ? 'online' : 'offline'}`} />
          {status.online !== false ? 'Online' : 'Offline'}
          {status.pendingCount > 0 ? ` · ${status.pendingCount} pending` : ''}
          {status.lastError && status.state === 'error' ? ' · sync error' : ''}
        </span>
        <button type="button" className="link-btn" onClick={() => void logout()}>
          Log out
        </button>
      </div>

      {toast ?
        <div
          className={`st-toast ${saveAction.isError || syncAction.isError ? 'st-toast--error' : 'st-toast--success'}`}
          role="status"
        >
          {toast}
        </div>
      : null}

      {readingLoading ?
        <ReadingSkeleton />
      : session ?
        <section className="st-card reading-card">
          <p className="st-card__eyebrow">Currently reading</p>
          <h2 className="reading-card__title">{session.readingInfo.storyTitle}</h2>
          <p className="reading-card__chapter">
            {session.readingInfo.chapterTitle ?? 'Current chapter'}
          </p>
          <div className="st-progress" aria-hidden>
            <div
              className="st-progress__fill"
              style={{ width: `${session.readingInfo.progress.percentage}%` }}
            />
          </div>
          <div className="reading-card__meta">
            <span>{session.readingInfo.progress.percentage}% read</span>
            {session.readingInfo.progress.readingTimeSeconds > 0 ?
              <span>{Math.round(session.readingInfo.progress.readingTimeSeconds / 60)} min</span>
            : null}
          </div>
        </section>
      : <section className="st-card empty-card">
          <p className="empty-card__icon" aria-hidden>
            📖
          </p>
          <p className="empty-card__title">No chapter detected</p>
          <p className="empty-card__hint">
            Open a chapter page (e.g. TruyenFull <code>/chuong-26/</code>) on this tab, then use Save
            Now.
          </p>
        </section>
      }

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
          loadingLabel="Syncing…"
          successLabel="Synced"
          disabled={status.online === false && !syncAction.isLoading}
          onClick={handleSync}
        >
          Sync
        </ActionButton>
      </div>

      {history.length > 0 ?
        <section className="st-card history-card">
          <p className="st-card__eyebrow">Recent stories</p>
          <ul className="history-list">
            {history.slice(0, 5).map((entry) => (
              <li key={`${entry.storyId}:${entry.lastReadAt}`} className="history-item">
                <div className="history-item__main">
                  <strong>{entry.storyTitle}</strong>
                  <span>{entry.chapterTitle ?? entry.chapterId ?? 'Latest chapter'}</span>
                </div>
                <span className="history-item__pct">{entry.progress.percentage}%</span>
              </li>
            ))}
          </ul>
        </section>
      : null}
    </div>
  );
}
