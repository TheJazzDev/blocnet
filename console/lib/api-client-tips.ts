import { apiFetch, toQuery } from "./api-client-http";
import type { AdminTipSettings, AdminTipTransactionsResponse, TipDirection } from "./api";

export const tipsApi = {
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
    apiFetch<AdminTipSettings>(`/admin/tips/settings/currencies/${currencyCode}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

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
};
