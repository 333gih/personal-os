"use client";

import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Briefcase,
  Clock,
  FileText,
  Image as ImageIcon,
  Plus,
  Sparkles,
  Target,
} from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { EmptyState } from "@/components/mobile/empty-state";
import { LoadingState } from "@/components/mobile/loading-state";
import { SectionHeader } from "@/components/mobile/section-header";
import { Button } from "@/components/ui/button";
import { ArchitectureDiagram } from "@/components/mobile/architecture-diagram";
import { api } from "@/services/api";
import {
  architectureLayers,
  careerSpan,
  designImage,
  filterByType,
  filterCVEntries,
  formatWorkPeriod,
  isActiveWork,
  parseEntityTags,
  projectSubtitle,
  sortWorkByDate,
  timelineLabel,
  workMeta,
  WORK_HOURS_DEFAULT,
} from "@/lib/work";
import { typeLabel } from "@/lib/utils";
import type { Entity } from "@/services/types";

function RoleTimelineItem({ role }: { role: Entity }) {
  const meta = workMeta(role);
  return (
    <Link href={`/entities/${role.id}`} className="block min-w-[9rem] shrink-0">
      <div className="flex flex-col gap-2">
        <p className="text-[11px] font-medium leading-tight">{meta.company ?? role.title}</p>
        <p className="text-[10px] text-muted-foreground">{formatWorkPeriod(meta)}</p>
        <div
          className={`mx-auto h-3 w-3 rounded-full ${
            isActiveWork(role) ? "bg-primary ring-4 ring-primary/20" : "bg-muted-foreground/35"
          }`}
        />
      </div>
    </Link>
  );
}

function ProjectCard({ item, primary }: { item: Entity; primary?: boolean }) {
  const meta = workMeta(item);
  const img = designImage(item);
  const tags = parseEntityTags(item.tags);

  return (
    <Link href={`/entities/${item.id}`} className="block">
      <div className="overflow-hidden rounded-3xl bg-card shadow-sm ring-1 ring-border/50">
        {img ? (
          <div className="relative h-32 w-full bg-muted">
            <Image src={img} alt="" fill className="object-cover object-top" sizes="(max-width: 768px) 100vw, 400px" />
          </div>
        ) : null}
        <div className="p-4">
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <p className="font-semibold leading-snug">{item.title}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">{projectSubtitle(item)}</p>
            </div>
            <span
              className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${
                primary || meta.priority === "primary"
                  ? "bg-emerald-100 text-emerald-800"
                  : "bg-muted text-muted-foreground"
              }`}
            >
              {isActiveWork(item) ? "Active" : meta.status === "completed" ? "Done" : typeLabel(item.type)}
            </span>
          </div>
          {tags.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1.5">
              {tags.slice(0, 4).map((tag) => (
                <span key={tag} className="rounded-md bg-muted px-2 py-0.5 text-[11px] text-muted-foreground">
                  {tag}
                </span>
              ))}
            </div>
          )}
          {(designImage(item) || architectureLayers(item).length > 0) && (
            <div className="mt-3">
              <ArchitectureDiagram entity={item} compact />
            </div>
          )}
        </div>
      </div>
    </Link>
  );
}

export function WorkMobile() {
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["entities", "work"],
    queryFn: () => api.listEntities({ domain: "work", limit: "80" }),
  });

  const items = useMemo(() => sortWorkByDate(data?.items ?? []), [data?.items]);
  const profile = useMemo(() => items.find((e) => workMeta(e).kind === "profile"), [items]);
  const roles = useMemo(() => sortWorkByDate(filterByType(items, "work_role")), [items]);
  const projects = useMemo(() => sortWorkByDate(filterByType(items, "work_project").filter((e) => workMeta(e).kind !== "profile")), [items]);
  const activeProjects = useMemo(() => projects.filter(isActiveWork), [projects]);
  const skills = useMemo(() => filterByType(items, "work_technology"), [items]);
  const designDocs = useMemo(() => filterByType(items, "work_design_doc"), [items]);
  const cvInResume = useMemo(() => filterCVEntries(items, "in_cv"), [items]);
  const cvRecommended = useMemo(() => filterCVEntries(items, "recommended_add"), [items]);
  const insights = useMemo(() => filterByType(items, "work_lesson", "work_decision"), [items]);
  const span = careerSpan(roles);
  const workHours = profile ? (workMeta(profile).work_hours?.replace("-", " — ") ?? WORK_HOURS_DEFAULT) : WORK_HOURS_DEFAULT;

  if (isLoading) return <LoadingState label="Loading career path…" />;

  if (isError) {
    const message = error instanceof Error ? error.message : "Could not load career data";
    return (
      <EmptyState
        icon={Briefcase}
        title="Could not load career data"
        description={
          message.includes("503") || message.includes("ring-balancer")
            ? "API gateway cannot reach backend. Redeploy frontend with PERSONAL_OS_API_INTERNAL_URL or fix Kong on VPS."
            : message
        }
        action={
          <Button variant="outline" onClick={() => refetch()}>
            Retry
          </Button>
        }
      />
    );
  }

  return (
    <div className="space-y-6 pb-24">
      <div className="rounded-3xl bg-gradient-to-br from-foreground to-foreground/90 p-5 text-background shadow-card">
        <p className="text-xs font-bold uppercase tracking-[0.14em] opacity-80">Career Path</p>
        <h2 className="font-display mt-1 text-2xl font-semibold">
          {profile?.title.replace(" — Career Profile", "") ?? "Your work history"}
        </h2>
        <p className="mt-2 text-sm opacity-90 line-clamp-3">
          {profile?.content ?? "Track roles, projects, and decisions in one place."}
        </p>
        <div className="mt-4 flex flex-wrap gap-2 text-xs">
          <span className="inline-flex items-center gap-1 rounded-full bg-background/15 px-3 py-1">
            <Clock className="h-3.5 w-3.5" />
            {workHours}
          </span>
          {span && (
            <span className="rounded-full bg-background/15 px-3 py-1">{span}</span>
          )}
          <span className="rounded-full bg-background/15 px-3 py-1">{items.length} entries</span>
        </div>
      </div>

      <div>
        <SectionHeader title="Employment timeline" actionLabel={span || "History"} />
        <div className="mt-4 overflow-x-auto pb-2">
          {roles.length === 0 ? (
            <p className="text-sm text-muted-foreground">Add work roles to build your timeline.</p>
          ) : (
            <div className="flex min-w-max items-end gap-8 px-1">
              {roles.map((role) => (
                <RoleTimelineItem key={role.id} role={role} />
              ))}
            </div>
          )}
          <div className="mt-3 h-px bg-border" />
        </div>
      </div>

      {activeProjects.length > 0 && (
        <div className="rounded-3xl bg-primary p-5 text-primary-foreground shadow-card">
          <div className="mb-2 flex items-center gap-2 text-xs font-bold uppercase tracking-[0.14em]">
            <Sparkles className="h-4 w-4" />
            In focus now
          </div>
          <p className="font-display text-xl font-semibold">{activeProjects[0].title}</p>
          <p className="mt-2 text-sm text-primary-foreground/85 line-clamp-2">
            {activeProjects[0].content}
          </p>
          <Button asChild variant="secondary" size="sm" className="mt-4 rounded-full">
            <Link href={`/entities/${activeProjects[0].id}`}>Open project</Link>
          </Button>
        </div>
      )}

      <div>
        <SectionHeader title="Projects" actionLabel={`${projects.length} total`} />
        {projects.length === 0 ? (
          <EmptyState
            icon={Briefcase}
            title="No projects yet"
            description="Capture a project from inbox or run career seed migration."
            className="mt-3 py-8"
          />
        ) : (
          <div className="mt-3 space-y-3">
            {projects.slice(0, 5).map((item, i) => (
              <ProjectCard key={item.id} item={item} primary={i === 0 && isActiveWork(item)} />
            ))}
          </div>
        )}
      </div>

      {designDocs.length > 0 && (
        <div>
          <SectionHeader title="System design" actionLabel="Architecture" />
          <div className="mt-3 grid gap-3">
            {designDocs.slice(0, 3).map((doc) => {
              const img = designImage(doc);
              return (
                <Link key={doc.id} href={`/entities/${doc.id}`} className="block">
                  <div className="flex gap-3 rounded-2xl bg-card p-3 ring-1 ring-border/50">
                    <div className="relative h-16 w-24 shrink-0 overflow-hidden rounded-lg bg-muted">
                      {img ? (
                        <Image src={img} alt="" fill className="object-cover object-top" sizes="96px" />
                      ) : (
                        <div className="flex h-full items-center justify-center">
                          <ImageIcon className="h-5 w-5 text-muted-foreground" />
                        </div>
                      )}
                    </div>
                    <div className="min-w-0">
                      <p className="text-sm font-medium leading-snug">{doc.title}</p>
                      <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">{doc.content}</p>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        </div>
      )}

      {(cvInResume.length > 0 || cvRecommended.length > 0) && (
        <div>
          <SectionHeader title="CV experience" eyebrow="On resume vs should add" />
          <div className="mt-3 space-y-3">
            {cvInResume.length > 0 && (
              <div className="mobile-card p-4">
                <p className="mb-3 text-xs font-bold uppercase tracking-wide text-emerald-700">Already in CV</p>
                <ul className="space-y-3">
                  {cvInResume.slice(0, 5).map((e) => (
                    <li key={e.id}>
                      <Link href={`/entities/${e.id}`} className="block">
                        <p className="text-sm font-medium">{e.title.replace(/^CV: /, "")}</p>
                        <p className="line-clamp-2 text-xs text-muted-foreground">{e.content}</p>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            {cvRecommended.length > 0 && (
              <div className="mobile-card p-4">
                <p className="mb-3 text-xs font-bold uppercase tracking-wide text-primary">Should add to CV</p>
                <ul className="space-y-3">
                  {cvRecommended.slice(0, 4).map((e) => (
                    <li key={e.id}>
                      <Link href={`/entities/${e.id}`} className="block">
                        <p className="text-sm font-medium">{e.title.replace(/^Add to CV: /, "")}</p>
                        <p className="line-clamp-2 text-xs text-muted-foreground">{e.content}</p>
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      )}

      <div>
        <SectionHeader title="CV shelf" eyebrow="Decisions & lessons" />
        <div className="mt-3 grid grid-cols-2 gap-3">
          <div className="mobile-card col-span-2 p-4">
            <div className="mb-3 flex items-center gap-2">
              <Briefcase className="h-5 w-5 text-primary" />
              <span className="text-xs font-bold uppercase tracking-wide">Highlights</span>
            </div>
            {insights.length === 0 ? (
              <p className="text-sm text-muted-foreground">No decisions or lessons yet.</p>
            ) : (
              <div className="space-y-3 border-l-2 border-primary pl-4">
                {insights.slice(0, 4).map((item) => (
                  <Link key={item.id} href={`/entities/${item.id}`} className="block">
                    <p className="font-medium text-sm">{item.title}</p>
                    <p className="line-clamp-2 text-xs text-muted-foreground">{item.content}</p>
                  </Link>
                ))}
              </div>
            )}
          </div>

          <div className="mobile-card p-4">
            <div className="mb-2 flex items-center gap-2">
              <Target className="h-4 w-4 text-primary" />
              <span className="text-xs font-bold uppercase tracking-wide">Stack</span>
            </div>
            {skills.length === 0 ? (
              <p className="text-xs text-muted-foreground">Add technology entities.</p>
            ) : (
              <ul className="space-y-2 text-sm">
                {skills.slice(0, 5).map((s) => {
                  const meta = workMeta(s);
                  return (
                    <li key={s.id} className="flex justify-between gap-2">
                      <span className="truncate">{s.title}</span>
                      <span className="shrink-0 text-xs font-semibold capitalize text-primary">
                        {meta.level ?? "—"}
                      </span>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>

          <div className="mobile-card p-4">
            <div className="mb-2 flex items-center gap-2">
              <FileText className="h-4 w-4 text-primary" />
              <span className="text-xs font-bold uppercase tracking-wide">Roles</span>
            </div>
            {roles.slice(0, 3).map((r) => (
              <Link key={r.id} href={`/entities/${r.id}`} className="block py-1">
                <p className="text-sm font-medium">{workMeta(r).role ?? r.title}</p>
                <p className="text-[11px] text-muted-foreground">{timelineLabel(r)}</p>
              </Link>
            ))}
          </div>
        </div>
      </div>

      <div className="fixed inset-x-4 bottom-[calc(var(--mobile-nav-height)+var(--safe-bottom)+0.75rem)] z-20 flex gap-3 lg:hidden">
        <Button asChild className="h-12 flex-1 rounded-2xl bg-foreground text-background">
          <Link href="/search?domain=work">
            <FileText className="mr-2 h-4 w-4" />
            Search career context
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
