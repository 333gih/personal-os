import { useEffect, useState, type FormEvent } from 'react';
import browser from 'webextension-polyfill';
import { useAuth } from '../hooks/useAuth';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { MESSAGE_TYPES } from '../shared/messages';
import type { AuthMode } from '../auth/types';
import type { ReadingHistoryEntry } from '../types/reading';

type CommercialView = 'login' | 'register';

export function App() {
  const { auth, loading: authLoading, error, login, register, logout } = useAuth();
  const { session, loading: readingLoading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const [authMode, setAuthMode] = useState<AuthMode>('commercial');
  const [commercialView, setCommercialView] = useState<CommercialView>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [syncing, setSyncing] = useState(false);

  useEffect(() => {
    void browser.runtime
      .sendMessage({ type: MESSAGE_TYPES.GET_READING_HISTORY })
      .then((res) => {
        if (res?.success) setHistory(res.data as ReadingHistoryEntry[]);
      });
  }, [session]);

  const handleLogin = async (e: FormEvent) => {
    e.preventDefault();
    await login(email, password, authMode);
  };

  const handleRegister = async (e: FormEvent) => {
    e.preventDefault();
    await register(email, password, name);
  };

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

        <div className="auth-mode-tabs">
          <button
            type="button"
            className={`auth-mode-tab ${authMode === 'internal' ? 'active' : ''}`}
            onClick={() => setAuthMode('internal')}
          >
            Internal
          </button>
          <button
            type="button"
            className={`auth-mode-tab ${authMode === 'commercial' ? 'active' : ''}`}
            onClick={() => setAuthMode('commercial')}
          >
            Commercial
          </button>
        </div>

        <div className="card">
          {authMode === 'internal' ?
            <>
              <h2>Internal Sign In</h2>
              <p className="auth-hint">
                Staff accounts only. Your account must have admin access.
              </p>
              <form onSubmit={handleLogin} className="form-group" style={{ marginTop: 8 }}>
                <label htmlFor="email">Email</label>
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoComplete="email"
                />
                <label htmlFor="password">Password</label>
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  minLength={8}
                  autoComplete="current-password"
                />
                {error && <p className="error-text">{error}</p>}
                <button type="submit" className="btn btn-primary" disabled={authLoading}>
                  {authLoading ? 'Signing in...' : 'Sign In'}
                </button>
              </form>
            </>
          : <>
              <div className="auth-mode-tabs auth-mode-tabs--sub">
                <button
                  type="button"
                  className={`auth-mode-tab ${commercialView === 'login' ? 'active' : ''}`}
                  onClick={() => setCommercialView('login')}
                >
                  Sign In
                </button>
                <button
                  type="button"
                  className={`auth-mode-tab ${commercialView === 'register' ? 'active' : ''}`}
                  onClick={() => setCommercialView('register')}
                >
                  Register
                </button>
              </div>

              {commercialView === 'login' ?
                <form onSubmit={handleLogin} className="form-group" style={{ marginTop: 8 }}>
                  <h2>Commercial Sign In</h2>
                  <label htmlFor="email-commercial">Email</label>
                  <input
                    id="email-commercial"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                  />
                  <label htmlFor="password-commercial">Password</label>
                  <input
                    id="password-commercial"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={8}
                    autoComplete="current-password"
                  />
                  {error && <p className="error-text">{error}</p>}
                  <button type="submit" className="btn btn-primary" disabled={authLoading}>
                    {authLoading ? 'Signing in...' : 'Sign In'}
                  </button>
                </form>
              : <form onSubmit={handleRegister} className="form-group" style={{ marginTop: 8 }}>
                  <h2>Create Account</h2>
                  <label htmlFor="name">Name</label>
                  <input
                    id="name"
                    type="text"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    autoComplete="name"
                  />
                  <label htmlFor="email-register">Email</label>
                  <input
                    id="email-register"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                  />
                  <label htmlFor="password-register">Password</label>
                  <input
                    id="password-register"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={8}
                    autoComplete="new-password"
                  />
                  {error && <p className="error-text">{error}</p>}
                  <button type="submit" className="btn btn-primary" disabled={authLoading}>
                    {authLoading ? 'Creating account...' : 'Register'}
                  </button>
                </form>
              }
            </>
          }
        </div>
      </div>
    );
  }

  const info = session?.readingInfo;
  const percentage = info?.progress.percentage ?? 0;

  return (
    <div className="container">
      <div className="header">
        <h1>Story Tracker</h1>
        <span className={`badge badge-${status.state}`}>{status.state}</span>
      </div>

      <div className="card">
        <h2>Currently Reading</h2>
        {readingLoading ?
          <p className="empty-state">Loading...</p>
        : info ?
          <>
            <p className="story-title">{info.storyTitle}</p>
            {info.chapterTitle && <p className="chapter-title">{info.chapterTitle}</p>}
            <div className="progress-bar">
              <div className="progress-fill" style={{ width: `${percentage}%` }} />
            </div>
            <p className="progress-label">{percentage}% read</p>
          </>
        : <p className="empty-state">No active reading session. Open a supported story site.</p>}
      </div>

      <div className="actions">
        <button className="btn btn-secondary" onClick={handleManualSave} disabled={!info}>
          Save Now
        </button>
        <button className="btn btn-primary" onClick={handleSync} disabled={syncing}>
          {syncing ? 'Syncing...' : 'Sync Now'}
        </button>
      </div>

      {history.length > 0 && (
        <div className="card">
          <h2>Recent History</h2>
          <ul className="history-list">
            {history.slice(0, 5).map((entry) => (
              <li key={`${entry.storyId}-${entry.lastReadAt}`} className="history-item">
                <strong>{entry.storyTitle}</strong>
                <span>
                  {entry.chapterTitle ?? 'Unknown chapter'} · {entry.progress.percentage}%
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="footer">
        <span>
          {auth.user.email}
          {auth.mode === 'internal' && auth.user.isAdmin && ' · admin'}
          {status.pendingCount > 0 && ` · ${status.pendingCount} pending`}
        </span>
        <div>
          <button className="btn btn-ghost" onClick={openOptions}>
            Settings
          </button>
          <button className="btn btn-ghost" onClick={logout}>
            Logout
          </button>
        </div>
      </div>
    </div>
  );
}
