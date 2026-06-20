"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { Menu, Settings, X } from "lucide-react";
import { clearAccessTokenCache } from "@/lib/auth/access-token";
import { IOS_DRAWER_ITEMS, navLabelForPath } from "@/lib/nav";
import { isPersonalOSIosApp, isPersonalOSIosEmbed } from "@/lib/ios-app";
import { api } from "@/services/api";
import { BottomNav } from "@/components/bottom-nav";
import { SidebarFooter, SidebarNav } from "@/components/sidebar-nav";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

function userInitials(name?: string) {
  if (!name) return "?";
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) return parts[0].charAt(0).toUpperCase();
  return `${parts[0].charAt(0)}${parts[parts.length - 1].charAt(0)}`.toUpperCase();
}

export function AppShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const [iosApp, setIosApp] = useState(false);
  const [iosEmbed, setIosEmbed] = useState(false);

  useEffect(() => {
    setIosApp(isPersonalOSIosApp());
    setIosEmbed(isPersonalOSIosEmbed());
  }, []);

  const { data: user } = useQuery({
    queryKey: ["me"],
    queryFn: () => api.me(),
    enabled: iosApp,
  });

  const pageTitle = navLabelForPath(pathname, iosApp);

  const logout = async () => {
    clearAccessTokenCache();
    await fetch("/api/auth/logout", {
      method: "POST",
      credentials: "same-origin",
    }).catch(() => undefined);
    router.push("/login");
  };

  return (
    <div className={cn("flex min-h-[100dvh] bg-background", iosApp && "personal-os-ios")}>
      {/* Desktop sidebar */}
      <aside className="hidden h-[100dvh] w-64 shrink-0 flex-col border-r bg-card lg:flex">
        <div className="border-b p-5">
          <h1 className="font-display text-lg font-bold tracking-tight">Personal OS</h1>
          <p className="text-xs text-muted-foreground">Knowledge Platform</p>
        </div>
        <SidebarNav />
        <SidebarFooter onLogout={logout} />
      </aside>

      {/* Mobile drawer */}
      {menuOpen && (
        <button
          type="button"
          aria-label="Close menu"
          className="fixed inset-0 z-50 bg-black/40 lg:hidden"
          onClick={() => setMenuOpen(false)}
        />
      )}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-[min(85vw,18rem)] flex-col border-r bg-card pl-safe shadow-xl transition-transform duration-200 lg:hidden",
          menuOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex items-center justify-between border-b p-4 pt-safe pr-4">
          <div>
            <h1 className="font-display text-lg font-bold">Personal OS</h1>
            <p className="text-xs text-muted-foreground">Knowledge Platform</p>
          </div>
          <Button variant="ghost" size="icon" onClick={() => setMenuOpen(false)} aria-label="Close menu">
            <X className="h-5 w-5" />
          </Button>
        </div>
        <SidebarNav
          mobile
          items={iosApp ? IOS_DRAWER_ITEMS : undefined}
          onNavigate={() => setMenuOpen(false)}
        />
        <SidebarFooter onLogout={logout} />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        {/* Mobile top bar — hidden in iOS embed sheets (native toolbar handles chrome) */}
        {!iosEmbed ? (
        <header className="sticky top-0 z-30 flex min-h-[3.25rem] items-center gap-2 border-b bg-background/95 px-3 pt-safe backdrop-blur supports-[backdrop-filter]:bg-background/80 lg:hidden">
          {iosApp ? (
            <button
              type="button"
              onClick={() => setMenuOpen(true)}
              className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary"
              aria-label="Open menu"
            >
              {userInitials(user?.name)}
            </button>
          ) : (
            <Button variant="ghost" size="icon" onClick={() => setMenuOpen(true)} aria-label="Open menu">
              <Menu className="h-5 w-5" />
            </Button>
          )}
          <div className="min-w-0 flex-1 text-center">
            <p className="truncate font-display text-base font-semibold">{pageTitle}</p>
          </div>
          {iosApp ? (
            <Button variant="ghost" size="icon" asChild aria-label="Settings">
              <Link href="/settings">
                <Settings className="h-5 w-5 text-primary" />
              </Link>
            </Button>
          ) : (
            <div className="w-9 shrink-0" />
          )}
        </header>
        ) : null}

        <main
          className={cn(
            "flex-1 overflow-x-hidden overflow-y-auto overscroll-y-contain p-4 pb-mobile-nav sm:p-5 lg:p-8 lg:pb-8",
            iosApp && "ios-app-main",
            iosEmbed && "pb-4 ios-embed-main",
          )}
        >
          <div className="mx-auto w-full max-w-6xl">{children}</div>
        </main>
      </div>

      {!iosApp ? <BottomNav onOpenMenu={() => setMenuOpen(true)} /> : null}
    </div>
  );
}
