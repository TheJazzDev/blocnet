import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminComment,
  AdminCommunityComment,
  AdminCommunityPost,
  AdminProject,
  AdminUpdate,
  CommunityTopic,
  ContentStatus,
  ProjectStatus,
  UpdateStatus,
} from "./api";

export const contentApi = {
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

  moderateProjectStatus: (
    id: string,
    body: { status: ProjectStatus; reason: string },
  ) =>
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

  moderateUpdateStatus: (
    id: string,
    body: { status: UpdateStatus; reason: string },
  ) =>
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

  moderateCommentStatus: (
    id: string,
    body: { status: ContentStatus; reason: string },
  ) =>
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
};
