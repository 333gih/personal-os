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

      <form onSubmit={handleSearch} className="flex gap-2">
        <Input
          placeholder="Search courses, projects, ideas..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className="flex-1"
        />
        <Button type="submit">
          <SearchIcon className="mr-2 h-4 w-4" />
          Search
        </Button>
      </form>

      <div className="flex gap-2">
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
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="font-medium">{entity.title}</h3>
                      <p className="text-xs text-muted-foreground">
                        {domainLabel(entity.domain)} · {typeLabel(entity.type)}
                      </p>
                    </div>
                    <div className="flex gap-2">
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
