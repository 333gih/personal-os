"use client";

import { useQuery } from "@tanstack/react-query";
import { api } from "@/services/api";

export function useEntities(domain?: string, type?: string) {
  const params: Record<string, string> = { limit: "50" };
  if (domain) params.domain = domain;
  if (type) params.type = type;

  return useQuery({
    queryKey: ["entities", domain, type],
    queryFn: () => api.listEntities(params),
  });
}

export function useEntityDetail(id: string, insights = false) {
  return useQuery({
    queryKey: ["entity-detail", id, insights],
    queryFn: () => api.getEntityDetail(id, insights),
    enabled: !!id,
  });
}

export function useDashboard() {
  return useQuery({
    queryKey: ["dashboard"],
    queryFn: () => api.dashboard(),
  });
}
