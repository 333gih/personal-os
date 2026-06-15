import type {
  AIAnalyzeResult,
  DashboardData,
  Entity,
  EntityDetail,
  LoginResponse,
  SearchResult,
  User,
} from "./types";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "/api/v1";

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token");
}

export function setToken(token: string) {
  localStorage.setItem("token", token);
}

export function clearToken() {
  localStorage.removeItem("token");
}

async function request<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string>),
  };

  if (!(options.body instanceof FormData)) {
    headers["Content-Type"] = "application/json";
  }

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_URL}${path}`, { ...options, headers });

  if (!res.ok) {
    const body = await res.json().catch(() => ({ error: res.statusText }));
    throw new ApiError(res.status, body.error || "Request failed");
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
  login: (email: string, password: string) =>
    request<LoginResponse>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  me: () => request<User>("/auth/me"),

  updateProfile: (data: { name: string; email?: string }) =>
    request<User>("/auth/profile", {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  changePassword: (current_password: string, new_password: string) =>
    request<{ message: string }>("/auth/password", {
      method: "PUT",
      body: JSON.stringify({ current_password, new_password }),
    }),

  listEntities: (params?: Record<string, string>) => {
    const qs = params ? "?" + new URLSearchParams(params).toString() : "";
    return request<{ items: Entity[]; total: number }>(`/entities${qs}`);
  },

  getEntity: (id: string) => request<Entity>(`/entities/${id}`),

  getEntityDetail: (id: string, insights = false) =>
    request<EntityDetail>(
      `/entities/${id}/detail${insights ? "?insights=true" : ""}`
    ),

  createEntity: (data: Partial<Entity>) =>
    request<Entity>("/entities", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  updateEntity: (id: string, data: Partial<Entity>) =>
    request<Entity>(`/entities/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  deleteEntity: (id: string) =>
    request<void>(`/entities/${id}`, { method: "DELETE" }),

  search: (query: string, mode = "hybrid", domain?: string) =>
    request<{ results: SearchResult[]; count: number }>("/search", {
      method: "POST",
      body: JSON.stringify({ query, mode, domain }),
    }),

  analyze: (data: {
    entity_id?: string;
    action?: string;
    content?: string;
    type?: string;
  }) =>
    request<AIAnalyzeResult>("/ai/analyze", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  dashboard: () => request<DashboardData>("/dashboard"),

  createRelationship: (data: {
    source_entity_id: string;
    target_entity_id: string;
    relation_type: string;
  }) =>
    request("/relationships", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  uploadFile: (file: File, entityId?: string) => {
    const form = new FormData();
    form.append("file", file);
    if (entityId) form.append("entity_id", entityId);
    return request("/files/upload", { method: "POST", body: form });
  },

  upcomingReminders: (days = 7) =>
    request<{ items: Reminder[] }>(`/reminders/upcoming?days=${days}`),

  completeReminder: (id: string) =>
    request(`/reminders/${id}/complete`, { method: "POST" }),
};

import type { Reminder } from "./types";

export { ApiError };
