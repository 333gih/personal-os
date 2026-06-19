"use client";

import { useQuery } from "@tanstack/react-query";
import { ExternalLink, BookOpen } from "lucide-react";
import { api } from "@/services/api";
import type { ReadingProgress } from "@/services/types";

function formatRelativeTime(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  const diffMs = Date.now() - date.getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return date.toLocaleDateString();
}

function siteLabel(siteId: string): string {
  if (siteId === "vietnamthuquan") return "VTQ";
  if (siteId === "nettruyen") return "NetTruyen";
  if (siteId === "truyenfull") return "TruyenFull";
  if (!siteId || siteId === "generic") return "Web";
  return siteId.replace(/-/g, " ");
}

function ProgressBar({ value }: { value: number }) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div className="h-1.5 w-full overflow-hidden rounded-full bg-border">
      <div
        className="h-full rounded-full bg-gradient-to-r from-primary to-[#ff7a8c] transition-all duration-300"
        style={{ width: `${pct}%` }}
      />
    </div>
  );
}

function ReadingCard({ item }: { item: ReadingProgress }) {
  const chapterLabel = item.chapter_title || item.chapter_id || "Current chapter";
  const pct = Math.max(0, Math.min(100, item.progress_percentage));

  return (
    <article className="group relative overflow-hidden rounded-xl border border-border bg-card shadow-sm transition-shadow hover:shadow-md">
      <div
        className="absolute inset-y-0 left-0 w-1 bg-gradient-to-b from-primary to-[#ff7a8c] opacity-90"
        aria-hidden
      />
      <div className="flex flex-col gap-3 p-4 pl-5">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              {item.site_id && item.site_id !== "generic" ? (
                <span className="inline-flex rounded-full border border-primary/20 bg-accent px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-accent-foreground">
                  {siteLabel(item.site_id)}
                </span>
              ) : null}
              <span className="text-xs font-semibold text-muted-foreground">{pct}%</span>
            </div>
            <h3 className="line-clamp-2 text-base font-bold leading-snug tracking-tight text-foreground">
              {item.story_title}
            </h3>
            <p className="line-clamp-1 text-sm text-muted-foreground">{chapterLabel}</p>
          </div>
          {item.current_url ? (
            <a
              href={item.current_url}
              target="_blank"
              rel="noopener noreferrer"
              className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-border bg-background text-muted-foreground transition-colors hover:border-primary/30 hover:bg-accent hover:text-primary"
              aria-label="Open reading page"
            >
              <ExternalLink className="h-4 w-4" />
            </a>
          ) : null}
        </div>

        <ProgressBar value={pct} />

        <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs font-medium text-muted-foreground">
          <span>{pct}% read</span>
          {item.reading_time_seconds > 0 ? (
            <span>{Math.round(item.reading_time_seconds / 60)} min</span>
          ) : null}
          <span>{formatRelativeTime(item.last_read_at)}</span>
        </div>
      </div>
    </article>
  );
}

export function ReadingProgressList() {
  const { data, isLoading, error, isFetching } = useQuery({
    queryKey: ["reading-progress", "current"],
    queryFn: () => api.currentReadingProgress(),
    refetchInterval: 30_000,
    refetchOnWindowFocus: true,
  });

  if (isLoading) {
    return (
      <div className="space-y-3">
        {[1, 2].map((i) => (
          <div
            key={i}
            className="h-28 animate-pulse rounded-xl border border-border bg-muted/60"
            aria-hidden
          />
        ))}
      </div>
    );
  }

  if (error) {
    return (
      <p className="text-sm text-destructive">
        {error instanceof Error ? error.message : "Failed to load reading progress."}
      </p>
    );
  }

  const items = data?.items ?? [];
  if (items.length === 0) {
    return (
      <div className="rounded-xl border border-dashed border-border bg-card/60 p-10 text-center">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-accent text-primary">
          <BookOpen className="h-6 w-6" />
        </div>
        <p className="font-semibold">No reading progress yet</p>
        <p className="mt-1 text-sm text-muted-foreground">
          Story Tracker data appears here after sync from the extension. Sign in with the same
          account on both extension and this site, then use &quot;Đồng bộ tất cả lên DB&quot; in the
          extension popup.
        </p>
        <p className="mt-3 text-xs text-muted-foreground">
          Notes &amp; bookmarks below are separate — they are not synced from Story Tracker.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <p className="text-[10px] font-bold uppercase tracking-[0.08em] text-muted-foreground">
          Recent stories
        </p>
        <span className="rounded-full border border-border bg-muted px-2.5 py-0.5 text-xs font-semibold text-muted-foreground">
          {items.length}
        </span>
      </div>
      {isFetching && !isLoading ? (
        <p className="text-xs text-muted-foreground">Refreshing from Story Tracker…</p>
      ) : null}
      <div className="grid gap-3 sm:grid-cols-2">
        {items.map((item) => (
          <ReadingCard key={item.id} item={item} />
        ))}
      </div>
    </div>
  );
}
