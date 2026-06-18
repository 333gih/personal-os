"use client";

import { Suspense, useEffect, useRef, useState } from "react";
import { flushSync } from "react-dom";
import { useRouter, useSearchParams } from "next/navigation";

const HANDOFF_MESSAGE_TYPE = "PERSONAL_OS_EXTENSION_HANDOFF";
const HANDOFF_ACK_TYPE = "PERSONAL_OS_EXTENSION_HANDOFF_ACK";
const HANDOFF_DOM_ID = "personal-os-extension-handoff";

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

function deliverHandoff(payload: HandoffPayload): Promise<void> {
  return new Promise((resolve, reject) => {
    const deadline = Date.now() + 30_000;

    const onAck = (event: MessageEvent) => {
      if (event.source !== window || event.origin !== window.location.origin) return;
      if ((event.data as { type?: string })?.type !== HANDOFF_ACK_TYPE) return;
      cleanup();
      resolve();
    };

    const tick = () => {
      window.postMessage({ type: HANDOFF_MESSAGE_TYPE, payload }, window.location.origin);
      if (Date.now() > deadline) {
        cleanup();
        reject(
          new Error(
            "Story Tracker did not pick up the session. Reload the extension in about:debugging and try again.",
          ),
        );
      }
    };

    const interval = window.setInterval(tick, 400);

    function cleanup() {
      window.clearInterval(interval);
      window.removeEventListener("message", onAck);
    }

    window.addEventListener("message", onAck);
    tick();
  });
}

function ExtensionConnectInner() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const startedRef = useRef(false);
  const [status, setStatus] = useState<
    "checking" | "redirecting" | "handoff" | "waiting" | "done" | "error"
  >("checking");
  const [error, setError] = useState("");
  const [handoffPayload, setHandoffPayload] = useState<HandoffPayload | null>(null);

  useEffect(() => {
    if (startedRef.current) return;
    startedRef.current = true;

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

        flushSync(() => {
          setHandoffPayload(payload);
          setStatus("waiting");
        });
        await deliverHandoff(payload);
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
          onClick={() => router.replace(`/login?next=${encodeURIComponent("/extension/connect")}`)}
        >
          Try signing in again
        </button>
      </div>
    );
  }

  return (
    <>
      {handoffPayload ? (
        <div
          id={HANDOFF_DOM_ID}
          hidden
          data-handoff={JSON.stringify(handoffPayload)}
          aria-hidden
        />
      ) : null}
      <p className="text-sm text-muted-foreground">
        {status === "done"
          ? "Signed in. You can close this tab and return to Story Tracker."
          : status === "waiting"
            ? "Waiting for Story Tracker to receive your session…"
            : "Connecting Story Tracker to your Personal OS session…"}
      </p>
    </>
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
