type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LOG_PREFIX = '[StoryTracker]';

function log(level: LogLevel, message: string, ...args: unknown[]): void {
  const fn = console[level] ?? console.log;
  fn(`${LOG_PREFIX} ${message}`, ...args);
}

export const logger = {
  debug: (message: string, ...args: unknown[]) => log('debug', message, ...args),
  info: (message: string, ...args: unknown[]) => log('info', message, ...args),
  warn: (message: string, ...args: unknown[]) => log('warn', message, ...args),
  error: (message: string, ...args: unknown[]) => log('error', message, ...args),
};
