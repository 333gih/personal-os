"use client";

import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Sparkles, Trash2 } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { api } from "@/services/api";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { domainLabel, formatDateTime, parseTags, typeLabel } from "@/lib/utils";
import { designImage, formatWorkPeriod, workMeta } from "@/lib/work";
import Image from "next/image";

export default function EntityDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const router = useRouter();
  const queryClient = useQueryClient();

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["entity-detail", id],
    queryFn: () => api.getEntityDetail(id, true),
  });

  const analyze = useMutation({
    mutationFn: () => api.analyze({ entity_id: id, action: "full" }),
    onSuccess: () => refetch(),
  });

  const remove = useMutation({
    mutationFn: () => api.deleteEntity(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["entities"] });
      router.push("/dashboard");
    },
  });

  if (isLoading) return <p className="text-muted-foreground">Loading...</p>;
  if (!data) return <p className="text-destructive">Entity not found</p>;

  const { entity, relations, reminders, timeline, insights } = data;
  const tags = parseTags(entity.tags);
  const meta = workMeta(entity);
  const designImg = designImage(entity);

  return (
    <div className="mx-auto w-full max-w-4xl space-y-4 sm:space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="mb-2 flex flex-wrap gap-2">
            <Badge className="bg-primary/10 text-primary">{domainLabel(entity.domain)}</Badge>
            <Badge className="bg-muted text-muted-foreground">{typeLabel(entity.type)}</Badge>
            <Badge className="bg-muted text-muted-foreground">{entity.status}</Badge>
          </div>
          <h1 className="text-2xl font-bold">{entity.title}</h1>
          {entity.domain === "work" && (meta.company || meta.role || meta.start_date) && (
            <p className="mt-1 text-sm text-muted-foreground">
              {[meta.company, meta.role, formatWorkPeriod(meta)].filter(Boolean).join(" · ")}
            </p>
          )}
          <p className="text-sm text-muted-foreground">
            Created {formatDateTime(entity.created_at)} · Updated {formatDateTime(entity.updated_at)}
          </p>
        </div>
        <div className="flex shrink-0 flex-wrap gap-2">
          <Button
            variant="outline"
            className="flex-1 sm:flex-none"
            onClick={() => analyze.mutate()}
            disabled={analyze.isPending}
          >
            <Sparkles className="mr-2 h-4 w-4" />
            Analyze
          </Button>
          <Button variant="destructive" size="icon" onClick={() => remove.mutate()}>
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Content</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="whitespace-pre-wrap text-sm leading-relaxed">{entity.content || "No content."}</p>
          {tags.length > 0 && (
            <div className="mt-4 flex flex-wrap gap-1">
              {tags.map((tag) => (
                <Badge key={tag} className="bg-secondary text-secondary-foreground">
                  {tag}
                </Badge>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {designImg && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">System design</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="relative aspect-[16/10] w-full overflow-hidden rounded-lg bg-muted">
              <Image src={designImg} alt={entity.title} fill className="object-contain" sizes="(max-width: 768px) 100vw, 800px" />
            </div>
          </CardContent>
        </Card>
      )}

      {Object.keys(entity.metadata || {}).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Metadata</CardTitle>
          </CardHeader>
          <CardContent>
            <pre className="overflow-auto rounded-md bg-muted p-4 text-xs">
              {JSON.stringify(entity.metadata, null, 2)}
            </pre>
          </CardContent>
        </Card>
      )}

      {insights && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">AI Insights</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            {insights.summary && <p>{insights.summary}</p>}
            {insights.action_items && insights.action_items.length > 0 && (
              <div>
                <p className="font-medium">Action Items</p>
                <ul className="mt-1 list-inside list-disc text-muted-foreground">
                  {insights.action_items.map((item, i) => (
                    <li key={i}>{item}</li>
                  ))}
                </ul>
              </div>
            )}
            {insights.suggested_relations && insights.suggested_relations.length > 0 && (
              <div>
                <p className="font-medium">Suggested Relations</p>
                <ul className="mt-1 space-y-1 text-muted-foreground">
                  {insights.suggested_relations.map((rel, i) => (
                    <li key={i}>
                      {rel.relation_type} → {rel.target_title} ({rel.reason})
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Related Entities</CardTitle>
          </CardHeader>
          <CardContent>
            {relations.length === 0 ? (
              <p className="text-sm text-muted-foreground">No relationships yet.</p>
            ) : (
              <ul className="space-y-2">
                {relations.map((rel) => (
                  <li key={rel.id} className="text-sm">
                    <Link
                      href={`/entities/${rel.related_entity.id}`}
                      className="font-medium text-primary hover:underline"
                    >
                      {rel.related_entity.title}
                    </Link>
                    <span className="text-muted-foreground">
                      {" "}
                      · {rel.direction === "outgoing" ? rel.relation_type : `← ${rel.relation_type}`}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Timeline</CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-3">
              {timeline.map((event, i) => (
                <li key={i} className="flex gap-3 text-sm">
                  <span className="w-36 shrink-0 text-muted-foreground">
                    {formatDateTime(event.timestamp)}
                  </span>
                  <span>{event.title}</span>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      </div>

      {reminders.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Reminders</CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-2 text-sm">
              {reminders.map((r) => (
                <li key={r.id} className="flex justify-between">
                  <span>{r.title}</span>
                  <span className="text-muted-foreground">{formatDateTime(r.due_at)}</span>
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
