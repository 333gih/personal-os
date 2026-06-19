"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Briefcase,
  Cloud,
  FileText,
  Plus,
  Rocket,
  Sparkles,
  Target,
} from "lucide-react";
import Link from "next/link";
import { EmptyState } from "@/components/mobile/empty-state";
import { ListRow } from "@/components/mobile/list-row";
import { LoadingState } from "@/components/mobile/loading-state";
import { SectionHeader } from "@/components/mobile/section-header";
import { Button } from "@/components/ui/button";
import { api } from "@/services/api";
import { typeLabel } from "@/lib/utils";
import type { Entity } from "@/services/types";

function parseTags(tags: Entity["tags"]): string[] {
  if (Array.isArray(tags)) return tags;
  if (typeof tags === "string" && tags) {
    try {
      const parsed = JSON.parse(tags);
      return Array.isArray(parsed) ? parsed : [tags];
    } catch {
      return tags.split(",").map((t) => t.trim()).filter(Boolean);
    }
  }
  return [];
}

export function WorkMobile() {
  const { data, isLoading } = useQuery({
    queryKey: ["entities", "work"],
    queryFn: () => api.listEntities({ domain: "work", limit: "50" }),
  });

  const items = data?.items ?? [];
  const projects = useMemo(
    () => items.filter((e) => e.type.includes("project") || e.type.includes("feature")),
    [items],
  );
  const skills = useMemo(() => items.filter((e) => e.type.includes("technology")), [items]);
  const lessons = useMemo(() => items.filter((e) => e.type.includes("lesson") || e.type.includes("decision")), [items]);
  const latest = items[0];

  if (isLoading) return <LoadingState label="Loading career path…" />;

  return (
    <div className="space-y-6 pb-20">
      <div>
        <SectionHeader title="Timeline" actionLabel="2018 — Present" />
        <div className="mt-4 overflow-x-auto pb-2">
          <div className="flex min-w-max items-center gap-6 px-1">
            {items.length === 0 ? (
              <p className="text-sm text-muted-foreground">Add work items to build your timeline.</p>
            ) : (
              items.slice(0, 6).map((item, i) => (
                <div key={item.id} className="flex flex-col items-center gap-2">
                  <span className="max-w-[5.5rem] truncate text-[10px] text-muted-foreground">{item.title}</span>
                  <div
                    className={`h-3 w-3 rounded-full ${i === 0 ? "bg-primary ring-4 ring-primary/20" : "bg-muted-foreground/30"}`}
                  />
                </div>
              ))
            )}
          </div>
          <div className="mt-2 h-px bg-border" />
        </div>
      </div>

      {latest ? (
        <div className="rounded-3xl bg-primary p-5 text-primary-foreground shadow-card">
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-[0.14em]">
              <Sparkles className="h-4 w-4" />
              AI Sync Active
            </div>
            <Cloud className="h-5 w-5 opacity-80" />
          </div>
          <p className="font-display text-xl font-semibold">Your CV was updated recently</p>
          <p className="mt-2 text-sm text-primary-foreground/85">
            Based on &ldquo;{latest.title}&rdquo; and {items.length} tracked work items.
          </p>
          <div className="mt-4 flex flex-wrap gap-2">
            <Button asChild variant="secondary" size="sm" className="rounded-full">
              <Link href={`/entities/${latest.id}`}>Review changes</Link>
            </Button>
          </div>
        </div>
      ) : (
        <EmptyState
          icon={Briefcase}
          title="Start your career path"
          description="Add projects, skills, and decisions to build an auto-updating CV repository."
          action={
            <Button asChild>
              <Link href="/inbox">Capture work note</Link>
            </Button>
          }
        />
      )}

      <div>
        <SectionHeader title="Active Experiences" actionLabel="View all" actionHref="/work" />
        {projects.length === 0 ? (
          <div className="mt-3">
            <EmptyState
              icon={Rocket}
              title="No active projects"
              description="Create a work project entity to track roles and impact."
              className="py-8"
            />
          </div>
        ) : (
          <div className="mt-3 space-y-3">
            {projects.slice(0, 4).map((item, i) => (
              <Link key={item.id} href={`/entities/${item.id}`} className="block">
                <div className="rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-semibold">{item.title}</p>
                      <p className="text-sm text-muted-foreground">{typeLabel(item.type)}</p>
                    </div>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${
                        i === 0 ? "bg-emerald-100 text-emerald-800" : "bg-muted text-muted-foreground"
                      }`}
                    >
                      {i === 0 ? "Primary" : "Side"}
                    </span>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {parseTags(item.tags)
                      .slice(0, 3)
                      .map((tag) => (
                        <span key={tag} className="rounded-md bg-muted px-2 py-0.5 text-xs text-muted-foreground">
                          {tag}
                        </span>
                      ))}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      <div>
        <SectionHeader title="CV Repository" eyebrow="Auto-prioritized by recency" />
        <div className="mt-3 space-y-3">
          <div className="mobile-card p-4">
            <div className="mb-3 flex items-center gap-2">
              <Briefcase className="h-5 w-5 text-primary" />
              <span className="text-xs font-bold uppercase tracking-wide">Work History</span>
            </div>
            {lessons.length === 0 && projects.length === 0 ? (
              <p className="text-sm text-muted-foreground">No history entries yet.</p>
            ) : (
              <div className="space-y-3 border-l-2 border-primary pl-4">
                {[...projects, ...lessons].slice(0, 4).map((item) => (
                  <Link key={item.id} href={`/entities/${item.id}`} className="block">
                    <p className="font-medium">{item.title}</p>
                    <p className="line-clamp-2 text-sm text-muted-foreground">{item.content}</p>
                  </Link>
                ))}
              </div>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="mobile-card p-4">
              <div className="mb-2 flex items-center gap-2">
                <Target className="h-4 w-4 text-primary" />
                <span className="text-xs font-bold uppercase tracking-wide">Skills</span>
              </div>
              {skills.length === 0 ? (
                <p className="text-xs text-muted-foreground">Add technology entities.</p>
              ) : (
                <ul className="space-y-2 text-sm">
                  {skills.slice(0, 3).map((s) => (
                    <li key={s.id} className="flex justify-between gap-2">
                      <span className="truncate">{s.title}</span>
                      <span className="shrink-0 font-semibold text-primary">—</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>
            <div className="mobile-card p-4">
              <div className="mb-2 flex items-center gap-2">
                <FileText className="h-4 w-4 text-primary" />
                <span className="text-xs font-bold uppercase tracking-wide">Projects</span>
              </div>
              {projects.length === 0 ? (
                <p className="text-xs text-muted-foreground">No projects yet.</p>
              ) : (
                <Link href={`/entities/${projects[0].id}`} className="block">
                  <div className="mb-2 h-16 rounded-xl bg-gradient-to-br from-muted to-muted-foreground/20" />
                  <p className="text-sm font-medium">{projects[0].title}</p>
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="fixed inset-x-4 bottom-[calc(var(--mobile-nav-height)+var(--safe-bottom)+0.75rem)] z-20 flex gap-3 lg:hidden">
        <Button asChild className="h-12 flex-1 rounded-2xl bg-foreground text-background">
          <Link href="/search?domain=work">
            <FileText className="mr-2 h-4 w-4" />
            Generate tailored CV
          </Link>
        </Button>
        <Button asChild size="icon" className="h-12 w-12 shrink-0 rounded-full">
          <Link href="/inbox" aria-label="Add work item">
            <Plus className="h-5 w-5" />
          </Link>
        </Button>
      </div>
    </div>
  );
}
