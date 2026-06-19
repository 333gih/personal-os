import { useEffect, useState } from 'react';
import { App as HomeApp } from '../popup/App';
import '../popup/styles.css';
import { App as SettingsApp } from '../options/App';
import '../options/styles.css';
import { useAuth } from '../hooks/useAuth';
import { SafariSetupBanner } from './SafariSetupBanner';

type Tab = 'home' | 'settings';

function AuthRedirect() {
  const { auth } = useAuth();

  useEffect(() => {
    if (!auth) return;
    if (!window.location.pathname.includes('/extension/connect')) return;
    const index = new URL('index.html', window.location.href);
    window.location.replace(index.href);
  }, [auth]);

  return null;
}

export function AppShell() {
  const [tab, setTab] = useState<Tab>('home');

  useEffect(() => {
    const onOpenSettings = () => setTab('settings');
    window.addEventListener('story-tracker-open-settings', onOpenSettings);
    return () => window.removeEventListener('story-tracker-open-settings', onOpenSettings);
  }, []);

  useEffect(() => {
    if (!window.location.pathname.includes('/extension/connect')) return;
    const timer = window.setInterval(() => {
      if (!window.location.pathname.includes('/extension/connect')) return;
      const el = document.getElementById('personal-os-extension-handoff');
      if (!el?.getAttribute('data-handoff')) return;
      import('../content/extension-connect-bridge');
    }, 300);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <div className="ios-app">
      <AuthRedirect />
      <header className="ios-app__header">
        <div>
          <p className="ios-app__eyebrow">Personal OS</p>
          <h1 className="ios-app__title">Story Tracker</h1>
        </div>
      </header>

      {tab === 'home' ? <SafariSetupBanner /> : null}

      <main className={`ios-app__main ios-app__main--${tab}`}>
        {tab === 'home' ? (
          <div className="ios-app__panel">
            <HomeApp />
          </div>
        ) : (
          <div className="ios-app__panel ios-app__panel--settings">
            <SettingsApp />
          </div>
        )}
      </main>

      <nav className="ios-app__tabs" aria-label="Main">
        <button
          type="button"
          className={`ios-app__tab ${tab === 'home' ? 'ios-app__tab--active' : ''}`}
          onClick={() => setTab('home')}
        >
          <span className="ios-app__tab-icon" aria-hidden>
            📖
          </span>
          Đọc
        </button>
        <button
          type="button"
          className={`ios-app__tab ${tab === 'settings' ? 'ios-app__tab--active' : ''}`}
          onClick={() => setTab('settings')}
        >
          <span className="ios-app__tab-icon" aria-hidden>
            ⚙
          </span>
          Cài đặt
        </button>
      </nav>
    </div>
  );
}
