import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminDeleteUserResponse,
  AdminHardDeleteUserResponse,
  AdminMe,
  AdminReactivateUserResponse,
  AdminStats,
  AdminUserDetail,
  AdminUserStatus,
  AdminUsersResponse,
  RolesMatrixResponse,
} from "./api";

export const usersApi = {
  getMe: () => apiFetch<AdminMe>("/me"),

  getRolesMatrix: () => apiFetch<RolesMatrixResponse>("/roles/matrix"),

  getStats: () => apiFetch<AdminStats>("/admin/users/stats"),

  listUsers: (params?: {
    limit?: number;
    offset?: number;
    role?: string;
    q?: string;
    status?: AdminUserStatus | "all";
  }) =>
    apiFetch<AdminUsersResponse>(
      `/admin/users${toQuery({
        limit: params?.limit,
        offset: params?.offset,
        role: params?.role,
        q: params?.q,
        status: params?.status,
      })}`,
    ),

  getUser: (id: string) => apiFetch<AdminUserDetail>(`/admin/users/${id}`),

  updateUser: (
    id: string,
    body: Partial<{
      displayName: string | null;
      username: string | null;
      avatarUrl: string | null;
      bio: string | null;
    }>,
  ) =>
    apiFetch<AdminUserDetail>(`/admin/users/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  deleteUser: (id: string, body?: { reason?: string }) =>
    apiFetch<AdminDeleteUserResponse>(`/admin/users/${id}`, {
      method: "DELETE",
      body: JSON.stringify(body ?? {}),
    }),

  reactivateUser: (id: string, body?: { reason?: string }) =>
    apiFetch<AdminReactivateUserResponse>(`/admin/users/${id}/reactivate`, {
      method: "PATCH",
      body: JSON.stringify(body ?? {}),
    }),

  hardDeleteUser: (id: string, body?: { reason?: string }) =>
    apiFetch<AdminHardDeleteUserResponse>(`/admin/users/${id}/hard`, {
      method: "DELETE",
      body: JSON.stringify(body ?? {}),
    }),
};
