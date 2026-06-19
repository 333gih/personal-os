import type { LucideIcon } from "lucide-react";
import Link from "next/link";
import { ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

type ListRowProps = {
  title: string;
  subtitle?: string;
  badge?: string;
  icon?: LucideIcon;
  iconClassName?: string;
  href?: string;
  onClick?: () => void;
  trailing?: React.ReactNode;
  className?: string;
};

export function ListRow({
  title,
  subtitle,
  badge,
  icon: Icon,
  iconClassName,
  href,
  onClick,
  trailing,
  className,
}: ListRowProps) {
  const content = (
    <div
      className={cn(
        "flex min-h-[4.25rem] items-center gap-3 rounded-2xl bg-card px-4 py-3 shadow-sm ring-1 ring-border/50",
        (href || onClick) && "active:bg-accent/40",
        className,
      )}
    >
      {Icon ? (
        <div
          className={cn(
            "flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-muted",
            iconClassName,
          )}
        >
          <Icon className="h-5 w-5" />
        </div>
      ) : null}
      <div className="min-w-0 flex-1">
        {badge ? (
          <span className="mb-1 inline-block rounded-md bg-muted px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-muted-foreground">
            {badge}
          </span>
        ) : null}
        <p className="truncate font-medium">{title}</p>
        {subtitle ? <p className="truncate text-sm text-muted-foreground">{subtitle}</p> : null}
      </div>
      {trailing ?? (href || onClick ? <ChevronRight className="h-5 w-5 shrink-0 text-muted-foreground" /> : null)}
    </div>
  );

  if (href) return <Link href={href}>{content}</Link>;
  if (onClick) {
    return (
      <button type="button" onClick={onClick} className="w-full text-left">
        {content}
      </button>
    );
  }
  return content;
}
