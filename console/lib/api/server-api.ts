import { apiFetch, toQuery } from './server-core';
import type * as ApiTypes from './server-types';

type ActorSummary = ApiTypes.ActorSummary;
type AdminApplication = ApiTypes.AdminApplication;
type AdminBadgeSummary = ApiTypes.AdminBadgeSummary;
type AdminBindReferralRequest = ApiTypes.AdminBindReferralRequest;
type AdminBindReferralResponse = ApiTypes.AdminBindReferralResponse;
type AdminBindUserReferralRequest = ApiTypes.AdminBindUserReferralRequest;
type AdminComment = ApiTypes.AdminComment;
type AdminCommunityComment = ApiTypes.AdminCommunityComment;
type AdminCommunityPost = ApiTypes.AdminCommunityPost;
type AdminDeleteUserResponse = ApiTypes.AdminDeleteUserResponse;
type AdminGovernanceRole = ApiTypes.AdminGovernanceRole;
type AdminHardDeleteUserResponse = ApiTypes.AdminHardDeleteUserResponse;
type AdminMe = ApiTypes.AdminMe;
type AdminMiningConfig = ApiTypes.AdminMiningConfig;
type AdminMiningLeaderboardEntry = ApiTypes.AdminMiningLeaderboardEntry;
type AdminMiningLeaderboardResponse = ApiTypes.AdminMiningLeaderboardResponse;
type AdminMiningMetrics = ApiTypes.AdminMiningMetrics;
type AdminProject = ApiTypes.AdminProject;
type AdminReactivateUserResponse = ApiTypes.AdminReactivateUserResponse;
type AdminSocialCredential = ApiTypes.AdminSocialCredential;
type AdminSocialCredentialRevealResponse = ApiTypes.AdminSocialCredentialRevealResponse;
type AdminSocialCredentialsResponse = ApiTypes.AdminSocialCredentialsResponse;
type AdminStats = ApiTypes.AdminStats;
type AdminTipCurrencySettings = ApiTypes.AdminTipCurrencySettings;
type AdminTipSettings = ApiTypes.AdminTipSettings;
type AdminTipTransaction = ApiTypes.AdminTipTransaction;
type AdminTipTransactionsResponse = ApiTypes.AdminTipTransactionsResponse;
type AdminTwoFactorDisableResponse = ApiTypes.AdminTwoFactorDisableResponse;
type AdminTwoFactorEnrollmentConfirmResponse = ApiTypes.AdminTwoFactorEnrollmentConfirmResponse;
type AdminTwoFactorEnrollmentStartResponse = ApiTypes.AdminTwoFactorEnrollmentStartResponse;
type AdminTwoFactorLoginVerifyResponse = ApiTypes.AdminTwoFactorLoginVerifyResponse;
type AdminTwoFactorPolicy = ApiTypes.AdminTwoFactorPolicy;
type AdminTwoFactorPreflight = ApiTypes.AdminTwoFactorPreflight;
type AdminTwoFactorRecoveryCodesResponse = ApiTypes.AdminTwoFactorRecoveryCodesResponse;
type AdminTwoFactorSessionValidationResponse = ApiTypes.AdminTwoFactorSessionValidationResponse;
type AdminUpdate = ApiTypes.AdminUpdate;
type AdminUser = ApiTypes.AdminUser;
type AdminUserDetail = ApiTypes.AdminUserDetail;
type AdminUserStatus = ApiTypes.AdminUserStatus;
type AdminUsersResponse = ApiTypes.AdminUsersResponse;
type AdminWalletDepositReprocessNetworkResult = ApiTypes.AdminWalletDepositReprocessNetworkResult;
type AdminWalletDepositReprocessResponse = ApiTypes.AdminWalletDepositReprocessResponse;
type AdminWalletHealth = ApiTypes.AdminWalletHealth;
type AdminWalletKycRecord = ApiTypes.AdminWalletKycRecord;
type AdminWalletKycResponse = ApiTypes.AdminWalletKycResponse;
type AdminWalletUser = ApiTypes.AdminWalletUser;
type AdminWalletUserStatusResponse = ApiTypes.AdminWalletUserStatusResponse;
type AdminWalletUsersResponse = ApiTypes.AdminWalletUsersResponse;
type AdminWalletWithdrawal = ApiTypes.AdminWalletWithdrawal;
type AdminWalletWithdrawalsResponse = ApiTypes.AdminWalletWithdrawalsResponse;
type AuditLog = ApiTypes.AuditLog;
type CommunityTopic = ApiTypes.CommunityTopic;
type ContentStatus = ApiTypes.ContentStatus;
type GovernanceRoleDefinition = ApiTypes.GovernanceRoleDefinition;
type ModerationInfo = ApiTypes.ModerationInfo;
type OpsEvent = ApiTypes.OpsEvent;
type OpsEventProvider = ApiTypes.OpsEventProvider;
type OpsEventSource = ApiTypes.OpsEventSource;
type OpsEventStatus = ApiTypes.OpsEventStatus;
type ProjectProposal = ApiTypes.ProjectProposal;
type ProjectStatus = ApiTypes.ProjectStatus;
type RoleCapability = ApiTypes.RoleCapability;
type RoleCapabilitySection = ApiTypes.RoleCapabilitySection;
type RoleMatrixSection = ApiTypes.RoleMatrixSection;
type RolesMatrixResponse = ApiTypes.RolesMatrixResponse;
type RuntimeFeatureFlagsConfig = ApiTypes.RuntimeFeatureFlagsConfig;
type ClosedAlphaEmailRecord = ApiTypes.ClosedAlphaEmailRecord;
type ClosedAlphaEmailsResponse = ApiTypes.ClosedAlphaEmailsResponse;
type ClosedAlphaBulkUpsertResponse = ApiTypes.ClosedAlphaBulkUpsertResponse;
type SpaceRoleDefinition = ApiTypes.SpaceRoleDefinition;
type Tag = ApiTypes.Tag;
type TipCurrencyKind = ApiTypes.TipCurrencyKind;
type TipDirection = ApiTypes.TipDirection;
type TipFeePolicy = ApiTypes.TipFeePolicy;
type TipUserPreview = ApiTypes.TipUserPreview;
type UpdateStatus = ApiTypes.UpdateStatus;
type WalletAssetCode = ApiTypes.WalletAssetCode;
type WalletAssetPriceConfig = ApiTypes.WalletAssetPriceConfig;
type WalletFeeConfig = ApiTypes.WalletFeeConfig;
type WalletKycStatus = ApiTypes.WalletKycStatus;
type WalletRiskLimit = ApiTypes.WalletRiskLimit;
type WalletRuntimeConfig = ApiTypes.WalletRuntimeConfig;
type WalletStatus = ApiTypes.WalletStatus;
type WalletWithdrawalStatus = ApiTypes.WalletWithdrawalStatus;

export const api = {
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
    apiFetch<AdminCommunityPost>(
      `/admin/content/community-posts/${id}/status`,
      {
        method: "PATCH",
        body: JSON.stringify(body),
      },
    ),

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
    apiFetch<AdminCommunityComment>(
      `/admin/content/community-comments/${id}/status`,
      {
        method: "PATCH",
        body: JSON.stringify(body),
      },
    ),

  listAdminApplications: () =>
    apiFetch<AdminApplication[]>("/admin-applications"),

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

  listAuditLog: (limit = 100) =>
    apiFetch<AuditLog[]>(`/audit-log${toQuery({ limit })}`),

  listOpsEvents: (params?: {
    q?: string;
    source?: "all" | OpsEventSource;
    provider?: "all" | OpsEventProvider;
    status?: "all" | OpsEventStatus;
    from?: string;
    to?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<OpsEvent[]>(
      `/audit-log/ops-events${toQuery({
        q: params?.q,
        source: params?.source,
        provider: params?.provider,
        status: params?.status,
        from: params?.from,
        to: params?.to,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  promoteToAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteAdmin: (userId: string) =>
    apiFetch(`/roles/admins/${userId}`, {
      method: "DELETE",
    }),

  promoteToOwner: (userId: string, note?: string) =>
    apiFetch(`/roles/owners/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteOwner: (userId: string) =>
    apiFetch(`/roles/owners/${userId}`, {
      method: "DELETE",
    }),

  promoteToCommunityAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/community-admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCommunityAdmin: (userId: string) =>
    apiFetch(`/roles/community-admins/${userId}`, {
      method: "DELETE",
    }),

  promoteToCommunityModerator: (userId: string, note?: string) =>
    apiFetch(`/roles/community-moderators/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCommunityModerator: (userId: string) =>
    apiFetch(`/roles/community-moderators/${userId}`, {
      method: "DELETE",
    }),

  // Legacy moderator aliases retained for overlap rollout.
  promoteToModerator: (userId: string, note?: string) =>
    apiFetch(`/roles/moderators/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteModerator: (userId: string) =>
    apiFetch(`/roles/moderators/${userId}`, {
      method: "DELETE",
    }),

  promoteToCoreTeam: (userId: string, note?: string) =>
    apiFetch(`/roles/core-teams/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCoreTeam: (userId: string) =>
    apiFetch(`/roles/core-teams/${userId}`, {
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

  updateWalletUserStatus: (userId: string, body: { disabled: boolean }) =>
    apiFetch<AdminWalletUserStatusResponse>(
      `/admin/wallet/users/${userId}/status`,
      {
        method: "PATCH",
        body: JSON.stringify(body),
      },
    ),

  reprocessWalletDepositByTxHash: (body: {
    txHash: string;
    chainEnvironment?: "testnet" | "mainnet";
    asset?: WalletAssetCode;
  }) =>
    apiFetch<AdminWalletDepositReprocessResponse>(
      "/admin/wallet/deposits/reprocess",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  getWalletHealth: () => apiFetch<AdminWalletHealth>("/admin/wallet/health"),

  getWalletRuntimeConfig: () =>
    apiFetch<WalletRuntimeConfig>("/admin/wallet/settings/runtime"),

  updateWalletRuntimeConfig: (
    body: Partial<{
      walletEnabled: boolean;
      depositsEnabled: boolean;
      withdrawalsEnabled: boolean;
      depositRealtimeEnabled: boolean;
      bscRpcUrl: string | null;
      bscRpcWsUrl: string | null;
      depositConfirmations: number;
      withdrawalConfirmations: number;
      walletAssetBntEnabled: boolean;
      walletAssetBnbEnabled: boolean;
      walletAssetUsdtEnabled: boolean;
      withdrawalEnabledAssets: WalletAssetCode[];
    }>,
  ) =>
    apiFetch<WalletRuntimeConfig>("/admin/wallet/settings/runtime", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  getRuntimeFeatureFlags: () =>
    apiFetch<RuntimeFeatureFlagsConfig>("/admin/settings/runtime-features"),

  updateRuntimeFeatureFlags: (
    body: Partial<{
      closedAlphaEnabled: boolean;
      alphaRadarEnabled: boolean;
      followPrefsEnabled: boolean;
      weeklyDigestEnabled: boolean;
      miningEnabled: boolean;
      referralsEnabled: boolean;
    }>,
  ) =>
    apiFetch<RuntimeFeatureFlagsConfig>("/admin/settings/runtime-features", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listClosedAlphaEmails: (params?: {
    q?: string;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<ClosedAlphaEmailsResponse>(
      `/admin/settings/closed-alpha/emails${toQuery({
        q: params?.q,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  createClosedAlphaEmail: (body: {
    email: string;
    note?: string;
    isActive?: boolean;
  }) =>
    apiFetch<ClosedAlphaEmailRecord>("/admin/settings/closed-alpha/emails", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  createClosedAlphaEmailsBulk: (body: {
    emails: string[];
    note?: string;
    isActive?: boolean;
  }) =>
    apiFetch<ClosedAlphaBulkUpsertResponse>(
      "/admin/settings/closed-alpha/emails/bulk",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  updateClosedAlphaEmailStatus: (id: string, body: { isActive: boolean }) =>
    apiFetch<ClosedAlphaEmailRecord>(`/admin/settings/closed-alpha/emails/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  deleteClosedAlphaEmail: (id: string) =>
    apiFetch<{ id: string; deleted: true }>(
      `/admin/settings/closed-alpha/emails/${id}`,
      {
        method: "DELETE",
      },
    ),

  getAdminTwoFactorPreflight: () =>
    apiFetch<AdminTwoFactorPreflight>("/admin/security/2fa/preflight"),

  getAdminTwoFactorPolicy: () =>
    apiFetch<AdminTwoFactorPolicy>("/admin/security/2fa/policy"),

  updateAdminTwoFactorPolicy: (body: { require2faForAdminPanel: boolean }) =>
    apiFetch<AdminTwoFactorPolicy>("/admin/security/2fa/policy", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  startAdminTwoFactorEnrollment: () =>
    apiFetch<AdminTwoFactorEnrollmentStartResponse>(
      "/admin/security/2fa/enrollment/start",
      {
        method: "POST",
      },
    ),

  confirmAdminTwoFactorEnrollment: (body: { code: string }) =>
    apiFetch<AdminTwoFactorEnrollmentConfirmResponse>(
      "/admin/security/2fa/enrollment/confirm",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  regenerateAdminTwoFactorRecoveryCodes: (body: {
    code?: string;
    recoveryCode?: string;
  }) =>
    apiFetch<AdminTwoFactorRecoveryCodesResponse>(
      "/admin/security/2fa/recovery/regenerate",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  disableAdminTwoFactor: (body: { code?: string; recoveryCode?: string }) =>
    apiFetch<AdminTwoFactorDisableResponse>("/admin/security/2fa/disable", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  verifyAdminTwoFactorLogin: (body: { code?: string; recoveryCode?: string }) =>
    apiFetch<AdminTwoFactorLoginVerifyResponse>(
      "/admin/security/2fa/login/verify",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  validateAdminTwoFactorSession: (sessionToken?: string) =>
    apiFetch<AdminTwoFactorSessionValidationResponse>(
      "/admin/security/2fa/session/validate",
      {
        method: "POST",
        body: JSON.stringify({ sessionToken }),
      },
    ),

  listSocialCredentials: () =>
    apiFetch<AdminSocialCredentialsResponse>(
      "/admin/settings/social-credentials",
    ),

  revealSocialCredentialPassword: (id: string) =>
    apiFetch<AdminSocialCredentialRevealResponse>(
      `/admin/settings/social-credentials/${id}/reveal`,
    ),

  createSocialCredential: (body: {
    provider: string;
    accountLabel?: string;
    username?: string;
    password: string;
    notes?: string;
  }) =>
    apiFetch<AdminSocialCredential>("/admin/settings/social-credentials", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  updateSocialCredential: (
    id: string,
    body: Partial<{
      provider: string;
      accountLabel: string;
      username: string;
      password: string;
      notes: string;
    }>,
  ) =>
    apiFetch<AdminSocialCredential>(`/admin/settings/social-credentials/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  deleteSocialCredential: (id: string) =>
    apiFetch<{ id: string; deleted: true }>(
      `/admin/settings/social-credentials/${id}`,
      {
        method: "DELETE",
      },
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

  listWalletRiskLimits: () =>
    apiFetch<WalletRiskLimit[]>("/admin/wallet/settings/risk-limits"),

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

  listWalletFeeConfigs: () =>
    apiFetch<WalletFeeConfig[]>("/admin/wallet/settings/fees"),

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

  getTipSettings: () => apiFetch<AdminTipSettings>("/admin/tips/settings"),

  updateTipCurrencySettings: (
    currencyCode: string,
    body: Partial<{
      name: string;
      symbol: string;
      isEnabled: boolean;
      feeBps: number;
      minTip: string;
      maxTip: string | null;
      minFee: string;
      maxFee: string | null;
      senderPaysFee: boolean;
      policyActive: boolean;
    }>,
  ) =>
    apiFetch<AdminTipSettings>(
      `/admin/tips/settings/currencies/${currencyCode}`,
      {
        method: "PATCH",
        body: JSON.stringify(body),
      },
    ),

  setActiveTipCurrency: (body: { currencyCode: string }) =>
    apiFetch<AdminTipSettings>("/admin/tips/settings/active-currency", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  listTipTransactions: (params?: {
    q?: string;
    currencyCode?: string;
    userId?: string;
    direction?: TipDirection;
    limit?: number;
    offset?: number;
  }) =>
    apiFetch<AdminTipTransactionsResponse>(
      `/admin/tips/transactions${toQuery({
        q: params?.q,
        currencyCode: params?.currencyCode,
        userId: params?.userId,
        direction: params?.direction,
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),

  getMiningConfig: () => apiFetch<AdminMiningConfig>("/admin/mining/config"),

  updateMiningConfig: (body: Partial<AdminMiningConfig>) =>
    apiFetch<AdminMiningConfig>("/admin/mining/config", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  getMiningMetrics: () => apiFetch<AdminMiningMetrics>("/admin/mining/metrics"),

  getMiningLeaderboard: (params?: {
    q?: string;
    limit?: number;
    offset?: number;
  }) =>
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

  adminBindReferralForUser: (userId: string, body: AdminBindUserReferralRequest) =>
    apiFetch<AdminBindReferralResponse>(`/admin/users/${userId}/referrals/bind`, {
      method: "POST",
      body: JSON.stringify(body),
    }),
};
