"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { IOS_TAB_ITEMS, MOBILE_TAB_ITEMS } from "@/lib/nav";
import { isPersonalOSIosApp } from "@/lib/ios-app";
import { useEffect, useState } from "react";

type BottomNavProps = {
  onOpenMenu?: () => void;
};

export function BottomNav({ onOpenMenu }: BottomNavProps) {
  const pathname = usePathname();
  const [iosApp, setIosApp] = useState(false);

  useEffect(() => {
    setIosApp(isPersonalOSIosApp());
  }, []);

  const tabs = iosApp ? IOS_TAB_ITEMS : MOBILE_TAB_ITEMS;

  return (
    <nav
      aria-label="Primary"
      className="fixed inset-x-0 bottom-0 z-40 border-t bg-card/95 backdrop-blur supports-[backdrop-filter]:bg-card/80 lg:hidden"
      style={{ paddingBottom: "var(--safe-bottom)" }}
    >
      <div className="mx-auto flex h-[var(--mobile-nav-height)] max-w-lg items-stretch justify-around">
        {tabs.map(({ href, label, icon: Icon, iosMenuTrigger }) => {
          const active = !iosMenuTrigger && pathname.startsWith(href);

          if (iosMenuTrigger) {
            return (
              <button
                key={href}
                type="button"
                onClick={onOpenMenu}
                className="flex min-h-11 min-w-0 flex-1 flex-col items-center justify-center gap-0.5 px-1 text-[11px] font-medium text-muted-foreground active:scale-95 sm:text-xs"
              >
                <Icon className="h-5 w-5 shrink-0" />
                <span className="max-w-full truncate">{label}</span>
              </button>
            );
          }

          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex min-h-11 min-w-0 flex-1 flex-col items-center justify-center gap-0.5 px-1 text-[11px] font-medium active:scale-95 sm:text-xs",
                active ? "text-primary" : "text-muted-foreground",
              )}
            >
              <Icon className={cn("h-5 w-5 shrink-0", active && "stroke-[2.5]")} />
              <span className="max-w-full truncate">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
