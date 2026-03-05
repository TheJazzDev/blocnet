import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminSocialCredential,
  AdminSocialCredentialRevealResponse,
  AdminSocialCredentialsResponse,
  ClosedAlphaBulkUpsertResponse,
  ClosedAlphaEmailRecord,
  ClosedAlphaEmailsResponse,
  AdminWalletDepositReprocessResponse,
  AdminWalletHealth,
  AdminWalletKycRecord,
  AdminWalletKycResponse,
  AdminWalletUserStatusResponse,
  AdminWalletUsersResponse,
  AdminWalletWithdrawal,
  AdminWalletWithdrawalsResponse,
  RuntimeFeatureFlagsConfig,
  WalletAssetCode,
  WalletAssetPriceConfig,
  WalletFeeConfig,
  WalletKycStatus,
  WalletRiskLimit,
  WalletRuntimeConfig,
  WalletStatus,
  WalletWithdrawalStatus,
} from "./api";

export const walletApi = {
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
    apiFetch<AdminWalletUserStatusResponse>(`/admin/wallet/users/${userId}/status`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

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

  listSocialCredentials: () =>
    apiFetch<AdminSocialCredentialsResponse>("/admin/settings/social-credentials"),

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
    apiFetch<{ id: string; deleted: true }>(`/admin/settings/social-credentials/${id}`, {
      method: "DELETE",
    }),

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
};
