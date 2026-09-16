import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminBindReferralRequest,
  AdminBindReferralResponse,
  AdminBindUserReferralRequest,
  AdminBnpAdjustment,
  AdminBnpAdjustmentRequest,
  AdminBnpAdjustmentsResponse,
  AdminMiningConfig,
  AdminMiningConfigPatch,
  AdminMiningLeaderboardResponse,
  AdminMiningMetrics,
} from "./api";

export const miningApi = {
  getMiningConfig: () => apiFetch<AdminMiningConfig>("/admin/mining/config"),

  updateMiningConfig: (body: AdminMiningConfigPatch) =>
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

  /** F-66. Errors are shown inline by the dialog, so no error toast. */
  createBnpAdjustment: (userId: string, body: AdminBnpAdjustmentRequest) =>
    apiFetch<AdminBnpAdjustment>(`/admin/mining/users/${userId}/adjustments`, {
      method: "POST",
      body: JSON.stringify(body),
      successMessage: "BNP balance adjusted.",
      suppressErrorToast: true,
    }),

  listBnpAdjustments: (
    userId: string,
    params?: { limit?: number; offset?: number },
  ) =>
    apiFetch<AdminBnpAdjustmentsResponse>(
      `/admin/mining/users/${userId}/adjustments${toQuery({
        limit: params?.limit,
        offset: params?.offset,
      })}`,
    ),
};
