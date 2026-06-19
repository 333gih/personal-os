"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Search as SearchIcon } from "lucide-react";
import Link from "next/link";
import { api } from "@/services/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { domainLabel, typeLabel } from "@/lib/utils";

export default function SearchPage() {
  const [query, setQuery] = useState("");
  const [submitted, setSubmitted] = useState("");
  const [mode, setMode] = useState("hybrid");

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ["search", submitted, mode],
    queryFn: () => api.search(submitted, mode),
    enabled: submitted.length > 0,
  });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(query);
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Search</h1>
        <p className="text-muted-foreground">Full-text and semantic search across your knowledge</p>
      </div>

      <form onSubmit={handleSearch} className="sticky top-[calc(3.25rem+var(--safe-top))] z-20 -mx-4 flex flex-col gap-2 bg-background/95 px-4 py-2 backdrop-blur sm:static sm:mx-0 sm:bg-transparent sm:p-0 sm:backdrop-blur-none">
        <Input
          placeholder="Search courses, projects, ideas..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="min-h-11 min-w-0 flex-1 text-base"
          autoComplete="off"
          enterKeyHint="search"
        />
        <Button type="submit" className="min-h-11 w-full shrink-0 sm:w-auto">
          <SearchIcon className="mr-2 h-4 w-4" />
          Search
        </Button>
      </form>

      <div className="flex flex-wrap gap-2">
        {(["hybrid", "fulltext", "semantic"] as const).map((m) => (
          <Button
            key={m}
            size="sm"
            variant={mode === m ? "default" : "outline"}
            onClick={() => setMode(m)}
          >
            {m}
          </Button>
        ))}
      </div>

      {isLoading || isFetching ? (
        <p className="text-muted-foreground">Searching...</p>
      ) : submitted ? (
        <div className="space-y-3">
          <p className="text-sm text-muted-foreground">
            {data?.count ?? 0} results for &ldquo;{submitted}&rdquo;
          </p>
          {(data?.results || []).map(({ entity, score, match_type }) => (
            <Link key={entity.id} href={`/entities/${entity.id}`}>
              <Card className="transition-shadow hover:shadow-md">
                <CardContent className="p-4">
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <div className="min-w-0 flex-1">
                      <h3 className="font-medium">{entity.title}</h3>
                      <p className="text-xs text-muted-foreground">
                        {domainLabel(entity.domain)} · {typeLabel(entity.type)}
                      </p>
                    </div>
                    <div className="flex shrink-0 flex-wrap gap-2">
                      <Badge className="bg-muted text-muted-foreground">{match_type}</Badge>
                      <Badge className="bg-primary/10 text-primary">{score.toFixed(2)}</Badge>
                    </div>
                  </div>
                  <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">
                    {entity.content}
                  </p>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      ) : null}
    </div>
  );
}
