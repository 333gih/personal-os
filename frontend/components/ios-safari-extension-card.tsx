"use client";

import { useState } from "react";
import Link from "next/link";
import { ExternalLink, Puzzle } from "lucide-react";
import { buildExtensionConnectUrl } from "@/lib/extension-connect";
import { isPersonalOSIosApp } from "@/lib/ios-app";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const SAFARI_STEPS = [
  "Open Personal OS at least once after installing from TestFlight.",
  "Settings → Safari → Extensions → enable Story Tracker.",
  "In Safari: tap aA in the address bar → Manage Extensions → enable Story Tracker.",
  "On a story site: tap aA → Story Tracker to save reading progress.",
  "If the icon is missing: Settings → Safari → Extensions → Story Tracker → Allow on all websites.",
];

export function IosSafariExtensionCard() {
  const [open, setOpen] = useState(true);
  const iosApp = isPersonalOSIosApp();
  const connectUrl = buildExtensionConnectUrl("/extension/connect");

  if (!iosApp) return null;

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
            className="text-sm font-medium text-primary underline"
            onClick={() => setOpen(true)}
          >
            Show Safari extension setup
          </button>
        )}
      </CardContent>
    </Card>
  );
}
