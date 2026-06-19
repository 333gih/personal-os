import Link from "next/link";
import { cn } from "@/lib/utils";

type SectionHeaderProps = {
  title: string;
  actionLabel?: string;
  actionHref?: string;
  onAction?: () => void;
  className?: string;
  eyebrow?: string;
};

export function SectionHeader({
  title,
  actionLabel,
  actionHref,
  onAction,
  className,
  eyebrow,
}: SectionHeaderProps) {
  const action =
    actionLabel && actionHref ? (
      <Link href={actionHref} className="text-xs font-semibold uppercase tracking-wide text-primary">
        {actionLabel}
      </Link>
    ) : actionLabel && onAction ? (
      <button
        type="button"
        onClick={onAction}
        className="text-xs font-semibold uppercase tracking-wide text-primary"
      >
        {actionLabel}
      </button>
    ) : null;

  return (
    <div className={cn("flex items-end justify-between gap-3", className)}>
      <div>
        {eyebrow ? (
          <p className="mb-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-muted-foreground">
            {eyebrow}
          </p>
        ) : null}
        <h2 className="font-display text-xl font-semibold tracking-tight">{title}</h2>
      </div>
      {action}
    </div>
  );
}
