import type { LucideIcon } from "lucide-react";
import {
  BookOpen,
  Briefcase,
  Gamepad2,
  Home,
  Inbox,
  LayoutGrid,
  Rocket,
  Search,
  Settings,
} from "lucide-react";

export type NavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
  mobileTab?: boolean;
  /** iOS shell: opens drawer instead of navigating */
  iosMenuTrigger?: boolean;
};

export const NAV_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: Home, mobileTab: true },
  { href: "/inbox", label: "Inbox", icon: Inbox, mobileTab: true },
  { href: "/learning", label: "Learning", icon: BookOpen },
  { href: "/work", label: "Work", icon: Briefcase },
  { href: "/startup", label: "Startup", icon: Rocket },
  { href: "/entertainment", label: "Entertainment", icon: Gamepad2, mobileTab: true },
  { href: "/search", label: "Search", icon: Search, mobileTab: true },
  { href: "/settings", label: "Settings", icon: Settings },
];

/** Mobile web: compact tab bar */
export const MOBILE_TAB_ITEMS = NAV_ITEMS.filter((item) => item.mobileTab);

/** Personal OS iOS app: work / learning / research-first tabs */
export const IOS_TAB_ITEMS: NavItem[] = [
  { href: "/dashboard", label: "Home", icon: Home },
  { href: "/work", label: "Work", icon: Briefcase },
  { href: "/learning", label: "Learning", icon: BookOpen },
  { href: "/search", label: "Search", icon: Search },
  { href: "#menu", label: "More", icon: LayoutGrid, iosMenuTrigger: true },
];

/** Drawer sections when More is tapped on iOS */
export const IOS_DRAWER_ITEMS = NAV_ITEMS.filter(
  (item) => !IOS_TAB_ITEMS.some((tab) => tab.href === item.href && !tab.iosMenuTrigger),
);

const IOS_PAGE_TITLES: Record<string, string> = {
  "/dashboard": "Personal OS",
  "/work": "Career Path",
  "/learning": "Personal OS",
  "/search": "Personal OS",
  "/settings": "Personal OS",
  "/startup": "Startup Ecosystem",
};

export function navLabelForPath(pathname: string, iosApp = false): string {
  if (iosApp) {
    const iosMatch = Object.entries(IOS_PAGE_TITLES).find(([href]) => pathname.startsWith(href));
    if (iosMatch) return iosMatch[1];
  }
  const match = NAV_ITEMS.find((item) => pathname.startsWith(item.href));
  if (match) return match.label;
  if (pathname.startsWith("/entities")) return "Detail";
  return "Personal OS";
}
