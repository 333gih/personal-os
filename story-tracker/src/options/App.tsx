import { useEffect, useState } from 'react';
import { SUPPORTED_SITES } from '../shared/constants';
import { storageService } from '../storage/storage-service';
import type { ExtensionSettings } from '../types/storage';
import { DEFAULT_SETTINGS } from '../types/storage';

export function App() {
  const [settings, setSettings] = useState<ExtensionSettings>(DEFAULT_SETTINGS);
  const [exportData, setExportData] = useState('');
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    void storageService.getSettings().then(setSettings);
  }, []);

  const saveSettings = async (next: ExtensionSettings) => {
    setSettings(next);
    await storageService.set('settings', next);
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const toggleSite = (siteId: string) => {
    const next = {
      ...settings,
      enabledSites: {
        ...settings.enabledSites,
        [siteId]: !(settings.enabledSites[siteId] ?? true),
      },
    };
    void saveSettings(next);
  };

  const handleSyncInterval = (value: number) => {
    void saveSettings({ ...settings, syncIntervalMs: Math.max(5000, value) });
  };

  const handleExport = async () => {
    const data = await storageService.exportAll();
    const sanitized = { ...data, auth: data.auth ? { ...data.auth, tokens: '[REDACTED]' } : null };
    setExportData(JSON.stringify(sanitized, null, 2));
  };

  const handleClearCache = async () => {
    if (confirm('Clear parser cache and unsynced events? This cannot be undone.')) {
      await storageService.clearCache();
      alert('Cache cleared.');
    }
  };

  return (
    <div className="options-container">
      <h1>Story Tracker Settings</h1>
      {saved && <p style={{ color: '#2e7d32', marginBottom: 12 }}>Settings saved.</p>}

      <div className="section">
        <h2>Enabled Websites</h2>
        {SUPPORTED_SITES.filter((s) => s.id !== 'generic').map((site) => (
          <div key={site.id} className="site-toggle">
            <span>{site.label}</span>
            <label className="toggle">
              <input
                type="checkbox"
                checked={settings.enabledSites[site.id] ?? true}
                onChange={() => toggleSite(site.id)}
              />
              <span className="toggle-slider" />
            </label>
          </div>
        ))}
      </div>

      <div className="section">
        <h2>Sync Settings</h2>
        <div className="setting-row">
          <label htmlFor="sync-interval">Sync interval (seconds)</label>
          <input
            id="sync-interval"
            type="number"
            min={5}
            max={300}
            value={Math.round(settings.syncIntervalMs / 1000)}
            onChange={(e) => handleSyncInterval(Number(e.target.value) * 1000)}
          />
        </div>
        <div className="setting-row">
          <label htmlFor="auto-sync">Auto sync</label>
          <label className="toggle">
            <input
              id="auto-sync"
              type="checkbox"
              checked={settings.autoSync}
              onChange={() => void saveSettings({ ...settings, autoSync: !settings.autoSync })}
            />
            <span className="toggle-slider" />
          </label>
        </div>
      </div>

      <div className="section">
        <h2>Data Management</h2>
        <button className="btn btn-secondary" onClick={handleExport}>
          Export Data
        </button>
        {exportData && <pre className="export-output">{exportData}</pre>}
      </div>

      <div className="section danger-zone">
        <h2>Danger Zone</h2>
        <p style={{ fontSize: 12, color: '#666', marginBottom: 8 }}>
          Clear local parser cache and unsynced events. Reading history is preserved.
        </p>
        <button className="btn btn-secondary" onClick={handleClearCache}>
          Clear Local Cache
        </button>
      </div>
    </div>
  );
}
