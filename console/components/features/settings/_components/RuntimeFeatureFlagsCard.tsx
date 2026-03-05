"use client";

import { useMemo, useState } from "react";
import { Loader2, Save } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type {
  ClosedAlphaEmailRecord,
  RuntimeFeatureFlagsConfig,
} from "@/lib/api-client";

type RuntimeFlagKey = keyof Pick<
  RuntimeFeatureFlagsConfig,
  | "closedAlphaEnabled"
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
  closedAlphaEmails: ClosedAlphaEmailRecord[];
  closedAlphaTotal: number;
  closedAlphaLoading: boolean;
  closedAlphaMutating: boolean;
  closedAlphaStatus: string | null;
  onSave: () => Promise<void>;
  onSetFlag: (key: RuntimeFlagKey, enabled: boolean) => void;
  onAddEmail: (email: string, note?: string) => Promise<void>;
  onToggleEmailActive: (id: string, isActive: boolean) => Promise<void>;
  onRemoveEmail: (id: string) => Promise<void>;
};

const runtimeFlagFields: Array<{ key: RuntimeFlagKey; label: string }> = [
  { key: "closedAlphaEnabled", label: "Closed Alpha Signups" },
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
  closedAlphaEmails,
  closedAlphaTotal,
  closedAlphaLoading,
  closedAlphaMutating,
  closedAlphaStatus,
  onSave,
  onSetFlag,
  onAddEmail,
  onToggleEmailActive,
  onRemoveEmail,
}: RuntimeFeatureFlagsCardProps) {
  const [emailDraft, setEmailDraft] = useState("");
  const [noteDraft, setNoteDraft] = useState("");
  const hasEmails = closedAlphaEmails.length > 0;
  const sortedRows = useMemo(
    () =>
      [...closedAlphaEmails].sort((left, right) =>
        left.email.localeCompare(right.email),
      ),
    [closedAlphaEmails],
  );

  async function handleAddEmail() {
    const email = emailDraft.trim();
    if (!email) {
      return;
    }
    await onAddEmail(email, noteDraft.trim());
    setEmailDraft("");
    setNoteDraft("");
  }

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

        <div className="border-t border-border/60 pt-4 space-y-3">
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-sm font-medium">Closed Alpha Allowlist</p>
              <p className="text-xs text-muted-foreground">
                Only these emails can access mobile sign-in while Closed Alpha
                Signups is enabled.
              </p>
            </div>
            <span className="text-xs text-muted-foreground">
              {closedAlphaTotal} email{closedAlphaTotal === 1 ? "" : "s"}
            </span>
          </div>

          <div className="grid gap-2 md:grid-cols-[2fr_2fr_auto]">
            <Input
              placeholder="tester@domain.com"
              value={emailDraft}
              onChange={(event) => setEmailDraft(event.target.value)}
              disabled={!canMutate || closedAlphaMutating}
            />
            <Input
              placeholder="Optional note"
              value={noteDraft}
              onChange={(event) => setNoteDraft(event.target.value)}
              disabled={!canMutate || closedAlphaMutating}
            />
            <Button
              type="button"
              onClick={() => void handleAddEmail()}
              disabled={
                !canMutate ||
                closedAlphaMutating ||
                emailDraft.trim().length === 0
              }
            >
              {closedAlphaMutating ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : null}
              Add
            </Button>
          </div>

          {closedAlphaLoading ? (
            <LoadingSpinner className="py-4" />
          ) : hasEmails ? (
            <div className="space-y-2 max-h-64 overflow-auto pr-1">
              {sortedRows.map((row) => (
                <div
                  key={row.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded-md border border-border/60 p-2"
                >
                  <div className="min-w-0">
                    <p className="text-sm font-medium break-all">{row.email}</p>
                    <p className="text-xs text-muted-foreground">
                      {row.source} ·{" "}
                      {new Date(row.createdAt).toLocaleDateString()}
                      {row.note ? ` · ${row.note}` : ""}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Select
                      value={row.isActive ? "active" : "inactive"}
                      onValueChange={(value) =>
                        void onToggleEmailActive(row.id, value === "active")
                      }
                      disabled={!canMutate || closedAlphaMutating}
                    >
                      <SelectTrigger className="w-[124px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="inactive">Inactive</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button
                      type="button"
                      variant="ghost"
                      onClick={() => void onRemoveEmail(row.id)}
                      disabled={!canMutate || closedAlphaMutating}
                    >
                      Remove
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              No allowlisted tester emails yet.
            </p>
          )}

          {closedAlphaStatus ? (
            <p className="text-xs text-muted-foreground">{closedAlphaStatus}</p>
          ) : null}
        </div>
      </CardContent>
    </Card>
  );
}
