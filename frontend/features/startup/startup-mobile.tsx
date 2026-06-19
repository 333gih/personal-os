"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Building2,
  Clock,
  Heart,
  Mail,
  Plus,
  TrendingUp,
  UserPlus,
} from "lucide-react";
import Link from "next/link";
import { EmptyState } from "@/components/mobile/empty-state";
import { ListRow } from "@/components/mobile/list-row";
import { LoadingState } from "@/components/mobile/loading-state";
import { MetricCard } from "@/components/mobile/metric-card";
import { SectionHeader } from "@/components/mobile/section-header";
import { Button } from "@/components/ui/button";
import { api } from "@/services/api";
import { formatDateTime, typeLabel } from "@/lib/utils";
import type { Entity } from "@/services/types";

function relativeTime(iso: string) {
  const diff = Date.now() - new Date(iso).getTime();
  const hours = Math.floor(diff / 3_600_000);
  if (hours < 1) return "Just now";
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

function activityIcon(entity: Entity) {
  if (entity.type.includes("competitor")) return Heart;
  if (entity.type.includes("kpi")) return Mail;
  return UserPlus;
}

export function StartupMobile() {
  const { data, isLoading } = useQuery({
    queryKey: ["entities", "startup"],
    queryFn: () => api.listEntities({ domain: "startup", limit: "50" }),
  });

  const { data: dashboard } = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => api.dashboard(),
  });

  const items = data?.items ?? [];
  const ideas = useMemo(() => items.filter((e) => e.type.includes("idea")), [items]);
  const kpis = useMemo(() => items.filter((e) => e.type.includes("kpi")), [items]);
  const recent = useMemo(
    () => [...items].sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()),
    [items],
  );

  if (isLoading) return <LoadingState label="Loading startup ecosystem…" />;

  const total = data?.total ?? 0;
  const pending = items.filter((e) => e.status !== "done" && e.status !== "archived").length;

  return (
    <div className="space-y-6 pb-20">
      <div className="grid grid-cols-2 gap-3">
        <MetricCard
          label="Total Portfolio"
          value={total > 0 ? String(total) : "—"}
          hint={total > 0 ? "Tracked startup entities" : "Start capturing ideas"}
          icon={TrendingUp}
          accent="success"
        />
        <MetricCard
          label="Active Companies"
          value={String(ideas.length || total)}
          hint={pending > 0 ? `${pending} pending` : "All clear"}
          icon={Building2}
        />
      </div>

      <div>
        <SectionHeader title="Portfolio Highlights" actionLabel="View all" actionHref="/startup" />
        {ideas.length === 0 && items.length === 0 ? (
          <div className="mt-3">
            <EmptyState
              icon={Building2}
              title="No portfolio yet"
              description="Capture startup ideas, KPIs, and competitors to build your ecosystem view."
              action={
                <Button asChild>
                  <Link href="/inbox">Add startup idea</Link>
                </Button>
              }
            />
          </div>
        ) : (
          <div className="mt-3 space-y-3">
            {(ideas.length ? ideas : items).slice(0, 3).map((item, i) => (
              <Link key={item.id} href={`/entities/${item.id}`} className="block">
                <div className="rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
                  <div className="mb-3 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-muted font-bold">
                        {item.title.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="font-semibold">{item.title}</p>
                        <p className="text-xs text-muted-foreground">{typeLabel(item.type)}</p>
                      </div>
                    </div>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${
                        i === 0 ? "bg-primary/15 text-primary" : "bg-emerald-100 text-emerald-800"
                      }`}
                    >
                      {i === 0 ? "Growth" : "Steady"}
                    </span>
                  </div>
                  <p className="line-clamp-2 text-sm text-muted-foreground">{item.content}</p>
                  <div className="mt-3 flex flex-wrap gap-2">
                    <Button size="sm" variant="outline" className="h-8 rounded-full text-xs" asChild>
                      <span>Dashboard</span>
                    </Button>
                    {i === 0 ? (
                      <Button size="sm" className="h-8 rounded-full text-xs">
                        Quick Connect
                      </Button>
                    ) : null}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>

      <div>
        <SectionHeader title="Network Activity" />
        {recent.length === 0 ? (
          <EmptyState
            icon={Mail}
            title="No recent activity"
            description="Updates from your startup entities will appear here."
            className="mt-3 py-8"
          />
        ) : (
          <div className="mt-3 space-y-2">
            {recent.slice(0, 3).map((item) => {
              const Icon = activityIcon(item);
              return (
                <ListRow
                  key={item.id}
                  title={item.title}
                  subtitle={`${typeLabel(item.type)} · ${relativeTime(item.updated_at)}`}
                  icon={Icon}
                  iconClassName="text-primary bg-primary/10"
                  href={`/entities/${item.id}`}
                />
              );
            })}
          </div>
        )}
      </div>

      <div>
        <SectionHeader title="Startup Schedule" />
        {(dashboard?.upcoming_reminders ?? []).length === 0 ? (
          <EmptyState
            icon={Clock}
            title="No upcoming events"
            description="Link reminders to startup entities to see your schedule."
            className="mt-3 py-8"
          />
        ) : (
          <div className="mt-3 space-y-3">
            {dashboard!.upcoming_reminders.slice(0, 4).map((r) => (
              <div key={r.id} className="flex gap-4 rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
                <div className="w-12 shrink-0 text-center">
                  <p className="text-xs font-bold uppercase text-muted-foreground">
                    {new Date(r.due_at).toLocaleTimeString(undefined, { hour: "numeric" })}
                  </p>
                </div>
                <div className="min-w-0 flex-1">
                  <span className="text-[10px] font-bold uppercase tracking-wide text-primary">Event</span>
                  <p className="font-semibold">{r.title}</p>
                  <p className="text-sm text-muted-foreground">Due {formatDateTime(r.due_at)}</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {kpis.length > 0 ? (
        <div className="mobile-card p-4">
          <p className="text-xs font-bold uppercase tracking-wide text-muted-foreground">Key KPIs</p>
          <ul className="mt-3 space-y-2">
            {kpis.slice(0, 3).map((k) => (
              <li key={k.id} className="flex justify-between text-sm">
                <span>{k.title}</span>
                <span className="font-semibold text-primary">→</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      <Button
        asChild
        size="icon"
        className="fixed bottom-[calc(var(--mobile-nav-height)+var(--safe-bottom)+0.75rem)] right-4 z-20 h-14 w-14 rounded-full shadow-lg lg:hidden"
      >
        <Link href="/inbox" aria-label="Add startup item">
          <Plus className="h-6 w-6" />
        </Link>
      </Button>
    </div>
  );
}
