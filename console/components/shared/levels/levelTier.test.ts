import { describe, expect, it } from "vitest";
import {
  LEVEL_TIERS,
  formatTierRange,
  getLevelColor,
  getLevelTier,
  groupLevelsByTier,
  isHexColor,
} from "./levelTier";

describe("getLevelTier", () => {
  it("maps each level number to its tier of three", () => {
    expect(getLevelTier(1).name).toBe("Iron");
    expect(getLevelTier(3).name).toBe("Iron");
    expect(getLevelTier(4).name).toBe("Jade");
    expect(getLevelTier(6).name).toBe("Jade");
    expect(getLevelTier(7).name).toBe("Amethyst");
    expect(getLevelTier(9).name).toBe("Amethyst");
    expect(getLevelTier(10).name).toBe("Gold");
    expect(getLevelTier(12).name).toBe("Gold");
    expect(getLevelTier(13).name).toBe("Ruby");
    expect(getLevelTier(15).name).toBe("Ruby");
  });

  it("clamps out-of-range and invalid levels to the first/last tier", () => {
    expect(getLevelTier(0).name).toBe("Iron");
    expect(getLevelTier(-4).name).toBe("Iron");
    expect(getLevelTier(Number.NaN).name).toBe("Iron");
    expect(getLevelTier(16).name).toBe("Ruby");
    expect(getLevelTier(999).name).toBe("Ruby");
  });

  it("carries the tier hex colours", () => {
    expect(LEVEL_TIERS.map((t) => t.color)).toEqual([
      "#8A96A8",
      "#2AA876",
      "#8B5CF6",
      "#F0B429",
      "#E23D4A",
    ]);
  });
});

describe("getLevelColor", () => {
  it("prefers the level's own colour when it is a valid hex", () => {
    expect(getLevelColor({ level: 2, color: "#123456" })).toBe("#123456");
    expect(getLevelColor({ level: 2, color: " #abc " })).toBe("#abc");
  });

  it("falls back to the tier colour when colour is null, empty or invalid", () => {
    expect(getLevelColor({ level: 2, color: null })).toBe("#8A96A8");
    expect(getLevelColor({ level: 5, color: "" })).toBe("#2AA876");
    expect(getLevelColor({ level: 8, color: "purple" })).toBe("#8B5CF6");
    expect(getLevelColor({ level: 11 })).toBe("#F0B429");
    expect(getLevelColor({ level: 14, color: "#12345" })).toBe("#E23D4A");
  });
});

describe("isHexColor", () => {
  it("accepts 3 and 6 digit hex and rejects everything else", () => {
    expect(isHexColor("#fff")).toBe(true);
    expect(isHexColor("#FFAA00")).toBe(true);
    expect(isHexColor("fff")).toBe(false);
    expect(isHexColor("#ggg")).toBe(false);
    expect(isHexColor(null)).toBe(false);
    expect(isHexColor(undefined)).toBe(false);
  });
});

describe("formatTierRange", () => {
  it("formats the level range with an en dash", () => {
    expect(formatTierRange(LEVEL_TIERS[1])).toBe("Levels 4–6");
  });
});

describe("groupLevelsByTier", () => {
  it("groups in tier order, sorts within a tier and omits empty tiers", () => {
    const groups = groupLevelsByTier([
      { id: "l14", level: 14, sortOrder: 14 },
      { id: "l2", level: 2, sortOrder: 2 },
      { id: "l1", level: 1, sortOrder: 1 },
      { id: "l5", level: 5, sortOrder: 5 },
    ]);

    expect(groups.map((g) => g.tier.name)).toEqual(["Iron", "Jade", "Ruby"]);
    expect(groups[0].levels.map((l) => l.id)).toEqual(["l1", "l2"]);
    expect(groups[2].levels.map((l) => l.id)).toEqual(["l14"]);
  });

  it("orders by sortOrder before level number and returns nothing for no levels", () => {
    const groups = groupLevelsByTier([
      { id: "a", level: 1, sortOrder: 3 },
      { id: "b", level: 3, sortOrder: 1 },
    ]);
    expect(groups[0].levels.map((l) => l.id)).toEqual(["b", "a"]);
    expect(groupLevelsByTier([])).toEqual([]);
  });
});
