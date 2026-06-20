"use client";

import { useState } from "react";
import Image from "next/image";
import {
  ArrowDown,
  ArrowRight,
  Bolt,
  Cloud,
  Cpu,
  Cylinder,
  FileText,
  Folder,
  Globe,
  Leaf,
  Link2,
  Radio,
  Search,
  Server,
  type LucideIcon,
} from "lucide-react";
import type { Entity } from "@/services/types";
import { architectureLayers, designImage } from "@/lib/work";
import { cn } from "@/lib/utils";

const LAYER_COLORS = [
  "border-rose-200 bg-rose-50/80 text-rose-800",
  "border-sky-200 bg-sky-50/80 text-sky-800",
  "border-emerald-200 bg-emerald-50/80 text-emerald-800",
  "border-violet-200 bg-violet-50/80 text-violet-800",
  "border-amber-200 bg-amber-50/80 text-amber-800",
];

const LAYER_DOT = ["bg-rose-500", "bg-sky-500", "bg-emerald-500", "bg-violet-500", "bg-amber-500"];

function nodeIcon(name: string): LucideIcon {
  const key = name.toLowerCase();
  if (key.includes("aem") || key.includes("cms")) return FileText;
  if (key.includes("spring") || key.includes("java")) return Leaf;
  if (key.includes("nest") || key.includes("node")) return Server;
  if (key.includes("mongo") || key.includes("postgres") || key.includes("sql")) return Cylinder;
  if (key.includes("redis") || key.includes("cache")) return Bolt;
  if (key.includes("rabbit") || key.includes("kafka") || key.includes("queue")) return Radio;
  if (key.includes("gcp") || key.includes("aws") || key.includes("cloud")) return Cloud;
  if (key.includes("search") || key.includes("algolia") || key.includes("elastic")) return Search;
  if (key.includes("api") || key.includes("gateway")) return Link2;
  if (key.includes("web") || key.includes("next") || key.includes("react")) return Globe;
  if (key.includes("ftp") || key.includes("file")) return Folder;
  if (key.includes("iot") || key.includes("device")) return Cpu;
  return Cpu;
}

function NodeChip({ name, className }: { name: string; className?: string }) {
  const Icon = nodeIcon(name);
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-lg border border-border/60 bg-background/90 px-2.5 py-1 text-[11px] font-medium text-foreground shadow-sm",
        className,
      )}
    >
      <Icon className="h-3 w-3 shrink-0 opacity-70" />
      {name}
    </span>
  );
}

type DiagramMode = "flow" | "layers" | "reference";

export function ArchitectureDiagram({
  entity,
  compact,
  defaultMode,
}: {
  entity: Entity;
  compact?: boolean;
  defaultMode?: DiagramMode;
}) {
  const img = designImage(entity);
  const layers = architectureLayers(entity);
  const hasLayers = layers.length > 0;
  const hasImage = Boolean(img);

  const [mode, setMode] = useState<DiagramMode>(
    defaultMode ?? (hasLayers ? "flow" : hasImage ? "reference" : "flow"),
  );

  if (!hasLayers && !hasImage) return null;

  const showTabs = !compact && hasLayers && hasImage;

  return (
    <div className="space-y-3">
      {showTabs && (
        <div className="flex gap-1 rounded-xl bg-muted/60 p-1">
          {(["flow", "layers", "reference"] as const).map((tab) => (
            <button
              key={tab}
              type="button"
              onClick={() => setMode(tab)}
              className={cn(
                "flex-1 rounded-lg px-3 py-1.5 text-xs font-semibold capitalize transition-colors",
                mode === tab ? "bg-card text-primary shadow-sm" : "text-muted-foreground hover:text-foreground",
              )}
            >
              {tab}
            </button>
          ))}
        </div>
      )}

      {mode === "reference" && hasImage ? (
        <div
          className={cn(
            "relative w-full overflow-hidden rounded-xl border border-border/60 bg-muted",
            compact ? "h-28" : "aspect-[16/10]",
          )}
        >
          <Image
            src={img!}
            alt=""
            fill
            className="object-contain object-top p-2"
            sizes="(max-width: 768px) 100vw, 800px"
            unoptimized={img!.endsWith(".svg")}
          />
        </div>
      ) : (
        <FlowCanvas layers={compact ? layers.slice(0, 2) : layers} grid={mode === "layers"} compact={compact} />
      )}
    </div>
  );
}

function FlowCanvas({
  layers,
  grid,
  compact,
}: {
  layers: { layer: string; nodes: string[] }[];
  grid?: boolean;
  compact?: boolean;
}) {
  if (layers.length === 0) return null;

  return (
    <div className={cn("space-y-2", compact ? "space-y-1.5" : "space-y-3")}>
      {layers.map((layer, index) => (
        <div key={layer.layer}>
          <div
            className={cn(
              "rounded-xl border p-3",
              LAYER_COLORS[index % LAYER_COLORS.length],
              compact && "p-2.5",
            )}
          >
            <div className="mb-2 flex items-center justify-between gap-2">
              <div className="flex items-center gap-2">
                <span className={cn("h-2 w-2 rounded-full", LAYER_DOT[index % LAYER_DOT.length])} />
                <p className="text-[10px] font-bold uppercase tracking-wide">{layer.layer}</p>
              </div>
              {!compact && (
                <span className="text-[10px] opacity-70">{layer.nodes.length} nodes</span>
              )}
            </div>

            {grid ? (
              <div className="grid grid-cols-2 gap-1.5 sm:grid-cols-3">
                {layer.nodes.map((node) => (
                  <NodeChip key={node} name={node} className="w-full justify-center text-center" />
                ))}
              </div>
            ) : (
              <div className="flex flex-wrap items-center gap-1.5">
                {layer.nodes.map((node, nodeIndex) => (
                  <span key={node} className="inline-flex items-center gap-1.5">
                    <NodeChip name={node} />
                    {nodeIndex < layer.nodes.length - 1 && (
                      <ArrowRight className="h-3 w-3 shrink-0 opacity-40" aria-hidden />
                    )}
                  </span>
                ))}
              </div>
            )}
          </div>
          {!compact && index < layers.length - 1 && (
            <div className="flex justify-center py-0.5">
              <ArrowDown className="h-4 w-4 text-muted-foreground/50" aria-hidden />
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
