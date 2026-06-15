"use client";

import { useState } from "react";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Sparkles } from "lucide-react";
import { api } from "@/services/api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

interface InboxCaptureProps {
  defaultType?: string;
  onSuccess?: () => void;
}

export function InboxCapture({ defaultType = "inbox_note", onSuccess }: InboxCaptureProps) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [inputType, setInputType] = useState<"text" | "url" | "note">("note");
  const queryClient = useQueryClient();

  const typeMap = {
    text: "inbox_text",
    url: "inbox_url",
    note: "inbox_note",
  };

  const create = useMutation({
    mutationFn: () =>
      api.createEntity({
        type: defaultType === "inbox_note" ? typeMap[inputType] : defaultType,
        title: title || (inputType === "url" ? content : "Untitled"),
        content,
        source: inputType,
      }),
    onSuccess: () => {
      setTitle("");
      setContent("");
      queryClient.invalidateQueries({ queryKey: ["entities"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
      onSuccess?.();
    },
  });

  const analyze = useMutation({
    mutationFn: () => api.analyze({ content, action: "full" }),
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg">Capture to Inbox</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          {(["note", "url", "text"] as const).map((t) => (
            <Button
              key={t}
              size="sm"
              variant={inputType === t ? "default" : "outline"}
              onClick={() => setInputType(t)}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </Button>
          ))}
        </div>
        {inputType !== "url" && (
          <Input
            placeholder="Title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        )}
        <Textarea
          placeholder={
            inputType === "url"
              ? "Paste URL..."
              : "Write your note, idea, or transcript..."
          }
          rows={4}
          value={content}
          onChange={(e) => setContent(e.target.value)}
        />
        <div className="flex flex-col gap-2 sm:flex-row">
          <Button
            className="w-full sm:w-auto"
            onClick={() => create.mutate()}
            disabled={!content || create.isPending}
          >
            Save to Inbox
          </Button>
          <Button
            variant="outline"
            className="w-full sm:w-auto"
            onClick={() => analyze.mutate()}
            disabled={!content || analyze.isPending}
          >
            <Sparkles className="mr-2 h-4 w-4" />
            AI Preview
          </Button>
        </div>
        {analyze.data && (
          <div className="rounded-md border bg-muted/50 p-4 text-sm">
            {analyze.data.summary && <p className="mb-2">{analyze.data.summary}</p>}
            {analyze.data.suggested_type && (
              <p className="text-muted-foreground">
                Suggested type: {analyze.data.suggested_type}
              </p>
            )}
            {analyze.data.tags && analyze.data.tags.length > 0 && (
              <p className="mt-1 text-muted-foreground">
                Tags: {analyze.data.tags.join(", ")}
              </p>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
