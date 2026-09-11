export const BNP_CURRENCY_CODE = 'BNP';
export const BNP_DECIMALS = 3;
export const FEE_VAULT_OWNER_REF = 'FEE_VAULT';

/**
 * Tip currency codes that have been retired (F-07). They must never be
 * created, enabled, activated or surfaced by the admin settings surface.
 *
 * - `MCR` ("Mine Credits") was the pre-BNP mining unit. Users mine BNP now.
 */
export const RETIRED_TIP_CURRENCY_CODES: readonly string[] = ['MCR'];

export function isRetiredTipCurrencyCode(code: string): boolean {
  return RETIRED_TIP_CURRENCY_CODES.includes(code.trim().toUpperCase());
}
