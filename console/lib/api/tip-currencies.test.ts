import { describe, expect, it } from "vitest";
import type { AdminTipCurrencySettings, AdminTipSettings } from "./server-types-tips-mining";
import { isRetiredTipCurrency, stripRetiredTipCurrencies } from "./tip-currencies";

function currency(code: string): AdminTipCurrencySettings {
  return {
    code,
    name: code,
    symbol: code,
    decimals: 2,
    kind: "points",
    isEnabled: true,
    isActiveTippingCurrency: false,
    feePolicy: null,
    feeVaultBalanceAtomic: "0",
    feeVaultBalance: "0",
  };
}

describe("stripRetiredTipCurrencies", () => {
  it("removes MCR from the currency list", () => {
    const settings: AdminTipSettings = {
      activeCurrencyCode: "BNP",
      currencies: [currency("BNP"), currency("MCR"), currency("BNT")],
    };
    expect(stripRetiredTipCurrencies(settings).currencies.map((row) => row.code)).toEqual([
      "BNP",
      "BNT",
    ]);
  });

  it("clears the active code when the retired currency was active", () => {
    const settings: AdminTipSettings = {
      activeCurrencyCode: "MCR",
      currencies: [currency("MCR"), currency("BNP")],
    };
    const stripped = stripRetiredTipCurrencies(settings);
    expect(stripped.activeCurrencyCode).toBeNull();
    expect(stripped.currencies.map((row) => row.code)).toEqual(["BNP"]);
  });

  it("returns the same object when nothing is retired", () => {
    const settings: AdminTipSettings = {
      activeCurrencyCode: "BNP",
      currencies: [currency("BNP"), currency("BNT")],
    };
    expect(stripRetiredTipCurrencies(settings)).toBe(settings);
  });

  it("matches codes case-insensitively", () => {
    expect(isRetiredTipCurrency("mcr")).toBe(true);
    expect(isRetiredTipCurrency("BNP")).toBe(false);
  });
});
