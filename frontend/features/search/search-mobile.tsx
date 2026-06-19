"use client";

import { useEffect, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Clock,
  FileText,
  FolderKanban,
  Search as SearchIcon,
  User,
} from "lucide-react";
import Link from "next/link";
import { EmptyState } from "@/components/mobile/empty-state";
import { LoadingState } from "@/components/mobile/loading-state";
import { SectionHeader } from "@/components/mobile/section-header";
import { SegmentedControl } from "@/components/mobile/segmented-control";
import { Input } from "@/components/ui/input";
import { api } from "@/services/api";
import { addRecentSearch, clearRecentSearches, getRecentSearches } from "@/lib/recent-searches";
import { domainLabel, typeLabel } from "@/lib/utils";
import type { Entity } from "@/services/types";

type SearchMode = "hybrid" | "fulltext" | "semantic";

function resultIcon(entity: Entity) {
  if (entity.type.includes("project") || entity.domain === "startup") return FolderKanban;
  if (entity.type.includes("person") || entity.type.includes("contact")) return User;
  return FileText;
}

function resultBadge(entity: Entity) {
  if (entity.domain === "work") return "PROJECT";
  if (entity.domain === "learning") return "LEARNING";
  if (entity.domain === "startup") return "STARTUP";
  return domainLabel(entity.domain).toUpperCase();
}

export function SearchMobile() {
  const [query, setQuery] = useState("");
  const [submitted, setSubmitted] = useState("");
  const [mode, setMode] = useState<SearchMode>("hybrid");
  const [recent, setRecent] = useState<string[]>([]);

  useEffect(() => {
    setRecent(getRecentSearches());
  }, []);

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ["search", submitted, mode],
    queryFn: () => api.search(submitted, mode),
    enabled: submitted.length > 0,
  });

  const runSearch = (q: string) => {
    const trimmed = q.trim();
    if (!trimmed) return;
    setQuery(trimmed);
    setSubmitted(trimmed);
    setRecent(addRecentSearch(trimmed));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    runSearch(query);
  };

  const searching = isLoading || isFetching;
  const results = data?.results ?? [];

  return (
    <div className="space-y-6">
      <form
        onSubmit={handleSubmit}
        className="sticky top-[calc(3.25rem+var(--safe-top))] z-20 -mx-4 space-y-3 bg-background/95 px-4 py-2 backdrop-blur"
      >
        <div className="relative">
          <SearchIcon className="pointer-events-none absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Search people, projects, documents…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="h-12 rounded-2xl border-0 bg-card pl-12 text-base shadow-sm ring-1 ring-border/60"
            autoComplete="off"
            enterKeyHint="search"
          />
        </div>
        <SegmentedControl
          options={[
            { value: "hybrid", label: "Hybrid" },
            { value: "fulltext", label: "Fulltext" },
            { value: "semantic", label: "Semantic" },
          ]}
          value={mode}
          onChange={setMode}
        />
      </form>

      {!submitted && recent.length > 0 ? (
        <div>
          <SectionHeader
            title="Recent Searches"
            actionLabel="Clear all"
            onAction={() => {
              clearRecentSearches();
              setRecent([]);
            }}
          />
          <div className="mt-3 space-y-2">
            {recent.map((item) => (
              <button
                key={item}
                type="button"
                onClick={() => runSearch(item)}
                className="flex w-full items-center gap-3 rounded-2xl bg-card px-4 py-3 text-left shadow-sm ring-1 ring-border/50 active:bg-accent/40"
              >
                <Clock className="h-5 w-5 shrink-0 text-muted-foreground" />
                <span className="truncate font-medium">{item}</span>
              </button>
            ))}
          </div>
        </div>
      ) : null}

      {!submitted && recent.length === 0 ? (
        <EmptyState
          icon={SearchIcon}
          title="Search your knowledge"
          description="Find courses, projects, ideas, and documents across all domains."
        />
      ) : null}

      {submitted ? (
        <div>
          <SectionHeader
            title="Top Results"
            eyebrow={searching ? "Searching…" : `${data?.count ?? 0} results`}
          />
          {searching ? (
            <LoadingState label="Searching your library…" />
          ) : results.length === 0 ? (
            <EmptyState
              icon={SearchIcon}
              title="No matches"
              description={`Nothing found for “${submitted}”. Try another keyword or switch search mode.`}
            />
          ) : (
            <div className="mt-3 space-y-3">
              {results.map(({ entity, score, match_type }) => {
                const Icon = resultIcon(entity);
                const isFeatured = entity.type.includes("project") || entity.domain === "startup";

                if (isFeatured) {
                  return (
                    <Link key={entity.id} href={`/entities/${entity.id}`} className="block">
                      <div className="overflow-hidden rounded-3xl bg-card shadow-sm ring-1 ring-border/50">
                        <div className="relative h-36 bg-gradient-to-br from-neutral-200 to-neutral-400 dark:from-neutral-700 dark:to-neutral-900">
                          <span className="absolute left-4 top-4 rounded-md bg-white/90 px-2 py-1 text-[10px] font-bold uppercase tracking-wide text-foreground">
                            {resultBadge(entity)}
                          </span>
                        </div>
                        <div className="p-4">
                          <h3 className="font-display text-lg font-semibold">{entity.title}</h3>
                          <p className="mt-1 line-clamp-2 text-sm text-muted-foreground">{entity.content}</p>
                          <div className="mt-3 flex gap-2 text-xs text-muted-foreground">
                            <span className="rounded-full bg-muted px-2 py-0.5">{match_type}</span>
                            <span className="rounded-full bg-primary/10 px-2 py-0.5 text-primary">
                              {score.toFixed(2)}
                            </span>
                          </div>
                        </div>
                      </div>
                    </Link>
                  );
                }

                return (
                  <Link key={entity.id} href={`/entities/${entity.id}`} className="block">
                    <div className="flex items-center gap-3 rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
                      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-muted">
                        <Icon className="h-6 w-6 text-muted-foreground" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <span className="text-[10px] font-bold uppercase tracking-wide text-emerald-700">
                          {resultBadge(entity)}
                        </span>
                        <p className="truncate font-semibold">{entity.title}</p>
                        <p className="truncate text-sm text-muted-foreground">
                          {typeLabel(entity.type)} · {match_type}
                        </p>
                      </div>
                    </div>
                  </Link>
                );
              })}
            </div>
          )}
        </div>
      ) : null}
    </div>
  );
}
