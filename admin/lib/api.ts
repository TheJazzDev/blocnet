import { cookies } from "next/headers";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

async function getToken(): Promise<string | null> {
  const store = await cookies();
  return store.get("admin_token")?.value ?? null;
}

function toQuery(params: Record<string, string | number | undefined | null>): string {
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    query.set(key, String(value));
  }
  const encoded = query.toString();
  return encoded ? `?${encoded}` : "";
}

async function apiFetch<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = await getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
    cache: "no-store",
  });

  if (!res.ok) {
    const text = await res.text().catch(() => res.statusText);
    throw new Error(`API ${res.status}: ${text}`);
  }

  return res.json() as Promise<T>;
}

export interface AdminMe {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  roles: string[];
}

export interface AdminStats {
  totalProjects: number;
  totalUsers: number;
  pendingAdminApps: number;
  totalUpdates: number;
  totalComments: number;
  activeHunters: number;
  pendingProposals: number;
  totalTags: number;
  usersWithPushEnabled: number;
}

export interface AdminUser {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  roles: string[];
  projectsAssigned: number;
  updatesPosted: number;
  createdAt: string;
}

export interface AdminUsersResponse {
  data: AdminUser[];
  total: number;
  limit: number;
  offset: number;
}

export type ProjectStatus = "active" | "paused" | "hidden" | "archived";
export type UpdateStatus = "published" | "hidden" | "archived";
export type ContentStatus = "active" | "hidden" | "archived";
export type CommunityTopic = "general" | "market_talk" | "introductions";

export interface ActorSummary {
  id: string;
  email: string;
  displayName: string | null;
}

export interface ModerationInfo {
  moderatedBy: ActorSummary | null;
  moderatedAt: string | null;
  moderationReason: string | null;
}

export interface AdminProject {
  id: string;
  name: string;
  symbol: string | null;
  status: ProjectStatus;
  description: string;
  slug: string;
  primaryTag: { id: string; name: string } | null;
  owner: ActorSummary | null;
  moderation: ModerationInfo;
  counts: {
    updates: number;
    followers: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AdminUpdate {
  id: string;
  projectId: string;
  authorId: string;
  title: string;
  contentMd: string;
  urgency: "high" | "medium" | "low";
  status: UpdateStatus;
  author: ActorSummary;
  project: {
    id: string;
    name: string;
    slug: string;
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminComment {
  id: string;
  updateId: string;
  authorId: string;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  update: {
    id: string;
    title: string;
    project: {
      id: string;
      name: string;
    };
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminCommunityPost {
  id: string;
  authorId: string;
  topic: CommunityTopic;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  moderation: ModerationInfo;
  counts: {
    comments: number;
    reactions: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AdminCommunityComment {
  id: string;
  postId: string;
  authorId: string;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  post: {
    id: string;
    topic: CommunityTopic;
    preview: string;
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminApplication {
  id: string;
  userId: string;
  user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  targetRole: "admin" | "hunter";
  reason: string;
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface ProjectProposal {
  id: string;
  name: string;
  symbol: string | null;
  description: string;
  reason: string | null;
  primaryTag: { id: string; name: string } | null;
  applicant: {
    id: string;
    email: string;
    displayName: string | null;
  };
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface AuditLog {
  id: string;
  action: string;
  actor: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  resourceType: string;
  resourceId: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export interface Tag {
  id: string;
  name: string;
  slug: string;
  createdAt: string;
  updatedAt: string;
}

export type WalletStatus = "provisioning" | "ready" | "error" | "disabled";
export type WalletKycStatus = "not_submitted" | "pending" | "approved" | "rejected";
export type WalletWithdrawalStatus =
  | "requested"
  | "pending_review"
  | "approved"
  | "rejected"
  | "broadcasting"
  | "confirmed"
  | "failed"
  | "reverted";

export interface AdminWalletUser {
  id: string;
  email: string;
  displayName: string | null;
  username: string | null;
  roles: string[];
  createdAt: string;
  wallet: {
    id: string;
    status: WalletStatus;
    address: string | null;
    providerWalletId: string | null;
    chainId: number;
  } | null;
  balances: {
    available: string;
    pending: string;
    locked: string;
  } | null;
  kyc: {
    status: WalletKycStatus;
    tier: string;
    submittedAt: string | null;
    reviewedAt: string | null;
  } | null;
}

export interface AdminWalletUsersResponse {
  data: AdminWalletUser[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminWalletWithdrawal {
  id: string;
  status: WalletWithdrawalStatus;
  toAddress: string;
  amount: string;
  feeAmount: string;
  netAmount: string;
  reason: string;
  rejectReason: string | null;
  failureReason: string | null;
  broadcastTxHash: string | null;
  confirmations: number;
  requester: {
    id: string;
    email: string;
    displayName: string | null;
  };
  reviewer: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  requestedAt: string;
  reviewedAt: string | null;
  confirmedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminWalletWithdrawalsResponse {
  data: AdminWalletWithdrawal[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminWalletKycRecord {
  id: string;
  userId: string;
  user: {
    id: string;
    email: string;
    displayName: string | null;
  };
  status: WalletKycStatus;
  tier: string;
  country: string | null;
  fullName: string | null;
  documentType: string | null;
  documentNumberLast4: string | null;
  documentUrl: string | null;
  submittedAt: string | null;
  reviewedAt: string | null;
  reviewNote: string | null;
  reviewer: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminWalletKycResponse {
  data: AdminWalletKycRecord[];
  total: number;
  limit: number;
  offset: number;
}

export interface WalletRiskLimit {
  id: string;
  tier: string;
  description: string | null;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
  createdAt: string;
  updatedAt: string;
}

export interface WalletFeeConfig {
  id: string;
  key: string;
  flatFee: string;
  percentFee: string;
  minFee: string;
  maxFee: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export const api = {
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
};
