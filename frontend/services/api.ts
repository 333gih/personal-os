import { portalFetch } from "@/lib/auth/client-fetch";
import { authHeaders } from "@/lib/auth/access-token";
import type {
  AIAnalyzeResult,
  DashboardData,
  Entity,
  EntityDetail,
  SearchResult,
  User,
} from "./types";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "/api/v1";
const DEBUG_API = process.env.NODE_ENV === "development";

function apiLog(label: string, data?: Record<string, unknown>) {
  if (!DEBUG_API) return;
  if (data) {
    console.log(`[api] ${label}`, data);
    return;
  }
  console.log(`[api] ${label}`);
}

class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public details?: unknown
  ) {
    super(message);
    this.name = "ApiError";
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const method = options.method || "GET";
  const url = `${API_URL}${path}`;

  const baseHeaders: Record<string, string> = {
    ...(options.headers as Record<string, string>),
  };
  if (!(options.body instanceof FormData) && !baseHeaders["Content-Type"]) {
    baseHeaders["Content-Type"] = "application/json";
  }

  const headers = await authHeaders(baseHeaders);
  const hasAuth = headers.has("Authorization");
  apiLog("request", { method, url, hasAuth });

  const res = await portalFetch(url, { ...options, headers });

  if (!res.ok) {
    const raw = await res.text();
    let body: { error?: string; message?: string } = {};
    try {
      body = raw ? JSON.parse(raw) : {};
    } catch {
      body = { error: raw || res.statusText };
    }
    const message = body.error || body.message || "Request failed";
    apiLog("response error", { method, url, status: res.status, body, hasAuth });
    throw new ApiError(res.status, message, body);
  }

  apiLog("response ok", { method, url, status: res.status, hasAuth });
  if (res.status === 204) return undefined as T;
  return res.json();
}

export const api = {
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
