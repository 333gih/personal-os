"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/services/api";
import { EntityList } from "@/components/entity-card";
import { InboxCapture } from "@/features/inbox/inbox-capture";

const DOMAIN_TYPES: Record<string, { label: string; types?: { value: string; label: string }[] }> = {
  inbox: { label: "Inbox" },
  learning: {
    label: "Learning",
    types: [
      { value: "learning_course", label: "Course" },
      { value: "learning_certificate", label: "Certificate" },
      { value: "learning_skill", label: "Skill" },
      { value: "learning_topic", label: "Topic" },
      { value: "learning_note", label: "Note" },
    ],
  },
  work: {
    label: "Work",
    types: [
      { value: "work_project", label: "Project" },
      { value: "work_feature", label: "Feature" },
      { value: "work_technology", label: "Technology" },
      { value: "work_problem", label: "Problem" },
      { value: "work_decision", label: "Decision" },
      { value: "work_lesson", label: "Lesson" },
    ],
  },
  startup: {
    label: "Startup",
    types: [
      { value: "startup_idea", label: "Idea" },
      { value: "startup_pain_point", label: "Pain Point" },
      { value: "startup_business_model", label: "Business Model" },
      { value: "startup_feature", label: "Feature" },
      { value: "startup_kpi", label: "KPI" },
      { value: "startup_competitor", label: "Competitor" },
    ],
  },
};

export function DomainPage({ domain }: { domain: string }) {
  const config = DOMAIN_TYPES[domain];

  const { data, isLoading } = useQuery({
    queryKey: ["entities", domain],
    queryFn: () => api.listEntities({ domain, limit: "50" }),
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{config?.label || domain}</h1>
        <p className="text-muted-foreground">
          {data?.total ?? 0} items tracked
        </p>
      </div>

      {domain === "inbox" && <InboxCapture />}

      {isLoading ? (
        <p className="text-muted-foreground">Loading...</p>
      ) : (
        <EntityList
          entities={data?.items || []}
          emptyMessage={`No ${config?.label.toLowerCase() || domain} items yet.`}
        />
      )}
    </div>
  );
}

export { DOMAIN_TYPES };
