import browser from 'webextension-polyfill';
import { AUTH_REFRESH_ALARM, AUTH_REFRESH_PERIOD_MINUTES } from './constants';
import { authService } from './auth-service';
import { logger } from '../utils/logger';

export async function initAuthSessionManager(): Promise<void> {
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

  const ok = await authService.ensureSession();
  if (ok) {
    logger.info('Auth session restored on startup');
  }
}
