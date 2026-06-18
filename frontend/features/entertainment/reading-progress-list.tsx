"use client";

import { useQuery } from "@tanstack/react-query";
import { ExternalLink, BookOpen } from "lucide-react";
import { api } from "@/services/api";
import type { ReadingProgress } from "@/services/types";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

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

function ProgressBar({ value }: { value: number }) {
  const pct = Math.max(0, Math.min(100, value));
  return (
    <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
      <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${pct}%` }} />
    </div>
  );
}

function ReadingCard({ item }: { item: ReadingProgress }) {
  const chapterLabel = item.chapter_title || item.chapter_id || "Current chapter";
  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0 space-y-1">
            <CardTitle className="line-clamp-2 text-base">{item.story_title}</CardTitle>
            <p className="text-sm text-muted-foreground line-clamp-1">{chapterLabel}</p>
          </div>
          {item.current_url ? (
            <a
              href={item.current_url}
              target="_blank"
              rel="noopener noreferrer"
              className="shrink-0 text-muted-foreground hover:text-foreground"
              aria-label="Open reading page"
            >
              <ExternalLink className="h-4 w-4" />
            </a>
          ) : null}
        </div>
      </CardHeader>
      <CardContent className="space-y-3">
        <ProgressBar value={item.progress_percentage} />
        <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
          <span>{item.progress_percentage}% read</span>
          {item.reading_time_seconds > 0 ? (
            <span>{Math.round(item.reading_time_seconds / 60)} min</span>
          ) : null}
          <span>{formatRelativeTime(item.last_read_at)}</span>
          {item.site_id && item.site_id !== "generic" ? <span>{item.site_id}</span> : null}
        </div>
      </CardContent>
    </Card>
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
    return <p className="text-sm text-muted-foreground">Loading reading progress…</p>;
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
      <div className="rounded-lg border border-dashed p-8 text-center">
        <BookOpen className="mx-auto mb-3 h-8 w-8 text-muted-foreground" />
        <p className="font-medium">No reading progress yet</p>
        <p className="mt-1 text-sm text-muted-foreground">
          Install the Story Tracker extension and sign in to sync what you are reading.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {isFetching && !isLoading ? (
        <p className="text-xs text-muted-foreground">Refreshing from Story Tracker…</p>
      ) : null}
      <div className="grid gap-4 sm:grid-cols-2">
        {items.map((item) => (
          <ReadingCard key={item.id} item={item} />
        ))}
      </div>
    </div>
  );
}
