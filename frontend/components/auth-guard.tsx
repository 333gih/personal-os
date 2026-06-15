"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getAccessToken } from "@/lib/auth/access-token";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    fetch("/api/auth/session", { credentials: "same-origin" })
      .then(async (res) => {
        if (!res.ok) {
          console.warn("[auth-guard] no session", res.status);
          router.replace("/login");
          return;
        }
        const token = await getAccessToken(true);
        if (!token) {
          console.warn("[auth-guard] session ok but no access token");
          router.replace("/login");
          return;
        }
        setReady(true);
      })
      .catch((err) => {
        console.error("[auth-guard] session check failed", err);
        router.replace("/login");
      });
  }, [router]);

  if (!ready) {
    return (
      <div className="flex min-h-[100dvh] items-center justify-center text-sm text-muted-foreground">
        Loading...
      </div>
    );
  }

  return <>{children}</>;
}
