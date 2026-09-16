import type { AuditLog } from "./server-types-content-governance";

/** Audit action MiningAdminService writes on every config PATCH. */
export const MINING_CONFIG_UPDATE_ACTION = "admin.mining.config.update";

const FIELD_LABELS: Record<string, string> = {
  enabled: "Mining enabled",
  referralsEnabled: "Referrals enabled",
  cycleHours: "Cycle hours",
  basePointsPerCycle: "Base BNP / cycle",
  perActiveReferralBoostBps: "Boost per active referral (bps)",
  maxBoostBps: "Max boost (bps)",
  activeReferralWindowHours: "Active referral window (hours)",
  referralBindWindowHours: "Referral bind window (hours)",
  claimWindowHours: "Claim window (hours)",
};

/** Keys in the audit metadata that describe the diff, not a changed field. */
const DIFF_KEYS = new Set(["before", "after"]);

export type MiningConfigFieldChange = {
  field: string;
  label: string;
  /** Null when the entry only recorded the new value. */
  before: string | null;
  after: string;
};

export type MiningConfigHistoryEntry = {
  id: string;
  createdAt: string;
  actor: string;
  /** True when the audit entry carried a before/after snapshot. */
  hasDiff: boolean;
  changes: MiningConfigFieldChange[];
};

export function miningFieldLabel(field: string): string {
  return FIELD_LABELS[field] ?? field;
}

export function formatConfigValue(value: unknown): string {
  if (value === null || value === undefined) return "—";
  if (typeof value === "boolean") return value ? "On" : "Off";
  if (typeof value === "number") return value.toLocaleString("en-US");
  if (typeof value === "string") return value;
  return JSON.stringify(value);
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function actorName(actor: AuditLog["actor"]): string {
  return actor?.displayName?.trim() || actor?.email || "System";
}

function diffChanges(
  before: Record<string, unknown>,
  after: Record<string, unknown>,
): MiningConfigFieldChange[] {
  return Object.keys(after).map((field) => ({
    field,
    label: miningFieldLabel(field),
    before: field in before ? formatConfigValue(before[field]) : null,
    after: formatConfigValue(after[field]),
  }));
}

function rawChanges(metadata: Record<string, unknown>): MiningConfigFieldChange[] {
  return Object.entries(metadata)
    .filter(([field]) => !DIFF_KEYS.has(field))
    .map(([field, value]) => ({
      field,
      label: miningFieldLabel(field),
      before: null,
      after: formatConfigValue(value),
    }));
}

/**
 * One audit row -> a history entry. Uses the before/after snapshot when the
 * backend recorded one (F-65 onward); older rows only hold the patch.
 */
export function toMiningConfigHistoryEntry(log: AuditLog): MiningConfigHistoryEntry {
  const metadata = asRecord(log.metadata) ?? {};
  const before = asRecord(metadata.before);
  const after = asRecord(metadata.after);
  const hasDiff = Boolean(before && after);

  return {
    id: log.id,
    createdAt: log.createdAt,
    actor: actorName(log.actor),
    hasDiff,
    changes: before && after ? diffChanges(before, after) : rawChanges(metadata),
  };
}
