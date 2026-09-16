import { describe, expect, it } from "vitest";
import {
  formatConfigValue,
  toMiningConfigHistoryEntry,
} from "./mining-config-history";
import type { AuditLog } from "./server-types-content-governance";

const baseLog: AuditLog = {
  id: "log-1",
  action: "admin.mining.config.update",
  actor: { id: "u1", email: "admin@test.dev", displayName: "Ada" },
  resourceType: "mining_config",
  resourceId: "default",
  description: null,
  metadata: {},
  createdAt: "2026-09-16T10:00:00.000Z",
};

describe("toMiningConfigHistoryEntry", () => {
  it("builds a field-by-field diff from before/after metadata", () => {
    const entry = toMiningConfigHistoryEntry({
      ...baseLog,
      metadata: {
        claimWindowHours: 72,
        enabled: false,
        before: { claimWindowHours: 48, enabled: true },
        after: { claimWindowHours: 72, enabled: false },
      },
    });

    expect(entry.hasDiff).toBe(true);
    expect(entry.actor).toBe("Ada");
    expect(entry.changes).toEqual([
      { field: "claimWindowHours", label: "Claim window (hours)", before: "48", after: "72" },
      { field: "enabled", label: "Mining enabled", before: "On", after: "Off" },
    ]);
  });

  it("falls back to the raw changed fields for older entries", () => {
    const entry = toMiningConfigHistoryEntry({
      ...baseLog,
      metadata: { basePointsPerCycle: 1500, someNewField: "x" },
    });

    expect(entry.hasDiff).toBe(false);
    expect(entry.changes).toEqual([
      { field: "basePointsPerCycle", label: "Base BNP / cycle", before: null, after: "1,500" },
      { field: "someNewField", label: "someNewField", before: null, after: "x" },
    ]);
  });

  it("ignores a half-present diff and never lists before/after as fields", () => {
    const entry = toMiningConfigHistoryEntry({
      ...baseLog,
      metadata: { cycleHours: 12, before: { cycleHours: 24 } },
    });

    expect(entry.hasDiff).toBe(false);
    expect(entry.changes.map((c) => c.field)).toEqual(["cycleHours"]);
  });

  it("uses email, then System, when there is no display name", () => {
    expect(
      toMiningConfigHistoryEntry({
        ...baseLog,
        actor: { id: "u1", email: "admin@test.dev", displayName: null },
      }).actor,
    ).toBe("admin@test.dev");
    expect(toMiningConfigHistoryEntry({ ...baseLog, actor: null }).actor).toBe("System");
  });

  it("handles missing or non-object metadata", () => {
    const entry = toMiningConfigHistoryEntry({
      ...baseLog,
      metadata: null as unknown as Record<string, unknown>,
    });
    expect(entry.changes).toEqual([]);
  });
});

describe("formatConfigValue", () => {
  it("formats the common value types", () => {
    expect(formatConfigValue(true)).toBe("On");
    expect(formatConfigValue(10000)).toBe("10,000");
    expect(formatConfigValue(null)).toBe("—");
    expect(formatConfigValue({ a: 1 })).toBe('{"a":1}');
  });
});
