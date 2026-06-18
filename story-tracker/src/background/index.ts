import { syncManager } from './sync-manager';
import { tabTracker } from './tab-tracker';
import { logger } from '../utils/logger';

tabTracker.init();

void syncManager.init().catch((error) => {
  logger.error('Failed to initialize background script', error);
});
