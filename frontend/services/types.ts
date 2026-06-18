export interface Entity {
  id: string;
  user_id: string;
  type: string;
  title: string;
  content: string;
  tags: string[] | string;
  source: string;
  metadata: Record<string, unknown>;
  status: string;
  domain: string;
  created_at: string;
  updated_at: string;
}

export interface Relationship {
  id: string;
  source_entity_id: string;
  target_entity_id: string;
  relation_type: string;
  created_at: string;
}

export interface RelationWithEntity extends Relationship {
  related_entity: Entity;
  direction: "incoming" | "outgoing";
}

export interface Reminder {
  id: string;
  entity_id: string;
  title: string;
  due_at: string;
  status: string;
}

export interface EntityDetail {
  entity: Entity;
  relations: RelationWithEntity[];
  reminders: Reminder[];
  timeline: { type: string; title: string; timestamp: string }[];
  insights?: AIAnalyzeResult;
}

export interface AIAnalyzeResult {
  classification?: string;
  suggested_type?: string;
  summary?: string;
  tags?: string[];
  action_items?: string[];
  suggested_relations?: {
    target_title: string;
    relation_type: string;
    reason: string;
  }[];
  insights?: string;
}

export interface DashboardData {
  domain_counts: Record<string, number>;
  recent: Entity[];
  upcoming_reminders: Reminder[];
  inbox_count: number;
}

export interface SearchResult {
  entity: Entity;
  score: number;
  match_type: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface ReadingProgress {
  id: string;
  user_id: string;
  story_id: string;
  story_title: string;
  chapter_id?: string;
  chapter_title?: string;
  current_url: string;
  progress_percentage: number;
  scroll_y: number;
  reading_time_seconds: number;
  site_id: string;
  metadata?: Record<string, unknown>;
  client_timestamp?: string;
  last_read_at: string;
  created_at: string;
  updated_at: string;
}
