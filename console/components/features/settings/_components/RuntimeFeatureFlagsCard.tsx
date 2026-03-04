"use client";

import { Loader2, Save } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type { RuntimeFeatureFlagsConfig } from "@/lib/api-client";

type RuntimeFlagKey = keyof Pick<
  RuntimeFeatureFlagsConfig,
  | "alphaRadarEnabled"
  | "followPrefsEnabled"
  | "weeklyDigestEnabled"
  | "miningEnabled"
  | "referralsEnabled"
>;

type RuntimeFeatureFlagsCardProps = {
  canMutate: boolean;
  runtimeFlags: RuntimeFeatureFlagsConfig | null;
  runtimeFlagsLoading: boolean;
  runtimeFlagsSaving: boolean;
  runtimeFlagsStatus: string | null;
  onSave: () => Promise<void>;
  onSetFlag: (key: RuntimeFlagKey, enabled: boolean) => void;
};

const runtimeFlagFields: Array<{ key: RuntimeFlagKey; label: string }> = [
  { key: "alphaRadarEnabled", label: "Alpha Radar" },
  { key: "followPrefsEnabled", label: "Follow Preferences" },
  { key: "weeklyDigestEnabled", label: "Weekly Digest" },
  { key: "miningEnabled", label: "Mining" },
  { key: "referralsEnabled", label: "Referrals" },
];

export function RuntimeFeatureFlagsCard({
  canMutate,
  runtimeFlags,
  runtimeFlagsLoading,
  runtimeFlagsSaving,
  runtimeFlagsStatus,
  onSave,
  onSetFlag,
}: RuntimeFeatureFlagsCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <div>
          <CardTitle className="text-base">Runtime Feature Flags</CardTitle>
          <CardDescription>Live feature gating without redeploy.</CardDescription>
        </div>
        <Button
          size="sm"
          onClick={() => void onSave()}
          disabled={
            !canMutate ||
            !runtimeFlags ||
            runtimeFlagsLoading ||
            runtimeFlagsSaving
          }
        >
          {runtimeFlagsSaving ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Save className="h-4 w-4" />
          )}
          Save
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {runtimeFlagsLoading ? (
          <LoadingSpinner className="py-6" />
        ) : !runtimeFlags ? (
          <p className="text-sm text-muted-foreground">
            Runtime feature flags unavailable.
          </p>
        ) : (
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {runtimeFlagFields.map((field) => (
              <div key={field.key} className="space-y-1.5">
                <Label>{field.label}</Label>
                <Select
                  value={runtimeFlags[field.key] ? "true" : "false"}
                  onValueChange={(value) =>
                    onSetFlag(field.key, value === "true")
                  }
                  disabled={!canMutate || runtimeFlagsSaving}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            ))}
          </div>
        )}

        {runtimeFlagsStatus ? (
          <p className="text-xs text-muted-foreground">{runtimeFlagsStatus}</p>
        ) : null}
      </CardContent>
    </Card>
  );
}
