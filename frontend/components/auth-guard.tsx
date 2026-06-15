"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [ready, setReady] = useState(false);

  useEffect(() => {
    fetch("/api/auth/session", { credentials: "same-origin" })
      .then((res) => {
        if (!res.ok) {
          console.warn("[auth-guard] no session", res.status);
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

  if (!ready) return null;
  return <>{children}</>;
}
