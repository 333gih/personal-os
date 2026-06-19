"use client";

import { useQuery } from "@tanstack/react-query";
import { BookOpen, Briefcase, Inbox, Rocket } from "lucide-react";
import Link from "next/link";
import { EntityList } from "@/components/entity-card";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { DashboardMobile } from "@/features/dashboard/dashboard-mobile";
import { api } from "@/services/api";
import { formatDateTime } from "@/lib/utils";

const domainIcons = {
  inbox: Inbox,
  learning: BookOpen,
  work: Briefcase,
  startup: Rocket,
};

function DashboardDesktop() {
  const { data, isLoading } = useQuery({
    queryKey: ["dashboard"],
    queryFn: () => api.dashboard(),
  });

  if (isLoading) return <p className="text-muted-foreground">Loading dashboard...</p>;

  return (
    <div className="space-y-6 sm:space-y-8">
      <div>
        <h1 className="text-xl font-bold sm:text-2xl">Dashboard</h1>
        <p className="text-muted-foreground">Overview of your personal knowledge</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {(["inbox", "learning", "work", "startup"] as const).map((domain) => {
          const count = data?.domain_counts?.[domain] ?? 0;
          const Icon = domainIcons[domain] || Inbox;
          const href = domain === "inbox" ? "/inbox" : `/${domain}`;
          return (
            <Link key={domain} href={href}>
              <Card className="transition-shadow hover:shadow-md">
                <CardHeader className="flex flex-row items-center justify-between pb-2">
                  <CardTitle className="text-sm font-medium capitalize">{domain}</CardTitle>
                  <Icon className="h-4 w-4 text-muted-foreground" />
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{count}</div>
                </CardContent>
              </Card>
            </Link>
          );
        })}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div>
          <h2 className="mb-4 text-lg font-semibold">Upcoming Reminders</h2>
          {(data?.upcoming_reminders || []).length === 0 ? (
            <p className="text-sm text-muted-foreground">No upcoming reminders.</p>
          ) : (
            <div className="space-y-2">
              {data?.upcoming_reminders.map((r) => (
                <Card key={r.id}>
                  <CardContent className="flex flex-col gap-2 p-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <p className="font-medium">{r.title}</p>
                      <p className="text-xs text-muted-foreground">
                        Due {formatDateTime(r.due_at)}
                      </p>
                    </div>
                    <Badge>{r.status}</Badge>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        <div>
          <h2 className="mb-4 text-lg font-semibold">Recent Activity</h2>
          <EntityList entities={data?.recent || []} emptyMessage="No recent activity." />
        </div>
      </div>
    </div>
  );
}

export default function DashboardPage() {
  return (
    <>
      <div className="lg:hidden">
        <DashboardMobile />
      </div>
      <div className="hidden lg:block">
        <DashboardDesktop />
      </div>
    </>
  );
}
