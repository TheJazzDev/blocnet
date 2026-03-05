import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type TipDirection } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing tip transactions
 */
export function useTipTransactionsQuery(params?: {
  q?: string;
  currencyCode?: string;
  userId?: string;
  direction?: TipDirection;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: queryKeys.tips.transactions(params ?? {}),
    queryFn: () => clientApi.listTipTransactions(params),
    ...queryOptions.standard,
  });
}

/**
 * Query hook for getting tip settings
 */
export function useTipSettingsQuery() {
  return useQuery({
    queryKey: queryKeys.tips.settings(),
    queryFn: () => clientApi.getTipSettings(),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for updating tip currency settings
 */
export function useUpdateTipCurrencyMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      currencyCode,
      data,
    }: {
      currencyCode: string;
      data: Partial<{
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
      }>;
    }) => clientApi.updateTipCurrencySettings(currencyCode, data),

    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tips.settings() });
    },
  });
}

/**
 * Mutation hook for setting active tip currency
 */
export function useSetActiveTipCurrencyMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { currencyCode: string }) =>
      clientApi.setActiveTipCurrency(data),

    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tips.settings() });
    },
  });
}
