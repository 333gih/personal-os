import { useEffect, useState, type FormEvent } from 'react';
import browser from 'webextension-polyfill';
import { useAuth } from '../hooks/useAuth';
import { useReadingState } from '../hooks/useReadingState';
import { useSyncStatus } from '../hooks/useSyncStatus';
import { MESSAGE_TYPES } from '../shared/messages';
import type { AuthMode } from '../auth/types';
import type { ReadingHistoryEntry } from '../types/reading';

type CommercialView = 'login' | 'otp-request' | 'otp-verify';

export function App() {
  const { auth, loading: authLoading, error, login, requestOtp, verifyOtp, logout } = useAuth();
  const { session, loading: readingLoading } = useReadingState();
  const { status, syncNow } = useSyncStatus();
  const [history, setHistory] = useState<ReadingHistoryEntry[]>([]);
  const [authMode, setAuthMode] = useState<AuthMode>('commercial');
  const [commercialView, setCommercialView] = useState<CommercialView>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [otp, setOtp] = useState('');
  const [otpInfo, setOtpInfo] = useState('');
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

  const handleOtpRequest = async (e: FormEvent) => {
    e.preventDefault();
    setOtpInfo('');
    const result = await requestOtp(email);
    if (result) {
      setCommercialView('otp-verify');
      setOtpInfo(
        result.isNewUser
          ? 'Code sent. A new Fash account will be created after verification.'
          : 'Verification code sent to your email.',
      );
    }
  };

  const handleOtpVerify = async (e: FormEvent) => {
    e.preventDefault();
    await verifyOtp(email, otp);
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
            onClick={() => {
              setAuthMode('commercial');
              setCommercialView('login');
            }}
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
          : commercialView === 'login' ?
            <form onSubmit={handleLogin} className="form-group" style={{ marginTop: 8 }}>
              <h2>Commercial Sign In</h2>
              <p className="auth-hint">Uses the same Fash account as mobile apps.</p>
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
              <button
                type="button"
                className="btn btn-secondary"
                style={{ marginTop: 8 }}
                onClick={() => {
                  setCommercialView('otp-request');
                  setOtpInfo('');
                }}
              >
                Sign up with email code
              </button>
            </form>
          : commercialView === 'otp-request' ?
            <form onSubmit={handleOtpRequest} className="form-group" style={{ marginTop: 8 }}>
              <h2>Email verification</h2>
              <p className="auth-hint">
                We will send a one-time code. New accounts sync to Fash iOS/Android.
              </p>
              <label htmlFor="email-otp">Email</label>
              <input
                id="email-otp"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
              {error && <p className="error-text">{error}</p>}
              <button type="submit" className="btn btn-primary" disabled={authLoading}>
                {authLoading ? 'Sending...' : 'Send code'}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ marginTop: 8 }}
                onClick={() => setCommercialView('login')}
              >
                Back
              </button>
            </form>
          : <form onSubmit={handleOtpVerify} className="form-group" style={{ marginTop: 8 }}>
              <h2>Enter verification code</h2>
              <p className="auth-hint">{otpInfo || `Code sent to ${email}`}</p>
              <label htmlFor="otp">Code</label>
              <input
                id="otp"
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                required
                inputMode="numeric"
                autoComplete="one-time-code"
              />
              {error && <p className="error-text">{error}</p>}
              <button type="submit" className="btn btn-primary" disabled={authLoading}>
                {authLoading ? 'Verifying...' : 'Verify & continue'}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                style={{ marginTop: 8 }}
                onClick={() => setCommercialView('otp-request')}
              >
                Resend code
              </button>
            </form>
          }
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
