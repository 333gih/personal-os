"use client";

import { DomainPage } from "@/features/domain/domain-page";
import { ReadingProgressList } from "@/features/entertainment/reading-progress-list";

export default function EntertainmentPage() {
  return (
    <div className="space-y-10">
      <section className="space-y-4">
        <div>
          <h1 className="text-xl font-bold sm:text-2xl">Entertainment</h1>
          <p className="text-muted-foreground">
            Stories and reading progress synced from Story Tracker
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
