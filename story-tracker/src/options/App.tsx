import { useEffect, useState } from 'react';
import { ActionButton } from '../components/ActionButton';
import { BrandLogo } from '../components/BrandLogo';
import { useActionFeedback } from '../hooks/useActionFeedback';
import { SUPPORTED_SITES } from '../shared/constants';
import { storageService } from '../storage/storage-service';
import type { ExtensionSettings } from '../types/storage';
import { DEFAULT_SETTINGS } from '../types/storage';
import type { CustomSiteProfile, SiteProfileExtension } from '../types/site-profile';
import { listBuiltinPlugins, SITE_PLUGIN_GUIDE } from '../plugins';

const DEFAULT_CUSTOM_PROFILE: Omit<CustomSiteProfile, 'id' | 'addedAt'> = {
  label: '',
  enabled: true,
  originPattern: 'https://example.com/*',
  urlRules: {
    pathKeywords: ['truyen', 'chuong'],
    hostKeywords: [],
  },
  chapterDetection: ['url_path', 'url_hash', 'dom_active', 'title_split'],
  selectors: {
    storyTitle: ['h1', '.book-title'],
    chapterTitle: ['.chapter-title', 'h2'],
    chapterList: ['.list-chapter', '.chapter-list'],
    chapterListItem: ['a', 'li'],
    chapterActive: ['.active', '.current'],
    contentRoot: ['#chapter-content', '.chapter-c', 'article'],
  },
};

function newCustomProfile(): CustomSiteProfile {
  return {
    ...DEFAULT_CUSTOM_PROFILE,
    id: crypto.randomUUID(),
    label: 'Custom site',
    addedAt: Date.now(),
  };
}

export function App() {
  const [settings, setSettings] = useState<ExtensionSettings>(DEFAULT_SETTINGS);
  const [exportData, setExportData] = useState('');
  const [draftProfile, setDraftProfile] = useState<CustomSiteProfile | null>(null);
  const [selectorsJson, setSelectorsJson] = useState('');
  const [extensionJson, setExtensionJson] = useState('');
  const builtinPlugins = listBuiltinPlugins();
  const exportAction = useActionFeedback();
  const clearAction = useActionFeedback();
  const clearHistoryAction = useActionFeedback();
  const profileAction = useActionFeedback();

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

  const handleClearHistory = () => {
    if (
      !confirm(
        'Clear Recent stories in the extension popup? This does not delete progress on Personal OS. Sync may restore items from the server.',
      )
    ) {
      return;
    }
    void clearHistoryAction.run(async () => {
      await storageService.clearReadingHistory();
    });
  };

  const startAddProfile = () => {
    const profile = newCustomProfile();
    setDraftProfile(profile);
    setSelectorsJson(JSON.stringify(profile.selectors, null, 2));
    setExtensionJson('');
  };

  const saveCustomProfile = () => {
    if (!draftProfile) return;
    void profileAction.run(async () => {
      let selectors = draftProfile.selectors;
      if (selectorsJson.trim()) {
        selectors = JSON.parse(selectorsJson) as CustomSiteProfile['selectors'];
      }
      let extension: SiteProfileExtension | undefined = draftProfile.extension;
      if (extensionJson.trim()) {
        extension = JSON.parse(extensionJson) as SiteProfileExtension;
      }
      const keywords = draftProfile.urlRules.pathKeywords ?? [];
      const profile: CustomSiteProfile = {
        ...draftProfile,
        label: draftProfile.label.trim() || 'Custom site',
        originPattern: draftProfile.originPattern.trim(),
        urlRules: {
          ...draftProfile.urlRules,
          hostPatterns: [draftProfile.originPattern.trim()],
          pathKeywords: keywords,
        },
        selectors,
        extension,
        priority: 200,
      };
      const existing = settings.customProfiles.filter((p) => p.id !== profile.id);
      await saveSettings({
        ...settings,
        customProfiles: [...existing, profile],
      });
      setDraftProfile(null);
      setSelectorsJson('');
      setExtensionJson('');
    });
  };

  const removeCustomProfile = (id: string) => {
    void saveSettings({
      ...settings,
      customProfiles: settings.customProfiles.filter((p) => p.id !== id),
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
        <h2>Built-in site profiles</h2>
        <p className="section-desc">
          Profiles define URL keywords and DOM selectors. Auto-detect also matches paths containing
          truyen, chuong, thuvien, thuquan, etc.
        </p>
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
        <h2>Site plugins</h2>
        <p className="section-desc">{SITE_PLUGIN_GUIDE.title}</p>
        <div className="plugin-guide">
          {SITE_PLUGIN_GUIDE.levels.map((item) => (
            <div key={item.level} className="plugin-guide__item">
              <strong>
                Level {item.level}: {item.title}
              </strong>
              <p>{item.body}</p>
            </div>
          ))}
        </div>
        <p className="setting-hint">
          Need a new plugin? Email{' '}
          <a href={`mailto:${SITE_PLUGIN_GUIDE.supportEmail}`}>{SITE_PLUGIN_GUIDE.supportEmail}</a>
        </p>
        <h3 className="subsection-title">Pre-installed plugins</h3>
        {builtinPlugins.map((plugin) => (
          <div key={plugin.id} className="site-toggle site-toggle--discovered">
            <div>
              <span>{plugin.label}</span>
              <code className="origin-code">extension.handler = &quot;{plugin.id}&quot;</code>
              <span className="setting-hint">{plugin.description}</span>
            </div>
          </div>
        ))}
        <details className="plugin-example">
          <summary>Example extension JSON (Vietnam Thu Quan)</summary>
          <pre className="export-output">{SITE_PLUGIN_GUIDE.extensionExample}</pre>
        </details>
      </div>

      <div className="section">
        <h2>Custom site profiles</h2>
        <p className="section-desc">
          Level 1: URL pattern + selectors for normal chapter URLs. Level 2: add{' '}
          <code>extension.handler</code> to attach a built-in plugin above.
        </p>

        {settings.customProfiles.map((profile) => (
          <div key={profile.id} className="site-toggle site-toggle--discovered">
            <div>
              <span>{profile.label}</span>
              <code className="origin-code">{profile.originPattern}</code>
              {profile.urlRules.pathKeywords?.length ? (
                <span className="setting-hint">
                  keywords: {profile.urlRules.pathKeywords.join(', ')}
                </span>
              ) : null}
              {profile.extension?.handler ?
                <span className="setting-hint">plugin: {profile.extension.handler}</span>
              : null}
            </div>
            <button type="button" className="btn-text-danger" onClick={() => removeCustomProfile(profile.id)}>
              Remove
            </button>
          </div>
        ))}

        {draftProfile ? (
          <div className="profile-form">
            <label className="setting-label">
              Site name
              <input
                value={draftProfile.label}
                onChange={(e) => setDraftProfile({ ...draftProfile, label: e.target.value })}
              />
            </label>
            <label className="setting-label">
              URL pattern
              <input
                value={draftProfile.originPattern}
                onChange={(e) =>
                  setDraftProfile({ ...draftProfile, originPattern: e.target.value })
                }
                placeholder="https://vietnamthuquan.eu/*"
              />
            </label>
            <label className="setting-label">
              Path keywords (comma-separated)
              <input
                value={(draftProfile.urlRules.pathKeywords ?? []).join(', ')}
                onChange={(e) =>
                  setDraftProfile({
                    ...draftProfile,
                    urlRules: {
                      ...draftProfile.urlRules,
                      pathKeywords: e.target.value
                        .split(',')
                        .map((s) => s.trim())
                        .filter(Boolean),
                    },
                  })
                }
                placeholder="truyen, chuong, thuvien"
              />
            </label>
            <label className="setting-label">
              Optional path regex
              <input
                value={draftProfile.urlRules.pathRegex ?? ''}
                onChange={(e) =>
                  setDraftProfile({
                    ...draftProfile,
                    urlRules: { ...draftProfile.urlRules, pathRegex: e.target.value || undefined },
                  })
                }
                placeholder="/truyen/truyen\\.aspx"
              />
            </label>
            <label className="setting-label">
              Story query param
              <input
                value={draftProfile.urlRules.queryParams?.story ?? ''}
                onChange={(e) =>
                  setDraftProfile({
                    ...draftProfile,
                    urlRules: {
                      ...draftProfile.urlRules,
                      queryParams: {
                        ...draftProfile.urlRules.queryParams,
                        story: e.target.value || undefined,
                      },
                    },
                  })
                }
                placeholder="tid"
              />
            </label>
            <label className="setting-label">
              DOM selectors (JSON, optional)
              <textarea
                className="selectors-json"
                rows={8}
                value={selectorsJson}
                onChange={(e) => setSelectorsJson(e.target.value)}
              />
            </label>
            <label className="setting-label">
              Site plugin extension (JSON, optional — Level 2)
              <span className="setting-hint">
                Use built-in handler id, e.g. &quot;vietnamthuquan&quot;. Leave empty for
                selector-only sites.
              </span>
              <textarea
                className="selectors-json"
                rows={6}
                value={extensionJson}
                onChange={(e) => setExtensionJson(e.target.value)}
                placeholder={SITE_PLUGIN_GUIDE.extensionExample}
              />
            </label>
            <div className="profile-form__actions">
              <ActionButton variant="primary" onClick={saveCustomProfile} loading={profileAction.isLoading}>
                Save profile
              </ActionButton>
              <ActionButton variant="secondary" onClick={() => setDraftProfile(null)}>
                Cancel
              </ActionButton>
            </div>
          </div>
        ) : (
          <ActionButton variant="secondary" onClick={startAddProfile}>
            Add custom site
          </ActionButton>
        )}
      </div>

      <div className="section">
        <h2>Sync settings</h2>
        <div className="setting-row">
          <div>
            <span className="setting-label">Auto-track new reading sites</span>
            <span className="setting-hint">
              Ask permission when URL contains truyen/chuong/thuquan keywords
            </span>
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

      {settings.customOrigins.length > 0 ? (
        <div className="section">
          <h2>Discovered origins</h2>
          {settings.customOrigins.map((origin) => (
            <div key={origin.pattern} className="site-toggle site-toggle--discovered">
              <div>
                <span>{origin.label}</span>
                <code className="origin-code">{origin.pattern}</code>
              </div>
            </div>
          ))}
        </div>
      ) : null}

      <div className="section">
        <h2>Data management</h2>
        <p className="section-desc">
          <strong>Recent stories</strong> and saved progress live on this device. Clearing frees
          guest-mode slots (max 5 without sign-in). Signed-in users may see items return after sync
          if still on Personal OS.
        </p>
        <div className="profile-form__actions" style={{ marginBottom: 12 }}>
          <ActionButton
            variant="secondary"
            loading={clearHistoryAction.isLoading}
            success={clearHistoryAction.isSuccess}
            loadingLabel="Clearing…"
            successLabel="Cleared"
            onClick={handleClearHistory}
          >
            Clear recent stories
          </ActionButton>
        </div>
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
        {exportData ? <pre className="export-output">{exportData}</pre> : null}
      </div>

      <div className="section danger-zone">
        <h2>Danger zone</h2>
        <p className="section-desc">
          Clear local parser cache, active sessions, and unsynced sync queue. Recent stories are
          preserved unless you clear them in Data management above.
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
