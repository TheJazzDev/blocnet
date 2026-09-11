import type { UserLevel } from "@/lib/api/server-types-levels";

export type LevelRequirementKey =
  | "requiredBnp"
  | "requiredComments"
  | "requiredDaysActive"
  | "requiredQuests"
  | "requiredUpdates"
  | "requiredProjects";

export interface LevelRequirementField {
  key: LevelRequirementKey;
  label: string;
  format: (level: UserLevel) => string;
}

export function formatBnp(value: string): string {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed.toLocaleString() : "0";
}

export const LEVEL_REQUIREMENT_FIELDS: readonly LevelRequirementField[] = [
  { key: "requiredBnp", label: "Required BNP", format: (l) => formatBnp(l.requiredBnp) },
  {
    key: "requiredComments",
    label: "Required Comments",
    format: (l) => l.requiredComments.toLocaleString(),
  },
  {
    key: "requiredDaysActive",
    label: "Required Days Active",
    format: (l) => `${l.requiredDaysActive} day${l.requiredDaysActive === 1 ? "" : "s"}`,
  },
  { key: "requiredQuests", label: "Required Quests", format: (l) => String(l.requiredQuests) },
  { key: "requiredUpdates", label: "Required Updates", format: (l) => String(l.requiredUpdates) },
  {
    key: "requiredProjects",
    label: "Required Projects",
    format: (l) => String(l.requiredProjects),
  },
];
