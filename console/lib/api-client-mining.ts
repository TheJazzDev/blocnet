import { apiFetch, toQuery } from "./api-client-http";
import type {
  AdminBindReferralRequest,
  AdminBindReferralResponse,
  AdminBindUserReferralRequest,
  AdminMiningConfig,
  AdminMiningLeaderboardResponse,
  AdminMiningMetrics,
} from "./api";

export const miningApi = {
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
