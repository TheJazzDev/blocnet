import type { AdminTipSettings } from "./server-types-tips-mining";

/**
 * Tip currencies that were discarded product-wide (see UX tracker F-07).
 * The dev database still carries a legacy "MCR" row; the console must never
 * show it, even before WS-H removes it from the API and seeds.
 */
export const RETIRED_TIP_CURRENCY_CODES: readonly string[] = ["MCR"];

export function isRetiredTipCurrency(code: string): boolean {
  return RETIRED_TIP_CURRENCY_CODES.includes(code.toUpperCase());
}

/**
 * Drops retired currencies from a tip-settings payload. If the retired
 * currency was the active one, `activeCurrencyCode` becomes null so the
 * selector shows no stale choice and an admin picks a live currency.
 */
export function stripRetiredTipCurrencies(settings: AdminTipSettings): AdminTipSettings {
  const currencies = settings.currencies.filter((row) => !isRetiredTipCurrency(row.code));
  const activeCurrencyCode =
    settings.activeCurrencyCode && isRetiredTipCurrency(settings.activeCurrencyCode)
      ? null
      : settings.activeCurrencyCode;

  if (currencies.length === settings.currencies.length && activeCurrencyCode === settings.activeCurrencyCode) {
    return settings;
  }
  return { ...settings, currencies, activeCurrencyCode };
}
