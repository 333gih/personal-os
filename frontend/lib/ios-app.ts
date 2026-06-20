/**
 * Detect Personal OS native iOS shell (WKWebView) vs mobile Safari / browser.
 */
export function isPersonalOSIosApp(): boolean {
  if (typeof window === "undefined") return false;
  return (
    (window as Window & { __PERSONAL_OS_IOS_APP__?: boolean }).__PERSONAL_OS_IOS_APP__ === true ||
    document.documentElement.classList.contains("personal-os-ios") ||
    /\bPersonalOS-iOS\b/i.test(navigator.userAgent)
  );
}

/** WKWebView sheet / embed mode — hide duplicate web chrome; native tab bar handles nav. */
export function isPersonalOSIosEmbed(): boolean {
  if (typeof window === "undefined") return false;
  if ((window as Window & { __PERSONAL_OS_IOS_EMBED__?: boolean }).__PERSONAL_OS_IOS_EMBED__ === true) {
    return true;
  }
  if (document.documentElement.classList.contains("personal-os-ios-embed")) {
    return true;
  }
  return isPersonalOSIosApp() && new URLSearchParams(window.location.search).get("embed") === "1";
}

export function openInSafari(url: string): void {
  if (typeof window === "undefined") return;
  window.location.assign(url);
}
