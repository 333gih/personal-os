import { useEffect, useState } from 'react';
import { ActionButton } from '../components/ActionButton';
import { useActionFeedback } from '../hooks/useActionFeedback';
import { SUPPORTED_SITES } from '../shared/constants';
import { storageService } from '../storage/storage-service';
import type { ExtensionSettings } from '../types/storage';
import { DEFAULT_SETTINGS } from '../types/storage';

declare const __PERSONAL_OS_FE_URL__: string;

export function CompanionSettings() {
  const [settings, setSettings] = useState<ExtensionSettings>(DEFAULT_SETTINGS);
  const [exportData, setExportData] = useState('');
  const exportAction = useActionFeedback();
  const clearCacheAction = useActionFeedback();
  const clearHistoryAction = useActionFeedback();

  useEffect(() => {
    void storageService.getSettings().then(setSettings);
  }, []);

  const saveSettings = async (next: ExtensionSettings) => {
    setSettings(next);
    await storageService.set('settings', next);
  };

  const toggleSite = (siteId: string) => {
    void saveSettings({
      ...settings,
      enabledSites: {
        ...settings.enabledSites,
        [siteId]: !(settings.enabledSites[siteId] ?? true),
      },
    });
  };

  const handleExport = () => {
    void exportAction.run(async () => {
      const data = await storageService.exportAll();
      const sanitized = { ...data, auth: data.auth ? { ...data.auth, tokens: '[REDACTED]' } : null };
      setExportData(JSON.stringify(sanitized, null, 2));
    });
  };

  const handleClearHistory = () => {
    if (!window.confirm('Xóa lịch sử local? Tiến độ trên server (nếu đã sync) vẫn giữ.')) return;
    void clearHistoryAction.run(async () => {
      await storageService.clearReadingHistory();
    });
  };

  const handleClearCache = () => {
    if (!window.confirm('Xóa cache parser và hàng đợi sync chưa gửi?')) return;
    void clearCacheAction.run(async () => {
      await storageService.clearCache();
      setExportData('');
    });
  };

  const feUrl = __PERSONAL_OS_FE_URL__;

  return (
    <div className="companion-page">
      <section className="st-card">
        <p className="st-card__eyebrow">Site profiles</p>
        <p className="companion-settings__hint">Bật/tắt site extension theo dõi khi đọc trong Safari.</p>
        <ul className="companion-settings__sites">
          {SUPPORTED_SITES.map((site) => (
            <li key={site.id}>
              <label className="companion-settings__toggle">
                <input
                  type="checkbox"
                  checked={settings.enabledSites[site.id] ?? true}
                  onChange={() => toggleSite(site.id)}
                />
                <span>{site.label}</span>
              </label>
            </li>
          ))}
        </ul>
      </section>

      <section className="st-card">
        <p className="st-card__eyebrow">Đồng bộ</p>
        <label className="companion-settings__field">
          <span>Auto-sync</span>
          <input
            type="checkbox"
            checked={settings.autoSync}
            onChange={(e) => void saveSettings({ ...settings, autoSync: e.target.checked })}
          />
        </label>
        <label className="companion-settings__field">
          <span>Chu kỳ sync (giây)</span>
          <input
            type="number"
            min={5}
            step={5}
            value={Math.round(settings.syncIntervalMs / 1000)}
            onChange={(e) =>
              void saveSettings({
                ...settings,
                syncIntervalMs: Math.max(5000, Number(e.target.value) * 1000),
              })
            }
          />
        </label>
      </section>

      <section className="st-card">
        <p className="st-card__eyebrow">Dữ liệu</p>
        <div className="companion-settings__actions">
          <ActionButton variant="secondary" block loading={exportAction.isLoading} onClick={handleExport}>
            Export JSON
          </ActionButton>
          <ActionButton
            variant="secondary"
            block
            loading={clearHistoryAction.isLoading}
            onClick={handleClearHistory}
          >
            Xóa lịch sử local
          </ActionButton>
          <ActionButton variant="danger" block loading={clearCacheAction.isLoading} onClick={handleClearCache}>
            Xóa cache & queue
          </ActionButton>
        </div>
        {exportData ? (
          <textarea className="companion-settings__export" readOnly value={exportData} rows={8} />
        ) : null}
      </section>

      <section className="st-card companion-tip">
        <p className="st-card__eyebrow">Personal OS</p>
        <a className="companion-link-btn" href={feUrl} target="_blank" rel="noopener noreferrer">
          Mở web dashboard
        </a>
        <p className="companion-settings__hint">
          Cấu hình site tùy chỉnh nâng cao: dùng trang Options trong Safari extension (máy tính) hoặc bản
          extension desktop.
        </p>
      </section>
    </div>
  );
}
