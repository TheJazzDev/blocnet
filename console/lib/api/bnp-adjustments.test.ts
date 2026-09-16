import { describe, expect, it } from "vitest";
import {
  currentBnpBalances,
  formatAtomicBnp,
  parseAdjustmentAmount,
  previewAdjustment,
  signedAmount,
  validateAdjustmentForm,
} from "./bnp-adjustments";
import type { AdminUserDetail } from "./server-types-admin-users";

function user(claimed: string, walletAtomic?: string): AdminUserDetail {
  return {
    mining: { claimedTotalPoints: claimed },
    tips: {
      accounts:
        walletAtomic === undefined
          ? []
          : [{ accountType: "user", currencyCode: "BNP", balanceAtomic: walletAtomic }],
    },
  } as unknown as AdminUserDetail;
}

const before = { claimedPoints: BigInt(100), walletAtomic: BigInt(30500) };
const reason = "Refund for a failed claim";

describe("currentBnpBalances", () => {
  it("reads claimed points and the BNP wallet", () => {
    expect(currentBnpBalances(user("100", "30500"))).toEqual(before);
  });

  it("assumes a new wallet is seeded from claimed points", () => {
    expect(currentBnpBalances(user("42"))).toEqual({
      claimedPoints: BigInt(42),
      walletAtomic: BigInt(42000),
    });
  });
});

describe("parseAdjustmentAmount", () => {
  it.each([
    ["250", 250],
    [" 1 ", 1],
    ["1000000", 1_000_000],
    ["0", null],
    ["-5", null],
    ["1.5", null],
    ["1000001", null],
    ["abc", null],
    ["", null],
  ])("parses %j as %j", (raw, expected) => {
    expect(parseAdjustmentAmount(raw)).toBe(expected);
  });
});

describe("previewAdjustment", () => {
  it("moves both balances by the signed amount", () => {
    expect(previewAdjustment(before, signedAmount("remove", 30))).toEqual({
      claimedPoints: BigInt(70),
      walletAtomic: BigInt(500),
    });
    expect(previewAdjustment(before, signedAmount("add", 5))).toEqual({
      claimedPoints: BigInt(105),
      walletAtomic: BigInt(35500),
    });
  });
});

describe("validateAdjustmentForm", () => {
  it("accepts a valid removal", () => {
    expect(
      validateAdjustmentForm({ direction: "remove", amountRaw: "30", reason, before }),
    ).toBeNull();
  });

  it("rejects a removal below zero", () => {
    expect(
      validateAdjustmentForm({ direction: "remove", amountRaw: "31", reason, before }),
    ).toMatch(/below zero/);
  });

  it("requires a 10-500 character reason after trimming", () => {
    expect(
      validateAdjustmentForm({ direction: "add", amountRaw: "5", reason: "  long enough  ", before }),
    ).toBeNull();
    expect(
      validateAdjustmentForm({ direction: "add", amountRaw: "5", reason: "   short   ", before }),
    ).toMatch(/Reason/);
    expect(
      validateAdjustmentForm({ direction: "add", amountRaw: "5", reason: "x".repeat(501), before }),
    ).toMatch(/Reason/);
  });

  it("rejects a bad amount", () => {
    expect(
      validateAdjustmentForm({ direction: "add", amountRaw: "0", reason, before }),
    ).toMatch(/whole number/);
  });
});

describe("formatAtomicBnp", () => {
  it("formats with up to three decimals", () => {
    expect(formatAtomicBnp(BigInt(30500))).toBe("30.5");
    expect(formatAtomicBnp(BigInt(1234567000))).toBe("1,234,567");
    expect(formatAtomicBnp(-BigInt(1001))).toBe("-1.001");
  });
});
