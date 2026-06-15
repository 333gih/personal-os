"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Menu, X } from "lucide-react";
import { clearAccessTokenCache } from "@/lib/auth/access-token";
import { BottomNav } from "@/components/bottom-nav";
import { SidebarFooter, SidebarNav } from "@/components/sidebar-nav";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function AppShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [menuOpen, setMenuOpen] = useState(false);

  const logout = async () => {
    clearAccessTokenCache();
    await fetch("/api/auth/logout", {
      method: "POST",
      credentials: "same-origin",
    }).catch(() => undefined);
    router.push("/login");
  };

  return (
    <div className="flex min-h-[100dvh] bg-background">
      {/* Desktop sidebar */}
      <aside className="hidden h-[100dvh] w-64 shrink-0 flex-col border-r bg-card lg:flex">
        <div className="border-b p-5">
          <h1 className="text-lg font-bold tracking-tight">Personal OS</h1>
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
          "fixed inset-y-0 left-0 z-50 flex w-[min(85vw,18rem)] flex-col border-r bg-card shadow-xl transition-transform duration-200 lg:hidden",
          menuOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="flex items-center justify-between border-b p-4">
          <div>
            <h1 className="text-lg font-bold">Personal OS</h1>
            <p className="text-xs text-muted-foreground">Knowledge Platform</p>
          </div>
          <Button variant="ghost" size="icon" onClick={() => setMenuOpen(false)}>
            <X className="h-5 w-5" />
          </Button>
        </div>
        <SidebarNav onNavigate={() => setMenuOpen(false)} />
        <SidebarFooter onLogout={logout} />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        {/* Mobile top bar */}
        <header className="sticky top-0 z-30 flex items-center gap-3 border-b bg-card/95 px-4 py-3 backdrop-blur lg:hidden">
          <Button variant="ghost" size="icon" onClick={() => setMenuOpen(true)} aria-label="Open menu">
            <Menu className="h-5 w-5" />
          </Button>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold">Personal OS</p>
          </div>
        </header>

        <main className="flex-1 overflow-x-hidden overflow-y-auto p-4 pb-24 sm:p-5 lg:p-8 lg:pb-8">
          <div className="mx-auto w-full max-w-6xl">{children}</div>
        </main>
      </div>

      <BottomNav />
    </div>
  );
}
