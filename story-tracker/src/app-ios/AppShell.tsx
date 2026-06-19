import { useEffect, useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { CompanionHistory } from './CompanionHistory';
import { CompanionHome } from './CompanionHome';
import { CompanionSettings } from './CompanionSettings';

type Tab = 'home' | 'history' | 'settings';

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
          <p className="ios-app__eyebrow">Companion app</p>
          <h1 className="ios-app__title">Story Tracker</h1>
        </div>
      </header>

      <main className="ios-app__main">
        {tab === 'home' ? <CompanionHome onOpenHistory={() => setTab('history')} /> : null}
        {tab === 'history' ? <CompanionHistory /> : null}
        {tab === 'settings' ? <CompanionSettings /> : null}
      </main>

      <nav className="ios-app__tabs ios-app__tabs--3" aria-label="Main">
        <button
          type="button"
          className={`ios-app__tab ${tab === 'home' ? 'ios-app__tab--active' : ''}`}
          onClick={() => setTab('home')}
        >
          Trang chủ
        </button>
        <button
          type="button"
          className={`ios-app__tab ${tab === 'history' ? 'ios-app__tab--active' : ''}`}
          onClick={() => setTab('history')}
        >
          Lịch sử
        </button>
        <button
          type="button"
          className={`ios-app__tab ${tab === 'settings' ? 'ios-app__tab--active' : ''}`}
          onClick={() => setTab('settings')}
        >
          Cài đặt
        </button>
      </nav>
    </div>
  );
}
