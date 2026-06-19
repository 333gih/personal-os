import type { LucideIcon } from "lucide-react";
import Link from "next/link";
import { cn } from "@/lib/utils";

type MetricCardProps = {
  label: string;
  value: string;
  hint?: string;
  icon?: LucideIcon;
  href?: string;
  accent?: "default" | "success" | "primary";
  className?: string;
};

export function MetricCard({
  label,
  value,
  hint,
  icon: Icon,
  href,
  accent = "default",
  className,
}: MetricCardProps) {
  const body = (
    <div
      className={cn(
        "rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/60 transition-shadow active:scale-[0.99]",
        href && "hover:shadow-md",
        className,
      )}
    >
      <div className="mb-3 flex items-start justify-between gap-2">
        <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-muted-foreground">
          {label}
        </p>
        {Icon ? (
          <Icon
            className={cn(
              "h-5 w-5",
              accent === "success" && "text-emerald-600",
              accent === "primary" && "text-primary",
              accent === "default" && "text-muted-foreground",
            )}
          />
        ) : null}
      </div>
      <p className="font-display text-2xl font-semibold tracking-tight">{value}</p>
      {hint ? <p className="mt-1 text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );

  if (href) return <Link href={href}>{body}</Link>;
  return body;
}
