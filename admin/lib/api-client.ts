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

// Track if we're already attempting a refresh to avoid infinite loops
let isRefreshing = false;

export async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(`${PROXY_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (res.status === 401) {
    // Try to refresh the token once, then retry the request
    if (!isRefreshing && typeof window !== "undefined") {
      isRefreshing = true;
      try {
        const refreshRes = await fetch("/api/auth/refresh-token", { method: "POST" });
        if (refreshRes.ok) {
          isRefreshing = false;
          // Retry the original request with the new token
          return apiFetch<T>(path, options);
        }
      } catch {
        // Refresh failed
      }
      isRefreshing = false;
    }

    // If refresh failed or we're already refreshing, redirect to sign-in
    if (typeof window !== "undefined") {
      window.location.href = `/signin?next=${encodeURIComponent(window.location.pathname)}`;
    }
    throw new Error("Unauthorized");
  }

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

export type {
  RolesMatrixResponse,
  AdminMe,
  AdminStats,
  AdminUser,
  AdminUserDetail,
  AdminDeleteUserResponse,
  AdminReactivateUserResponse,
  AdminHardDeleteUserResponse,
  AdminUserStatus,
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
  WalletStatus,
  WalletKycStatus,
  WalletWithdrawalStatus,
  AdminWalletUser,
  AdminWalletUsersResponse,
  AdminWalletWithdrawal,
  AdminWalletWithdrawalsResponse,
  AdminWalletKycRecord,
  AdminWalletKycResponse,
  WalletRiskLimit,
  WalletFeeConfig,
  WalletAssetCode,
  WalletAssetPriceConfig,
  AdminWalletHealth,
  AdminMiningConfig,
  AdminMiningMetrics,
  AdminMiningLeaderboardEntry,
  AdminMiningLeaderboardResponse,
  AdminBindReferralRequest,
  AdminBindReferralResponse,
} from "./api";

import type {
  RolesMatrixResponse,
  AdminMe,
  AdminStats,
  AdminUserDetail,
  AdminDeleteUserResponse,
  AdminReactivateUserResponse,
  AdminHardDeleteUserResponse,
  AdminUserStatus,
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
  WalletStatus,
  WalletKycStatus,
  WalletWithdrawalStatus,
  AdminWalletUsersResponse,
  AdminWalletWithdrawalsResponse,
  AdminWalletWithdrawal,
  AdminWalletKycRecord,
  AdminWalletKycResponse,
  WalletRiskLimit,
  WalletFeeConfig,
  WalletAssetCode,
  WalletAssetPriceConfig,
  AdminWalletHealth,
  AdminMiningConfig,
  AdminMiningMetrics,
  AdminMiningLeaderboardResponse,
  AdminBindReferralRequest,
  AdminBindReferralResponse,
} from "./api";

export const clientApi = {
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

  listWalletUsers: (params?: {
    q?: string;
    walletStatus?: WalletStatus;
    kycStatus?: WalletKycStatus;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminWalletUsersResponse>(
      `/admin/wallet/users${toQuery({
        q: params?.q,
        walletStatus: params?.walletStatus,
        kycStatus: params?.kycStatus,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  getWalletHealth: () => apiFetch<AdminWalletHealth>("/admin/wallet/health"),

  listWalletWithdrawals: (params?: {
    q?: string;
    status?: WalletWithdrawalStatus;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminWalletWithdrawalsResponse>(
      `/admin/wallet/withdrawals${toQuery({
        q: params?.q,
        status: params?.status,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  reviewWalletWithdrawal: (
    id: string,
    body: { status: "approved" | "rejected"; reason: string },
  ) =>
    apiFetch<AdminWalletWithdrawal>(`/admin/wallet/withdrawals/${id}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listWalletKyc: (params?: {
    q?: string;
    status?: WalletKycStatus;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminWalletKycResponse>(
      `/admin/wallet/kyc${toQuery({
        q: params?.q,
        status: params?.status,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  reviewWalletKyc: (
    userId: string,
    body: { status: "approved" | "rejected"; note: string; tier?: string },
  ) =>
    apiFetch<AdminWalletKycRecord>(`/admin/wallet/kyc/${userId}/review`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listWalletRiskLimits: () => apiFetch<WalletRiskLimit[]>("/admin/wallet/settings/risk-limits"),

  updateWalletRiskLimit: (
    tier: string,
    body: Partial<{
      description: string;
      requiresKyc: boolean;
      maxWithdrawalPerTx: string;
      maxWithdrawalPerDay: string;
      maxInternalTransferPerDay: string;
    }>,
  ) =>
    apiFetch<WalletRiskLimit>(`/admin/wallet/settings/risk-limits/${tier}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listWalletFeeConfigs: () => apiFetch<WalletFeeConfig[]>("/admin/wallet/settings/fees"),

  updateWalletFeeConfig: (
    key: string,
    body: Partial<{
      flatFee: string;
      percentFee: string;
      minFee: string;
      maxFee: string | null;
      isActive: boolean;
    }>,
  ) =>
    apiFetch<WalletFeeConfig>(`/admin/wallet/settings/fees/${key}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listWalletAssetPriceConfigs: () =>
    apiFetch<WalletAssetPriceConfig[]>("/admin/wallet/settings/prices"),

  updateWalletAssetPriceConfig: (
    asset: WalletAssetCode,
    body: Partial<{
      providerId: string | null;
      fallbackUsdPrice: string;
      isActive: boolean;
    }>,
  ) =>
    apiFetch<WalletAssetPriceConfig>(`/admin/wallet/settings/prices/${asset}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  getMiningConfig: () => apiFetch<AdminMiningConfig>("/admin/mining/config"),

  updateMiningConfig: (body: Partial<AdminMiningConfig>) =>
    apiFetch<AdminMiningConfig>("/admin/mining/config", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  getMiningMetrics: () => apiFetch<AdminMiningMetrics>("/admin/mining/metrics"),

  getMiningLeaderboard: (params?: { q?: string; limit?: number; offset?: number }) =>
    apiFetch<AdminMiningLeaderboardResponse>(
      `/admin/mining/leaderboard${toQuery({
        q: params?.q,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  adminBindReferral: (body: AdminBindReferralRequest) =>
    apiFetch<AdminBindReferralResponse>("/admin/referrals/bind", {
      method: "POST",
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
      skipReason?: string | null;
    }>("/notifications/broadcast", {
      method: "POST",
      body: JSON.stringify(body),
    }),
};
