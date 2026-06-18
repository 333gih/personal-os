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
  { href: "/entertainment", label: "Entertainment", icon: Gamepad2 },
  { href: "/search", label: "Search", icon: Search, mobileTab: true },
  { href: "/settings", label: "Settings", icon: Settings, mobileTab: true },
];

export const MOBILE_TAB_ITEMS = NAV_ITEMS.filter((item) => item.mobileTab);
