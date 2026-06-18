import { syncManager } from './sync-manager';
import { tabTracker } from './tab-tracker';
import { initAuthSessionManager } from '../auth/auth-session-manager';
import { logger } from '../utils/logger';

tabTracker.init();

void initAuthSessionManager()
  .then(() => syncManager.init())
  .catch((error) => {
    logger.error('Failed to initialize background script', error);
  });
