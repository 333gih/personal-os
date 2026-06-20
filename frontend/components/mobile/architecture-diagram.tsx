"use client";

import Image from "next/image";
import type { Entity } from "@/services/types";
import { architectureLayers, designImage } from "@/lib/work";

export function ArchitectureDiagram({ entity, compact }: { entity: Entity; compact?: boolean }) {
  const img = designImage(entity);
  const layers = architectureLayers(entity);

  if (img) {
    return (
      <div className={`relative w-full overflow-hidden rounded-xl bg-muted ${compact ? "h-28" : "aspect-[16/10]"}`}>
        <Image src={img} alt="" fill className="object-contain object-top" sizes="(max-width: 768px) 100vw, 600px" unoptimized={img.endsWith(".svg")} />
      </div>
    );
  }

  if (layers.length === 0) return null;

  return (
    <div className="space-y-2">
      {layers.slice(0, compact ? 2 : layers.length).map((layer) => (
        <div key={layer.layer} className="rounded-xl border border-border/60 bg-card p-3">
          <p className="text-[10px] font-bold uppercase tracking-wide text-primary">{layer.layer}</p>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {layer.nodes.map((node) => (
              <span key={node} className="rounded-md bg-muted px-2 py-0.5 text-[11px] text-muted-foreground">
                {node}
              </span>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
