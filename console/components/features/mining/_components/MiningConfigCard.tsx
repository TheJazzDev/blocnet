"use client";

import { Loader2, Save } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Dispatch, SetStateAction } from "react";
import type { AdminMiningConfig } from "@/lib/api-client";

type MiningConfigCardProps = {
  config: AdminMiningConfig | null;
  canMutate: boolean;
  saving: boolean;
  onChange: Dispatch<SetStateAction<AdminMiningConfig | null>>;
  onSave: () => Promise<void>;
};

export function MiningConfigCard({
  config,
  canMutate,
  saving,
  onChange,
  onSave,
}: MiningConfigCardProps) {
  const disabled = !canMutate || !config;

  function updateNumber<K extends keyof AdminMiningConfig>(key: K, value: number) {
    onChange((prev) => (prev ? { ...prev, [key]: value } : prev));
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Mining Configuration</CardTitle>
      </CardHeader>
      <CardContent className="grid gap-4 md:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="enabled">Mining Enabled</Label>
          <select
            id="enabled"
            className="h-10 w-full rounded-md border bg-background px-3 text-sm"
            value={config?.enabled ? "true" : "false"}
            onChange={(e) =>
              onChange((prev) =>
                prev ? { ...prev, enabled: e.target.value === "true" } : prev,
              )
            }
            disabled={disabled}
          >
            <option value="true">Enabled</option>
            <option value="false">Disabled</option>
          </select>
        </div>

        <div className="space-y-2">
          <Label htmlFor="referralsEnabled">Referrals Enabled</Label>
          <select
            id="referralsEnabled"
            className="h-10 w-full rounded-md border bg-background px-3 text-sm"
            value={config?.referralsEnabled ? "true" : "false"}
            onChange={(e) =>
              onChange((prev) =>
                prev ? { ...prev, referralsEnabled: e.target.value === "true" } : prev,
              )
            }
            disabled={disabled}
          >
            <option value="true">Enabled</option>
            <option value="false">Disabled</option>
          </select>
        </div>

        <ConfigInput
          id="cycleHours"
          label="Cycle Hours"
          value={config?.cycleHours}
          disabled={disabled}
          onChange={(value) => updateNumber("cycleHours", value)}
        />
        <ConfigInput
          id="basePointsPerCycle"
          label="Base BNP / Cycle"
          value={config?.basePointsPerCycle}
          disabled={disabled}
          onChange={(value) => updateNumber("basePointsPerCycle", value)}
        />
        <ConfigInput
          id="perActiveReferralBoostBps"
          label="Boost per Active Referral (bps)"
          value={config?.perActiveReferralBoostBps}
          disabled={disabled}
          onChange={(value) => updateNumber("perActiveReferralBoostBps", value)}
        />
        <ConfigInput
          id="maxBoostBps"
          label="Max Boost (bps)"
          value={config?.maxBoostBps}
          disabled={disabled}
          onChange={(value) => updateNumber("maxBoostBps", value)}
        />
        <ConfigInput
          id="activeReferralWindowHours"
          label="Active Referral Window (hours)"
          value={config?.activeReferralWindowHours}
          disabled={disabled}
          onChange={(value) => updateNumber("activeReferralWindowHours", value)}
        />
        <ConfigInput
          id="referralBindWindowHours"
          label="Referral Bind Window (hours)"
          value={config?.referralBindWindowHours}
          disabled={disabled}
          onChange={(value) => updateNumber("referralBindWindowHours", value)}
        />

        <div className="flex justify-end md:col-span-2">
          <Button onClick={() => void onSave()} disabled={disabled || saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Save Mining Config
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function ConfigInput({
  id,
  label,
  value,
  onChange,
  disabled,
}: {
  id: string;
  label: string;
  value: number | undefined;
  onChange: (value: number) => void;
  disabled?: boolean;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      <Input
        id={id}
        type="number"
        value={value ?? 0}
        onChange={(e) => onChange(Number(e.target.value))}
        disabled={disabled}
      />
    </div>
  );
}
