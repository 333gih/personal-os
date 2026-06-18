import { useEffect, useState } from 'react';
import browser from 'webextension-polyfill';
import { useAuth } from '../hooks/useAuth';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { MESSAGE_TYPES } from '../shared/messages';
import type { ReadingHistoryEntry } from '../types/reading';

export function App() {
  const { auth, loading: authLoading, error, startWebAuth, logout } = useAuth();
  const { session, loading: readingLoading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    void browser.runtime
      .sendMessage({ type: MESSAGE_TYPES.GET_READING_HISTORY })
      .then((res) => {
        if (res?.success) setHistory(res.data as ReadingHistoryEntry[]);
      });
  }, [session]);

  const handleSync = async () => {
    setSyncing(true);
    await syncNow();
    setSyncing(false);
  };

  const handleManualSave = async () => {
    const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
    if (tab?.id) {
      await browser.tabs.sendMessage(tab.id, { type: MESSAGE_TYPES.MANUAL_SAVE });
    }
  };

  const openOptions = () => {
    void browser.runtime.openOptionsPage();
  };

  if (!auth) {
    return (
      <div className="container">
        <div className="header">
          <h1>Story Tracker</h1>
        </div>

        <div className="card">
          <h2>Sign in with Personal OS</h2>
          <p className="auth-hint">
            Uses the same login as Personal OS web: Internal (Admin Portal SSO) or Commercial
            (Google, email code, password).
          </p>
          {error && <p className="error-text">{error}</p>}
          <button
            type="button"
            className="btn btn-primary"
            style={{ marginTop: 12 }}
            disabled={authLoading}
            onClick={() => void startWebAuth()}
          >
            {authLoading ? 'Opening Personal OS…' : 'Continue to Personal OS'}
          </button>
          <p className="auth-hint" style={{ marginTop: 12 }}>
            Channel: <code>story_tracker_extension</code>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="header">
        <h1>Story Tracker</h1>
        <button type="button" className="btn-icon" onClick={openOptions} title="Settings">
          ⚙
        </button>
      </div>

      <div className="user-bar">
        <span>{auth.user.email}</span>
        <span className="badge">{auth.mode}</span>
        <button type="button" className="btn-link" onClick={() => void logout()}>
          Logout
        </button>
      </div>

      {readingLoading ?
        <p>Loading...</p>
      : session ?
        <div className="card">
          <h2>Currently Reading</h2>
          <p className="story-title">{session.readingInfo.storyTitle}</p>
          <p className="chapter-title">{session.readingInfo.chapterTitle ?? 'Current chapter'}</p>
          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{ width: `${session.readingInfo.progress.percentage}%` }}
            />
          </div>
          <p className="progress-text">{session.readingInfo.progress.percentage}% complete</p>
        </div>
      : <div className="card empty-state">
          <p>No active reading session on this tab.</p>
        </div>
      }

      <div className="actions">
        <button type="button" className="btn btn-secondary" onClick={() => void handleManualSave()}>
          Save Now
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => void handleSync()}
          disabled={syncing || !status.online}
        >
          {syncing ? 'Syncing...' : 'Sync'}
        </button>
      </div>

      <div className="sync-status">
        <span className={`status-dot ${status.online ? 'online' : 'offline'}`} />
        {status.online ? 'Online' : 'Offline'}
        {status.pendingCount > 0 && ` · ${status.pendingCount} pending`}
      </div>

      {history.length > 0 && (
        <div className="card">
          <h3>Recent</h3>
          <ul className="history-list">
            {history.slice(0, 5).map((entry) => (
              <li key={`${entry.storyId}:${entry.chapterId ?? ''}:${entry.lastReadAt}`}>
                <strong>{entry.storyTitle}</strong>
                <span>{entry.chapterTitle ?? entry.chapterId}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
