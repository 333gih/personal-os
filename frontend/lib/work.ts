import type { Entity } from "@/services/types";

export interface WorkMetadata {
  kind?: string;
  company?: string;
  role?: string;
  start_date?: string;
  end_date?: string | null;
  status?: "active" | "completed" | "paused";
  location?: string;
  team_size?: number | null;
  stack?: string[];
  design_images?: string[];
  image?: string;
  priority?: "primary" | "side";
  work_hours?: string;
  level?: string;
  years?: number;
  project_id?: string;
  doc_type?: string;
  has_design_system?: boolean;
  architecture_layers?: { layer: string; nodes: string[] }[];
  cv_status?: "in_cv" | "recommended_add";
  cv_section?: string;
}

export function workMeta(entity: Entity): WorkMetadata {
  return (entity.metadata ?? {}) as WorkMetadata;
}

export function parseEntityTags(tags: Entity["tags"]): string[] {
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

export function workSortKey(entity: Entity): number {
  const meta = workMeta(entity);
  const raw = meta.end_date ?? meta.start_date ?? entity.updated_at;
  if (!raw) return 0;
  const t = Date.parse(String(raw));
  return Number.isNaN(t) ? 0 : t;
}

/** Newest career milestone first */
export function sortWorkByDate(entities: Entity[]): Entity[] {
  return [...entities].sort((a, b) => workSortKey(b) - workSortKey(a));
}

export function formatWorkPeriod(meta: WorkMetadata): string {
  const start = meta.start_date ? formatMonthYear(meta.start_date) : "";
  const end =
    meta.end_date && meta.end_date !== "null"
      ? formatMonthYear(meta.end_date)
      : meta.status === "active"
        ? "Present"
        : "";
  if (start && end) return `${start} — ${end}`;
  if (start) return `${start} — Present`;
  return end || "";
}

function formatMonthYear(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleDateString(undefined, { month: "short", year: "numeric" });
}

export function timelineLabel(entity: Entity): string {
  const meta = workMeta(entity);
  if (entity.type === "work_role" || entity.type === "work_employer") {
    return formatWorkPeriod(meta) || entity.title;
  }
  if (meta.company) return meta.company;
  return entity.title;
}

export function isActiveWork(entity: Entity): boolean {
  const meta = workMeta(entity);
  return meta.status === "active" || (!meta.status && entity.status === "active");
}

export function filterByType(entities: Entity[], ...needles: string[]): Entity[] {
  return entities.filter((e) => needles.some((n) => e.type.includes(n)));
}

export function careerSpan(roles: Entity[]): string {
  const dated = roles.filter((r) => workMeta(r).start_date);
  if (dated.length === 0) return "";
  const years = dated
    .map((r) => workMeta(r).start_date!.slice(0, 4))
    .concat(
      dated.map((r) => {
        const end = workMeta(r).end_date;
        return end ? end.slice(0, 4) : new Date().getFullYear().toString();
      }),
    );
  const min = Math.min(...years.map(Number));
  const max = Math.max(...years.map(Number));
  return `${min} — ${max === new Date().getFullYear() ? "Present" : max}`;
}

export function projectSubtitle(entity: Entity): string {
  const meta = workMeta(entity);
  const parts = [meta.company, meta.role, formatWorkPeriod(meta)].filter(Boolean);
  return parts.join(" · ");
}

export function designImage(entity: Entity): string | null {
  const meta = workMeta(entity);
  if (meta.image) return meta.image;
  if (meta.design_images?.length) return meta.design_images[0];
  return null;
}

export function architectureLayers(entity: Entity): { layer: string; nodes: string[] }[] {
  return workMeta(entity).architecture_layers ?? [];
}

export function filterCVEntries(entities: Entity[], status: "in_cv" | "recommended_add"): Entity[] {
  return entities.filter((e) => e.type === "work_cv_entry" && workMeta(e).cv_status === status);
}

/** Human-readable metadata rows for entity detail (work domain). */
export function workMetadataRows(entity: Entity): { label: string; value: string }[] {
  const meta = workMeta(entity);
  const rows: { label: string; value: string }[] = [];
  if (meta.company) rows.push({ label: "Company", value: meta.company });
  if (meta.role) rows.push({ label: "Role", value: meta.role });
  const period = formatWorkPeriod(meta);
  if (period) rows.push({ label: "Period", value: period });
  if (meta.location) rows.push({ label: "Location", value: meta.location });
  if (meta.level) rows.push({ label: "Level", value: meta.level });
  if (meta.cv_status) {
    rows.push({
      label: "CV",
      value: meta.cv_status === "in_cv" ? "On resume" : "Recommended add",
    });
  }
  if (meta.work_hours) rows.push({ label: "Hours", value: meta.work_hours.replace("-", " – ") });
  if (meta.stack?.length) rows.push({ label: "Stack", value: meta.stack.join(", ") });
  return rows;
}

export const WORK_HOURS_DEFAULT = "08:00 — 17:00 ICT";
