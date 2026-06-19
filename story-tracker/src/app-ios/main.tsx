import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { SyncManager } from '../background/sync-manager';
import { AppShell } from './AppShell';
import './styles.css';

async function boot() {
  const manager = new SyncManager();
  await manager.init();

  const root = document.getElementById('root');
  if (!root) throw new Error('Missing #root');

  createRoot(root).render(
    <StrictMode>
      <AppShell />
    </StrictMode>,
  );
}

void boot();
