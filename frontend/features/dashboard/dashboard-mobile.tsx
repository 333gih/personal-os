"use client";

import { useQuery } from "@tanstack/react-query";
import {
  BookOpen,
  Brain,
  CheckSquare,
  Lightbulb,
  PlusCircle,
  Sparkles,
  TrendingUp,
  Zap,
} from "lucide-react";
import Link from "next/link";
import { EmptyState } from "@/components/mobile/empty-state";
import { ListRow } from "@/components/mobile/list-row";
import { LoadingState } from "@/components/mobile/loading-state";
import { MetricCard } from "@/components/mobile/metric-card";
import { SectionHeader } from "@/components/mobile/section-header";
import { Button } from "@/components/ui/button";
import { api } from "@/services/api";
import { formatDateTime } from "@/lib/utils";

function firstName(name?: string) {
  if (!name) return "there";
  return name.split(/\s+/)[0] || name;
}

export function DashboardMobile() {
  const { data: user } = useQuery({ queryKey: ["me"], queryFn: () => api.me() });
  const { data, isLoading } = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => api.dashboard(),
  });

  if (isLoading) return <LoadingState label="Loading your dashboard…" />;

  const inboxCount = data?.inbox_count ?? data?.domain_counts?.inbox ?? 0;
  const learningCount = data?.domain_counts?.learning ?? 0;
  const totalItems = Object.values(data?.domain_counts ?? {}).reduce((a, b) => a + b, 0);
  const focusPct = totalItems > 0 ? Math.min(100, Math.round((learningCount / Math.max(totalItems, 1)) * 100) + 35) : 0;
  const focusLabel = totalItems > 0 ? `${focusPct}% of daily goal achieved` : "Log study time to track focus";
  const recent = data?.recent?.[0];
  const reminders = data?.upcoming_reminders ?? [];

  return (
    <div className="space-y-6 pb-2">
      <div>
        <h1 className="font-display text-3xl font-semibold tracking-tight">{firstName(user?.name)}</h1>
        <p className="mt-1 text-sm text-muted-foreground">Your personal knowledge at a glance</p>
      </div>

      <div className="mobile-card p-5">
        <div className="mb-4 flex items-center gap-2 text-emerald-700">
          <Zap className="h-4 w-4" />
          <span className="text-[11px] font-bold uppercase tracking-[0.14em]">Deep Focus</span>
        </div>
        <p className="font-display text-4xl font-semibold tracking-tight">
          {totalItems > 0 ? `${learningCount}h` : "—"}
          {totalItems > 0 ? <span className="text-2xl text-muted-foreground"> tracked</span> : null}
        </p>
        <p className="mt-1 text-sm text-muted-foreground">{focusLabel}</p>
        <div className="mt-5 h-2 overflow-hidden rounded-full bg-muted">
          <div
            className="h-full rounded-full bg-emerald-700 transition-all"
            style={{ width: `${Math.max(focusPct, totalItems > 0 ? 8 : 0)}%` }}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <MetricCard
          label="Tasks"
          value={String(inboxCount)}
          hint={inboxCount > 0 ? "In inbox to process" : "Inbox clear"}
          icon={CheckSquare}
          accent="primary"
          href="/inbox"
        />
        <MetricCard
          label="Knowledge"
          value={totalItems > 0 ? "Active" : "Empty"}
          hint={totalItems > 0 ? `${totalItems} items tracked` : "Capture your first note"}
          icon={TrendingUp}
          accent="success"
        />
      </div>

      <div>
        <SectionHeader title="Quick Actions" actionLabel="Manage" actionHref="/inbox" />
        <div className="mt-3 flex gap-3 overflow-x-auto pb-1 [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <Link
            href="/inbox"
            className="flex h-28 w-28 shrink-0 flex-col items-center justify-center gap-2 rounded-3xl bg-primary text-primary-foreground shadow-sm"
          >
            <PlusCircle className="h-7 w-7" />
            <span className="text-[11px] font-bold uppercase tracking-wide">Add Task</span>
          </Link>
          <Link
            href="/learning"
            className="flex h-28 w-28 shrink-0 flex-col items-center justify-center gap-2 rounded-3xl bg-card shadow-sm ring-1 ring-border/60"
          >
            <BookOpen className="h-7 w-7 text-foreground" />
            <span className="text-[11px] font-bold uppercase tracking-wide text-foreground">Log Study</span>
          </Link>
          <Link
            href="/search"
            className="flex h-28 w-28 shrink-0 flex-col items-center justify-center gap-2 rounded-3xl bg-card shadow-sm ring-1 ring-border/60"
          >
            <Lightbulb className="h-7 w-7 text-foreground" />
            <span className="text-[11px] font-bold uppercase tracking-wide text-foreground">Search</span>
          </Link>
        </div>
      </div>

      {recent ? (
        <div>
          <SectionHeader title="Weekly Curation" eyebrow="Featured" />
          <Link href={`/entities/${recent.id}`} className="mt-3 block">
            <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-neutral-800 to-neutral-950 p-6 text-white shadow-card">
              <p className="text-[11px] font-bold uppercase tracking-[0.14em] text-white/70">From your library</p>
              <h3 className="mt-2 font-display text-2xl font-semibold leading-tight">{recent.title}</h3>
              <p className="mt-2 line-clamp-2 text-sm text-white/75">{recent.content}</p>
              <span className="mt-5 inline-flex rounded-full bg-white px-4 py-2 text-xs font-bold uppercase tracking-wide text-neutral-900">
                Open item
              </span>
            </div>
          </Link>
        </div>
      ) : (
        <EmptyState
          icon={Sparkles}
          title="No featured content yet"
          description="Capture notes in Inbox or Learning — your latest item will appear here."
          action={
            <Button asChild>
              <Link href="/inbox">Go to Inbox</Link>
            </Button>
          }
        />
      )}

      <div>
        <SectionHeader title="Up Next" />
        {reminders.length === 0 ? (
          <div className="mt-3">
            <EmptyState
              icon={Brain}
              title="Nothing scheduled"
              description="Add reminders to entities and they will show up here."
              className="py-8"
            />
          </div>
        ) : (
          <div className="mt-3 space-y-2">
            {reminders.slice(0, 5).map((r) => (
              <ListRow
                key={r.id}
                title={r.title}
                subtitle={`Due ${formatDateTime(r.due_at)}`}
                badge={r.status}
                href={r.entity_id ? `/entities/${r.entity_id}` : undefined}
                icon={Brain}
                iconClassName="text-emerald-700 bg-emerald-50"
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
