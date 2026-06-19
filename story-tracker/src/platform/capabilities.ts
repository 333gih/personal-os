declare const __BROWSER_TARGET__: string;

export const browserTarget = __BROWSER_TARGET__;

export const isSafariTarget = browserTarget === 'safari';
export const isIosAppTarget = browserTarget === 'ios-app';

/** Feature flags for WebExtension API gaps on Safari (incl. iOS). */
export const platformCapabilities = {
  dynamicContentScripts: !isSafariTarget,
  optionalHostPermissions: !isSafariTarget,
  scriptingInjection: !isSafariTarget,
  reliableAlarms: !isSafariTarget,
} as const;
