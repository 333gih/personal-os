"use client";

import { DomainPage } from "@/features/domain/domain-page";
import { ReadingProgressList } from "@/features/entertainment/reading-progress-list";

export default function EntertainmentPage() {
  return (
    <div className="space-y-10">
      <section className="space-y-4">
        <div>
          <p className="text-[10px] font-bold uppercase tracking-[0.08em] text-primary">
            Fash &amp; Curious · Story Tracker
          </p>
          <h1 className="mt-1 text-xl font-bold tracking-tight sm:text-2xl">Entertainment</h1>
          <p className="text-muted-foreground">
            Stories and reading progress synced from the extension
          </p>
        </div>
        <ReadingProgressList />
      </section>

      <section>
        <DomainPage domain="entertainment" embedded sectionTitle="Notes & bookmarks" />
      </section>
    </div>
  );
}
