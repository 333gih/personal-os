"use client";

import Link from "next/link";
import { cn, domainLabel, formatDateTime, parseTags, typeLabel } from "@/lib/utils";
import type { Entity } from "@/services/types";
import { Badge } from "./ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

export function EntityCard({ entity }: { entity: Entity }) {
  const tags = parseTags(entity.tags);

  return (
    <Link href={`/entities/${entity.id}`}>
      <Card className="transition-shadow hover:shadow-md">
        <CardHeader className="pb-2">
          <div className="flex items-start justify-between gap-2">
            <CardTitle className="text-base">{entity.title}</CardTitle>
            <Badge className="shrink-0 bg-primary/10 text-primary">
              {domainLabel(entity.domain)}
            </Badge>
          </div>
          <p className="text-xs text-muted-foreground">{typeLabel(entity.type)}</p>
        </CardHeader>
        <CardContent>
          <p className="line-clamp-2 text-sm text-muted-foreground">{entity.content}</p>
          {tags.length > 0 && (
            <div className="mt-3 flex flex-wrap gap-1">
              {tags.slice(0, 4).map((tag) => (
                <Badge key={tag} className="border bg-background text-xs font-normal">
                  {tag}
                </Badge>
              ))}
            </div>
          )}
          <p className="mt-2 text-xs text-muted-foreground">
            Updated {formatDateTime(entity.updated_at)}
          </p>
        </CardContent>
      </Card>
    </Link>
  );
}

export function EntityList({ entities, emptyMessage }: { entities: Entity[]; emptyMessage?: string }) {
  if (entities.length === 0) {
    return (
      <p className="py-12 text-center text-muted-foreground">
        {emptyMessage || "No items yet."}
      </p>
    );
  }

  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
      {entities.map((entity) => (
        <EntityCard key={entity.id} entity={entity} />
      ))}
    </div>
  );
}
