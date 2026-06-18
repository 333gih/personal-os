"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";

const HANDOFF_MESSAGE_TYPE = "PERSONAL_OS_EXTENSION_HANDOFF";

type HandoffPayload = {
  access_token: string;
  refresh_token: string;
  token_type: "bearer";
  expires_in: number;
  refresh_expires_in: number;
  mode: "internal" | "commercial";
  application_id: string;
  nonce: string | null;
};

function ExtensionConnectInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [status, setStatus] = useState<"checking" | "redirecting" | "handoff" | "done" | "error">(
    "checking",
  );
  const [error, setError] = useState("");

  useEffect(() => {
    const nonce = searchParams.get("nonce");
    const nextPath = `/extension/connect${nonce ? `?nonce=${encodeURIComponent(nonce)}` : ""}`;

    async function run() {
      try {
        const sessionRes = await fetch("/api/auth/session", { credentials: "same-origin" });
        if (!sessionRes.ok) {
          setStatus("redirecting");
          router.replace(`/login?next=${encodeURIComponent(nextPath)}`);
          return;
        }

        setStatus("handoff");
        const handoffRes = await fetch("/api/auth/extension/handoff", {
          credentials: "same-origin",
          headers: { Accept: "application/json" },
        });
        const body = await handoffRes.json().catch(() => ({}));
        if (!handoffRes.ok) {
          setStatus("error");
          setError(
            (typeof body.error === "string" && body.error) ||
              "Could not read session for extension handoff.",
          );
          return;
        }

        const payload: HandoffPayload = {
          ...(body as Omit<HandoffPayload, "nonce">),
          nonce,
        };

        window.postMessage({ type: HANDOFF_MESSAGE_TYPE, payload }, window.location.origin);
        setStatus("done");
      } catch (e) {
        setStatus("error");
        setError(e instanceof Error ? e.message : "Extension handoff failed.");
      }
    }

    void run();
  }, [router, searchParams]);

  if (status === "redirecting") {
    return (
      <p className="text-sm text-muted-foreground">
        Redirecting to Personal OS sign-in (Internal SSO or Commercial)…
      </p>
    );
  }

  if (status === "error") {
    return (
      <div className="space-y-3 text-center">
        <p className="text-sm text-destructive">{error}</p>
        <button
          type="button"
          className="text-sm font-medium text-primary underline"
          onClick={() => router.replace("/login?next=/extension/connect")}
        >
          Try signing in again
        </button>
      </div>
    );
  }

  return (
    <p className="text-sm text-muted-foreground">
      {status === "done"
        ? "Signed in. You can close this tab and return to Story Tracker."
        : "Connecting Story Tracker to your Personal OS session…"}
    </p>
  );
}

export default function ExtensionConnectPage() {
  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-muted/30 p-4 pt-safe pb-safe">
      <div className="w-full max-w-md rounded-lg border bg-card p-6 text-center shadow-sm">
        <h1 className="mb-2 text-lg font-semibold">Story Tracker</h1>
        <Suspense fallback={<p className="text-sm text-muted-foreground">Loading…</p>}>
          <ExtensionConnectInner />
        </Suspense>
      </div>
    </div>
  );
}
