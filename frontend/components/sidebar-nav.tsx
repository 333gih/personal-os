"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LogOut } from "lucide-react";
import { cn } from "@/lib/utils";
import { NAV_ITEMS, type NavItem } from "@/lib/nav";
import { Button } from "./ui/button";

type SidebarNavProps = {
  onNavigate?: () => void;
  className?: string;
  mobile?: boolean;
  items?: NavItem[];
};

export function SidebarNav({ onNavigate, className, mobile, items = NAV_ITEMS }: SidebarNavProps) {
  const pathname = usePathname();

  return (
    <nav className={cn("flex-1 space-y-1 overflow-y-auto p-3 sm:p-4", className)}>
      {items.map(({ href, label, icon: Icon }) => (
        <Link
          key={href}
          href={href}
          onClick={onNavigate}
          className={cn(
            "flex items-center gap-3 rounded-xl px-3 text-sm font-medium transition-colors hover:bg-accent active:bg-accent/80",
            mobile ? "min-h-11 py-2.5" : "py-2.5",
            pathname.startsWith(href) && "bg-accent text-accent-foreground",
          )}
        >
          <Icon className="h-5 w-5 shrink-0" />
          {label}
        </Link>
      ))}
    </nav>
  );
}

type SidebarFooterProps = {
  onLogout: () => void;
};

export function SidebarFooter({ onLogout }: SidebarFooterProps) {
  return (
    <div className="border-t p-3 pb-safe sm:p-4">
      <Button variant="ghost" className="min-h-11 w-full justify-start" onClick={onLogout}>
        <LogOut className="mr-2 h-4 w-4" />
        Logout
      </Button>
    </div>
  );
}
