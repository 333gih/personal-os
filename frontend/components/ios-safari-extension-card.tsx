"use client";

import { useState } from "react";
import Link from "next/link";
import { ExternalLink, Puzzle } from "lucide-react";
import { buildExtensionConnectUrl } from "@/lib/extension-connect";
import { isPersonalOSIosApp } from "@/lib/ios-app";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

const SAFARI_STEPS = [
  "Open Safari on this device.",
  "Tap the AA or puzzle icon in the search bar.",
  "Select Manage Extensions from the menu.",
  "Toggle Personal OS / Story Tracker to enable.",
];

type IosSafariExtensionCardProps = {
  variant?: "default" | "featured";
};

export function IosSafariExtensionCard({ variant = "default" }: IosSafariExtensionCardProps) {
  const [open, setOpen] = useState(true);
  const iosApp = isPersonalOSIosApp();
  const connectUrl = buildExtensionConnectUrl("/extension/connect");

  if (!iosApp) return null;

  if (variant === "featured") {
    return (
      <div className="overflow-hidden rounded-3xl bg-card shadow-card ring-1 ring-border/50">
        <div className="relative bg-gradient-to-br from-orange-500 via-primary to-rose-700 px-5 pb-8 pt-5 text-white">
          <span className="rounded-md bg-white/20 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide">
            Featured
          </span>
          <h3 className="mt-3 font-display text-2xl font-semibold leading-tight">
            Safari Extension
            <br />
            Story Tracker
          </h3>
        </div>
        <div className="space-y-4 p-5">
          <p className="text-sm text-muted-foreground">
            Track reading progress and save inspirations directly from your mobile browser.
          </p>
          {open ? (
            <ol className="space-y-2 text-sm text-muted-foreground">
              {SAFARI_STEPS.map((step, i) => (
                <li key={step} className="flex gap-3">
                  <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-bold text-foreground">
                    {i + 1}
                  </span>
                  <span>{step}</span>
                </li>
              ))}
            </ol>
          ) : null}
          <div className="flex flex-col gap-2">
            <Button asChild className="min-h-11 w-full rounded-2xl">
              <a href={connectUrl}>
                <ExternalLink className="mr-2 h-4 w-4" />
                Connect in Safari
              </a>
            </Button>
            <Button variant="outline" asChild className="min-h-11 w-full rounded-2xl">
              <Link href="/entertainment">View synced progress</Link>
            </Button>
            <button
              type="button"
              className="text-sm font-medium text-primary"
              onClick={() => setOpen((v) => !v)}
            >
              {open ? "Hide steps" : "Show setup steps"}
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Puzzle className="h-5 w-5" />
          Story Tracker (Safari)
        </CardTitle>
        <CardDescription>
          Reading progress on novel/manga sites runs in Safari via the extension bundled with this
          app. Personal OS screens use your account session in this app.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex flex-col gap-2 sm:flex-row">
          <Button asChild className="min-h-11">
            <a href={connectUrl}>
              <ExternalLink className="mr-2 h-4 w-4" />
              Connect extension in Safari
            </a>
          </Button>
          <Button variant="outline" asChild className="min-h-11">
            <Link href="/entertainment">View synced progress</Link>
          </Button>
        </div>

        {open ? (
          <div className="rounded-xl border bg-muted/40 p-4 text-sm">
            <div className="mb-2 flex items-center justify-between gap-2">
              <p className="font-medium">Enable extension in Safari</p>
              <button
                type="button"
                className="text-muted-foreground hover:text-foreground"
                onClick={() => setOpen(false)}
                aria-label="Collapse"
              >
                ×
              </button>
            </div>
            <ol className="list-decimal space-y-2 pl-5 text-muted-foreground">
              {SAFARI_STEPS.map((step) => (
                <li key={step}>{step}</li>
              ))}
            </ol>
          </div>
        ) : (
          <button
            type="button"
            className={cn("text-sm font-medium text-primary underline")}
            onClick={() => setOpen(true)}
          >
            Show Safari extension setup
          </button>
        )}
      </CardContent>
    </Card>
  );
}
