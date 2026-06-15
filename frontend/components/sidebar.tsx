"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  BookOpen,
  Briefcase,
  Home,
  Inbox,
  LogOut,
  Rocket,
  Search,
  Settings,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { clearToken } from "@/services/api";
import { Button } from "./ui/button";

const nav = [
  { href: "/dashboard", label: "Dashboard", icon: Home },
  { href: "/inbox", label: "Inbox", icon: Inbox },
  { href: "/learning", label: "Learning", icon: BookOpen },
  { href: "/work", label: "Work", icon: Briefcase },
  { href: "/startup", label: "Startup", icon: Rocket },
  { href: "/search", label: "Search", icon: Search },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const logout = () => {
    clearToken();
    router.push("/login");
  };

  return (
    <aside className="flex h-screen w-64 flex-col border-r bg-card">
      <div className="border-b p-6">
        <h1 className="text-lg font-bold tracking-tight">Personal OS</h1>
        <p className="text-xs text-muted-foreground">Knowledge Platform</p>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {nav.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className={cn(
              "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors hover:bg-accent",
              pathname.startsWith(href) && "bg-accent text-accent-foreground"
            )}
          >
            <Icon className="h-4 w-4" />
            {label}
          </Link>
        ))}
      </nav>
      <div className="border-t p-4">
        <Button variant="ghost" className="w-full justify-start" onClick={logout}>
          <LogOut className="mr-2 h-4 w-4" />
          Logout
        </Button>
      </div>
    </aside>
  );
}
