import { useEffect, useState } from 'react';
import { ActionButton } from '../components/ActionButton';
import { BrandLogo } from '../components/BrandLogo';
import { useActionFeedback } from '../hooks/useActionFeedback';
import { SUPPORTED_SITES } from '../shared/constants';
import { storageService } from '../storage/storage-service';
import type { ExtensionSettings } from '../types/storage';
import { DEFAULT_SETTINGS } from '../types/storage';

export function App() {
  const [settings, setSettings] = useState<ExtensionSettings>(DEFAULT_SETTINGS);
  const [exportData, setExportData] = useState('');
  const exportAction = useActionFeedback();
  const clearAction = useActionFeedback();

  useEffect(() => {
    void storageService.getSettings().then(setSettings);
  }, []);

  const saveSettings = async (next: ExtensionSettings) => {
    setSettings(next);
    await storageService.set('settings', next);
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

  const handleExport = () => {
    void exportAction.run(async () => {
      const data = await storageService.exportAll();
      const sanitized = { ...data, auth: data.auth ? { ...data.auth, tokens: '[REDACTED]' } : null };
      setExportData(JSON.stringify(sanitized, null, 2));
    });
  };

  const handleClearCache = () => {
    if (!confirm('Clear parser cache and unsynced events? This cannot be undone.')) return;
    void clearAction.run(async () => {
      await storageService.clearCache();
      setExportData('');
    });
  };

  return (
    <div className="options-container">
      <header className="options-header">
        <div className="options-header__brand">
          <BrandLogo size={44} className="options-header__logo" />
          <div>
            <h1>Story Tracker Settings</h1>
            <p>Reading sync & site preferences</p>
          </div>
        </div>
      </header>

      <div className="section">
        <h2>Enabled websites</h2>
        <p className="section-desc">Turn off sites you do not want synced to Personal OS.</p>
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
        <h2>Sync settings</h2>
        <div className="setting-row">
          <div>
            <span className="setting-label">Auto-track new reading sites</span>
            <span className="setting-hint">Ask permission when a chapter URL is detected</span>
          </div>
          <label className="toggle">
            <input
              type="checkbox"
              checked={settings.autoDiscoverSites}
              onChange={() =>
                void saveSettings({ ...settings, autoDiscoverSites: !settings.autoDiscoverSites })
              }
            />
            <span className="toggle-slider" />
          </label>
        </div>
        <div className="setting-row">
          <label className="setting-label" htmlFor="sync-interval">
            Sync interval (seconds)
          </label>
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
          <div>
            <span className="setting-label">Auto sync</span>
            <span className="setting-hint">Push progress while you read</span>
          </div>
          <label className="toggle">
            <input
              type="checkbox"
              checked={settings.autoSync}
              onChange={() => void saveSettings({ ...settings, autoSync: !settings.autoSync })}
            />
            <span className="toggle-slider" />
          </label>
        </div>
      </div>

      {settings.customOrigins.length > 0 ?
        <div className="section">
          <h2>Discovered sites</h2>
          {settings.customOrigins.map((origin) => (
            <div key={origin.pattern} className="site-toggle site-toggle--discovered">
              <div>
                <span>{origin.label}</span>
                <code className="origin-code">{origin.pattern}</code>
              </div>
            </div>
          ))}
        </div>
      : null}

      <div className="section">
        <h2>Data management</h2>
        <ActionButton
          variant="secondary"
          loading={exportAction.isLoading}
          success={exportAction.isSuccess}
          loadingLabel="Exporting…"
          successLabel="Exported"
          onClick={handleExport}
        >
          Export data
        </ActionButton>
        {exportData ?
          <pre className="export-output">{exportData}</pre>
        : null}
      </div>

      <div className="section danger-zone">
        <h2>Danger zone</h2>
        <p className="section-desc">
          Clear local parser cache and unsynced events. Reading history is preserved.
        </p>
        <ActionButton
          variant="danger"
          loading={clearAction.isLoading}
          success={clearAction.isSuccess}
          loadingLabel="Clearing…"
          successLabel="Cleared"
          onClick={handleClearCache}
        >
          Clear local cache
        </ActionButton>
      </div>
    </div>
  );
}
