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

export function openInSafari(url: string): void {
  if (typeof window === "undefined") return;
  window.location.assign(url);
}
