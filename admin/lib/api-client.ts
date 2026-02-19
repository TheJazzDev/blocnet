// All client requests go through /api/proxy which reads the httpOnly cookie
// server-side and forwards the Authorization header to the backend.
const PROXY_BASE = "/api/proxy";

function toQuery(params: Record<string, string | number | undefined | null>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    query.set(key, String(value));
  }
  const encoded = query.toString();
  return encoded ? `?${encoded}` : "";
}

export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${PROXY_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

export type {
  AdminMe,
  AdminStats,
  AdminUser,
  AdminUsersResponse,
  ProjectStatus,
  UpdateStatus,
  ContentStatus,
  CommunityTopic,
  AdminProject,
  AdminUpdate,
  AdminComment,
  AdminCommunityPost,
  AdminCommunityComment,
  AdminApplication,
  ProjectProposal,
  AuditLog,
  Tag,
} from "./api";

import type {
  AdminMe,
  AdminStats,
  AdminUsersResponse,
  ProjectStatus,
  UpdateStatus,
  ContentStatus,
  CommunityTopic,
  AdminProject,
  AdminUpdate,
  AdminComment,
  AdminCommunityPost,
  AdminCommunityComment,
  AdminApplication,
  ProjectProposal,
  AuditLog,
  Tag,
} from "./api";

export const clientApi = {
  getMe: () => apiFetch<AdminMe>("/me"),

  getStats: () => apiFetch<AdminStats>("/admin/users/stats"),

  listUsers: (params?: { limit?: number; offset?: number; role?: string; q?: string }) =>
    apiFetch<AdminUsersResponse>(
      `/admin/users${toQuery({
        limit: params?.limit,
        offset: params?.offset,
        role: params?.role,
        q: params?.q,
      })}`,
    ),

  listAdminProjects: (params?: {
    q?: string;
    status?: ProjectStatus;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminProject[]>(
      `/admin/content/projects${toQuery({
        q: params?.q,
        status: params?.status,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  moderateProjectStatus: (id: string, body: { status: ProjectStatus; reason: string }) =>
    apiFetch<AdminProject>(`/admin/content/projects/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAdminUpdates: (params?: {
    q?: string;
    status?: UpdateStatus;
    projectId?: string;
    authorId?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminUpdate[]>(
      `/admin/content/updates${toQuery({
        q: params?.q,
        status: params?.status,
        projectId: params?.projectId,
        authorId: params?.authorId,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  moderateUpdateStatus: (id: string, body: { status: UpdateStatus; reason: string }) =>
    apiFetch<AdminUpdate>(`/admin/content/updates/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAdminComments: (params?: {
    q?: string;
    status?: ContentStatus;
    updateId?: string;
    authorId?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminComment[]>(
      `/admin/content/comments${toQuery({
        q: params?.q,
        status: params?.status,
        updateId: params?.updateId,
        authorId: params?.authorId,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  moderateCommentStatus: (id: string, body: { status: ContentStatus; reason: string }) =>
    apiFetch<AdminComment>(`/admin/content/comments/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAdminCommunityPosts: (params?: {
    q?: string;
    status?: ContentStatus;
    topic?: CommunityTopic;
    authorId?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminCommunityPost[]>(
      `/admin/content/community-posts${toQuery({
        q: params?.q,
        status: params?.status,
        topic: params?.topic,
        authorId: params?.authorId,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  moderateCommunityPostStatus: (
    id: string,
    body: { status: ContentStatus; reason: string },
  ) =>
    apiFetch<AdminCommunityPost>(`/admin/content/community-posts/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAdminCommunityComments: (params?: {
    q?: string;
    status?: ContentStatus;
    postId?: string;
    authorId?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminCommunityComment[]>(
      `/admin/content/community-comments${toQuery({
        q: params?.q,
        status: params?.status,
        postId: params?.postId,
        authorId: params?.authorId,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  moderateCommunityCommentStatus: (
    id: string,
    body: { status: ContentStatus; reason: string },
  ) =>
    apiFetch<AdminCommunityComment>(`/admin/content/community-comments/${id}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAdminApplications: () => apiFetch<AdminApplication[]>("/admin-applications"),

  reviewAdminApplication: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string },
  ) =>
    apiFetch(`/admin-applications/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listProjectProposals: () => apiFetch<ProjectProposal[]>("/project-proposals"),

  reviewProjectProposal: (
    id: string,
    body: { status: "approved" | "rejected"; note?: string },
  ) =>
    apiFetch(`/project-proposals/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listAuditLog: (limit = 100) => apiFetch<AuditLog[]>(`/audit-log${toQuery({ limit })}`),

  promoteToAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteAdmin: (userId: string) =>
    apiFetch(`/roles/admins/${userId}`, {
      method: "DELETE",
    }),

  promoteToModerator: (userId: string, note?: string) =>
    apiFetch(`/roles/moderators/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteModerator: (userId: string) =>
    apiFetch(`/roles/moderators/${userId}`, {
      method: "DELETE",
    }),

  promoteToHunter: (userId: string, note?: string) =>
    apiFetch(`/roles/hunters/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteHunter: (userId: string) =>
    apiFetch(`/roles/hunters/${userId}`, {
      method: "DELETE",
    }),

  listPrimaryTags: () => apiFetch<Tag[]>("/tags/primary"),
  listSecondaryTags: () => apiFetch<Tag[]>("/tags/secondary"),

  createPrimaryTag: (body: { name: string }) =>
    apiFetch<Tag>("/tags/primary", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  createSecondaryTag: (body: { name: string }) =>
    apiFetch<Tag>("/tags/secondary", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  updatePrimaryTag: (id: string, body: { name: string }) =>
    apiFetch<Tag>(`/tags/primary/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  updateSecondaryTag: (id: string, body: { name: string }) =>
    apiFetch<Tag>(`/tags/secondary/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  broadcastNotification: (body: {
    title: string;
    body: string;
    target: "all" | "hunters" | "users" | "specific";
    userIds?: string[];
  }) =>
    apiFetch<{
      insertedCount: number;
      sentCount: number;
      failureCount: number;
      recipientCount: number;
      skipped: boolean;
    }>("/notifications/broadcast", {
      method: "POST",
      body: JSON.stringify(body),
    }),
};
