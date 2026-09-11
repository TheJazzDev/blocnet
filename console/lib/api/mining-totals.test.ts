import { describe, expect, it } from "vitest";
import { toMiningTotals } from "./mining-totals";

describe("toMiningTotals", () => {
  it("returns null without a payload", () => {
    expect(toMiningTotals(null)).toBeNull();
    expect(toMiningTotals(undefined)).toBeNull();
  });

  it("reads the legacy Mcr fields the API still returns", () => {
    expect(
      toMiningTotals({
        lifetimeMinedMcr: 15044,
        lifetimeClaimedMcr: 14400,
        lifetimeUnclaimedMcr: 644,
        totalMiners: 12,
      }),
    ).toEqual({
      lifetimeMinedBnp: 15044,
      lifetimeClaimedBnp: 14400,
      lifetimeUnclaimedBnp: 644,
      totalMiners: 12,
    });
  });

  it("prefers the Bnp aliases once WS-H ships them", () => {
    expect(
      toMiningTotals({
        lifetimeMinedBnp: 20,
        lifetimeClaimedBnp: 15,
        lifetimeUnclaimedBnp: 5,
        lifetimeMinedMcr: 1,
        lifetimeClaimedMcr: 1,
        lifetimeUnclaimedMcr: 1,
        totalMiners: 3,
      }),
    ).toEqual({
      lifetimeMinedBnp: 20,
      lifetimeClaimedBnp: 15,
      lifetimeUnclaimedBnp: 5,
      totalMiners: 3,
    });
  });

  it("falls back to zero when neither naming is present", () => {
    expect(toMiningTotals({ totalMiners: 0 })).toEqual({
      lifetimeMinedBnp: 0,
      lifetimeClaimedBnp: 0,
      lifetimeUnclaimedBnp: 0,
      totalMiners: 0,
    });
  });
});
