"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminMiningConfig, AdminMiningConfigFields } from "@/lib/api-client";
import { effectiveMiningFlags } from "@/lib/api/mining-config";
import { MiningConfigActions } from "./MiningConfigActions";
import { MiningFlagField } from "./MiningFlagField";
import { MiningNumberField } from "./MiningNumberField";
import { MiningRuntimeFlagsNotice } from "./MiningRuntimeFlagsNotice";

type NumericField = {
  [K in keyof AdminMiningConfigFields]: AdminMiningConfigFields[K] extends number ? K : never;
}[keyof AdminMiningConfigFields];

const NUMBER_FIELDS: Array<{ key: NumericField; label: string; hint?: string }> = [
  { key: "cycleHours", label: "Cycle Hours" },
  { key: "basePointsPerCycle", label: "Base BNP / Cycle" },
  { key: "perActiveReferralBoostBps", label: "Boost per Active Referral (bps)" },
  { key: "maxBoostBps", label: "Max Boost (bps)" },
  { key: "activeReferralWindowHours", label: "Active Referral Window (hours)" },
  { key: "referralBindWindowHours", label: "Referral Bind Window (hours)" },
  {
    key: "claimWindowHours",
    label: "Claim Window (hours)",
    hint: "How long after a cycle ends it can still be claimed before it is forfeited.",
  },
];

type MiningConfigCardProps = {
  config: AdminMiningConfig | null;
  changedFields: string[];
  canMutate: boolean;
  saving: boolean;
  onFieldChange: <K extends keyof AdminMiningConfigFields>(
    key: K,
    value: AdminMiningConfigFields[K],
  ) => void;
  onReset: () => void;
  onSave: () => Promise<void>;
};

function formatUpdatedAt(value: string | undefined) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toLocaleString();
}

export function MiningConfigCard({
  config,
  changedFields,
  canMutate,
  saving,
  onFieldChange,
  onReset,
  onSave,
}: MiningConfigCardProps) {
  const disabled = !canMutate || !config || saving;
  const flags = config ? effectiveMiningFlags(config) : null;
  const changed = new Set(changedFields);
  const updatedAt = formatUpdatedAt(config?.updatedAt);

  return (
    <Card>
      <CardHeader className="p-4 sm:p-6">
        <CardTitle className="text-sm sm:text-base">Mining Configuration</CardTitle>
        {updatedAt && (
          <CardDescription className="text-xs sm:text-sm">Last updated {updatedAt}</CardDescription>
        )}
      </CardHeader>
      <CardContent className="space-y-4 p-4 pt-0 sm:p-6 sm:pt-0">
        <MiningRuntimeFlagsNotice runtimeFlags={config?.runtimeFlags} />

        <div className="grid grid-cols-1 gap-3 sm:gap-4 md:grid-cols-2">
          <MiningFlagField
            id="enabled"
            label="Mining Enabled"
            flag={flags?.mining ?? null}
            changed={changed.has("enabled")}
            disabled={disabled}
            onChange={(value) => onFieldChange("enabled", value)}
          />
          <MiningFlagField
            id="referralsEnabled"
            label="Referrals Enabled"
            flag={flags?.referrals ?? null}
            changed={changed.has("referralsEnabled")}
            disabled={disabled}
            onChange={(value) => onFieldChange("referralsEnabled", value)}
          />

          {NUMBER_FIELDS.map((field) => (
            <MiningNumberField
              key={field.key}
              id={field.key}
              label={field.label}
              hint={field.hint}
              value={config?.[field.key]}
              changed={changed.has(field.key)}
              disabled={disabled}
              onChange={(value) => onFieldChange(field.key, value)}
            />
          ))}
        </div>

        <MiningConfigActions
          changedCount={changed.size}
          canSave={canMutate && !!config}
          saving={saving}
          onReset={onReset}
          onSave={onSave}
        />
      </CardContent>
    </Card>
  );
}
