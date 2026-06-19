"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Award,
  BookOpen,
  Calendar,
  CheckCircle2,
  GraduationCap,
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
import { typeLabel } from "@/lib/utils";

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export function LearningMobile() {
  const { data, isLoading } = useQuery({
    queryKey: ["entities", "learning"],
    queryFn: () => api.listEntities({ domain: "learning", limit: "50" }),
  });

  const items = data?.items ?? [];
  const courses = useMemo(() => items.filter((e) => e.type.includes("course")), [items]);
  const certs = useMemo(() => items.filter((e) => e.type.includes("certificate")), [items]);
  const skills = useMemo(() => items.filter((e) => e.type.includes("skill")), [items]);
  const topics = useMemo(() => items.filter((e) => e.type.includes("topic")), [items]);

  const today = new Date().getDay();
  const chartDay = today === 0 ? 6 : today - 1;

  if (isLoading) return <LoadingState label="Loading learning…" />;

  return (
    <div className="space-y-6 pb-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="font-display text-xl font-semibold">Optimizer</h2>
          <p className="text-sm text-muted-foreground">Work & Study Sync</p>
        </div>
        <Button size="sm" className="rounded-full px-4" asChild>
          <Link href="/inbox">Optimize</Link>
        </Button>
      </div>

      <div className="mobile-card p-4">
        {items.length === 0 ? (
          <EmptyState
            icon={Calendar}
            title="No schedule yet"
            description="Add courses and topics to build your study timeline."
            className="border-0 bg-transparent py-6"
          />
        ) : (
          <div className="space-y-4">
            {items.slice(0, 3).map((item, i) => (
              <div key={item.id} className="relative pl-6">
                {i < 2 ? <div className="absolute bottom-0 left-[7px] top-6 w-px bg-border" /> : null}
                <div className="absolute left-0 top-1.5 h-4 w-4 rounded-full border-2 border-primary bg-background" />
                <p className="text-xs text-muted-foreground">Block {i + 1}</p>
                <Link href={`/entities/${item.id}`} className="font-medium hover:text-primary">
                  {item.title}
                </Link>
                <span className="ml-2 rounded-md bg-muted px-2 py-0.5 text-[10px] font-bold uppercase text-muted-foreground">
                  {typeLabel(item.type)}
                </span>
                {i === 1 ? (
                  <p className="mt-2 rounded-xl bg-emerald-50 px-3 py-2 text-xs text-emerald-800">
                    Auto-optimized reminder available
                  </p>
                ) : null}
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <SectionHeader title="Current Learning" />
        <div className="mt-3 grid grid-cols-2 gap-3">
          <MetricCard
            label="Courses"
            value={String(courses.length)}
            hint={courses.length ? `${courses.length} active` : "Add a course"}
            icon={GraduationCap}
            accent="primary"
          />
          <MetricCard
            label="Streak"
            value={items.length > 0 ? `${Math.min(items.length, 30)} days` : "—"}
            hint={skills[0]?.title ? `Focus: ${skills[0].title}` : "Track daily study"}
            icon={Zap}
            accent="success"
          />
        </div>

        {courses[0] ? (
          <Link href={`/entities/${courses[0].id}`} className="mt-3 block">
            <div className="flex items-center gap-3 rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100 text-sm font-bold text-emerald-800">
                C1
              </div>
              <div>
                <p className="font-semibold">{courses[0].title}</p>
                <p className="text-sm text-muted-foreground line-clamp-1">{courses[0].content}</p>
              </div>
            </div>
          </Link>
        ) : null}
      </div>

      <div className="rounded-3xl bg-neutral-900 p-5 text-white shadow-card">
        <div className="mb-4 flex items-center justify-between">
          <div>
            <p className="font-display text-lg font-semibold">Mastery Curve</p>
            <p className="text-sm text-white/70">Learning activity index</p>
          </div>
          <span className="rounded-full bg-primary px-2 py-0.5 text-[10px] font-bold uppercase">
            {items.length >= 10 ? "Expert" : items.length >= 3 ? "Growing" : "Starter"}
          </span>
        </div>
        <div className="flex h-24 items-end justify-between gap-2">
          {WEEKDAYS.map((day, i) => (
            <div key={day} className="flex flex-1 flex-col items-center gap-2">
              <div
                className={`w-full rounded-t-md ${i === chartDay ? "bg-primary" : "bg-white/20"}`}
                style={{ height: `${20 + ((i + items.length) % 5) * 12}%` }}
              />
              <span className="text-[10px] text-white/60">{day}</span>
            </div>
          ))}
        </div>
      </div>

      <div>
        <SectionHeader title="Future Milestones" />
        {certs.length === 0 && topics.length === 0 ? (
          <div className="mt-3">
            <EmptyState
              icon={Award}
              title="No milestones yet"
              description="Add certificates and topics with target dates to track goals."
              action={
                <Button asChild variant="outline">
                  <Link href="/inbox">Add milestone</Link>
                </Button>
              }
              className="py-8"
            />
          </div>
        ) : (
          <div className="mt-3 space-y-2">
            {[...certs, ...topics].slice(0, 5).map((item) => (
              <ListRow
                key={item.id}
                title={item.title}
                subtitle={typeLabel(item.type)}
                icon={item.type.includes("certificate") ? Award : BookOpen}
                href={`/entities/${item.id}`}
                trailing={
                  item.status === "done" ? (
                    <CheckCircle2 className="h-5 w-5 text-emerald-600" />
                  ) : (
                    <span className="text-xs font-semibold text-primary">Active</span>
                  )
                }
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
