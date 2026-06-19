import browser from 'webextension-polyfill';
import { AUTH_REFRESH_ALARM, AUTH_REFRESH_PERIOD_MINUTES } from './constants';
import { platformCapabilities } from '../platform/capabilities';
import { authService } from './auth-service';
import { logger } from '../utils/logger';

export async function initAuthSessionManager(): Promise<void> {
  if (platformCapabilities.reliableAlarms) {
    try {
      await browser.alarms.create(AUTH_REFRESH_ALARM, {
        periodInMinutes: AUTH_REFRESH_PERIOD_MINUTES,
      });
    } catch (error) {
      logger.warn('Could not schedule auth refresh alarm', error);
    }

    browser.alarms.onAlarm.addListener((alarm) => {
      if (alarm.name === AUTH_REFRESH_ALARM) {
        void authService.ensureSession();
      }
    });
  } else {
    const intervalMs = AUTH_REFRESH_PERIOD_MINUTES * 60 * 1000;
    globalThis.setInterval(() => {
      void authService.ensureSession();
    }, intervalMs);
  }

  const ok = await authService.ensureSession();
  if (ok) {
    logger.info('Auth session restored on startup');
  }
}
