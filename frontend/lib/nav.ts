import type { LucideIcon } from "lucide-react";
import {
  BookOpen,
  Briefcase,
  Gamepad2,
  Home,
  Inbox,
  Rocket,
  Search,
  Settings,
} from "lucide-react";

export type NavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
  mobileTab?: boolean;
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

export const MOBILE_TAB_ITEMS = NAV_ITEMS.filter((item) => item.mobileTab);

export function navLabelForPath(pathname: string): string {
  const match = NAV_ITEMS.find((item) => pathname.startsWith(item.href));
  if (match) return match.label;
  if (pathname.startsWith("/entities")) return "Detail";
  return "Personal OS";
}
