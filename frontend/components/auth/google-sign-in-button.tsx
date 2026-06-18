"use client";

import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";

declare global {
  interface Window {
    google?: {
      accounts: {
        id: {
          initialize: (config: {
            client_id: string;
            callback: (response: { credential: string }) => void;
            auto_select?: boolean;
          }) => void;
          renderButton: (
            parent: HTMLElement,
            options: { theme?: string; size?: string; width?: number; text?: string },
          ) => void;
        };
      };
    };
  }
}

type Props = {
  disabled?: boolean;
  onCredential: (idToken: string) => void | Promise<void>;
};

const GIS_SCRIPT = "https://accounts.google.com/gsi/client";

export function GoogleSignInButton({ disabled, onCredential }: Props) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [ready, setReady] = useState(false);
  const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID?.trim();

  useEffect(() => {
    if (!clientId) return;

    const render = () => {
      if (!window.google?.accounts?.id || !containerRef.current) return;
      window.google.accounts.id.initialize({
        client_id: clientId,
        callback: (response) => {
          void onCredential(response.credential);
        },
      });
      containerRef.current.innerHTML = "";
      window.google.accounts.id.renderButton(containerRef.current, {
        theme: "outline",
        size: "large",
        width: 320,
        text: "signin_with",
      });
      setReady(true);
    };

    if (window.google?.accounts?.id) {
      render();
      return;
    }

    const existing = document.querySelector(`script[src="${GIS_SCRIPT}"]`);
    if (existing) {
      existing.addEventListener("load", render);
      return () => existing.removeEventListener("load", render);
    }

    const script = document.createElement("script");
    script.src = GIS_SCRIPT;
    script.async = true;
    script.onload = render;
    document.head.appendChild(script);
  }, [clientId, onCredential]);

  if (!clientId) {
    return (
      <p className="text-xs text-muted-foreground">
        Google Sign-In is not configured (set NEXT_PUBLIC_GOOGLE_CLIENT_ID).
      </p>
    );
  }

  return (
    <div className="space-y-2">
      <div
        ref={containerRef}
        className={disabled ? "pointer-events-none opacity-50" : undefined}
      />
      {!ready && (
        <Button type="button" variant="outline" className="w-full" disabled>
          Loading Google…
        </Button>
      )}
    </div>
  );
}
