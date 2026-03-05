"use client";

import { Loader2, Save } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { AdminTipSettings } from "@/lib/api-client";
import { boolBadge, type CurrencyDraft } from "../_lib/tip-settings";

type TipCurrencyCardProps = {
  row: AdminTipSettings["currencies"][number];
  draft: CurrencyDraft;
  canMutate: boolean;
  saving: boolean;
  onDraftChange: (patch: Partial<CurrencyDraft>) => void;
  onSave: () => Promise<void>;
};

export function TipCurrencyCard({
  row,
  draft,
  canMutate,
  saving,
  onDraftChange,
  onSave,
}: TipCurrencyCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <CardTitle className="text-base">
            {row.code} · {row.name}
          </CardTitle>
          <div className="flex flex-wrap items-center gap-2">
            {row.kind === "points" ? (
              <Badge className="bg-blue-500/15 text-blue-300">Points</Badge>
            ) : (
              <Badge className="bg-violet-500/15 text-violet-300">Token</Badge>
            )}
            {boolBadge(row.isEnabled, "Enabled", "Disabled")}
            {boolBadge(row.feePolicy?.isActive ?? false, "Policy Active", "Policy Off")}
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid gap-3 md:grid-cols-2">
          <TextField
            id={`name-${row.code}`}
            label="Name"
            value={draft.name}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ name: value })}
          />
          <TextField
            id={`symbol-${row.code}`}
            label="Symbol"
            value={draft.symbol}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ symbol: value.toUpperCase() })}
          />
          <TextField
            id={`feeBps-${row.code}`}
            type="number"
            min={0}
            max={10000}
            label="Fee (bps)"
            value={String(draft.feeBps)}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ feeBps: Number(value || 0) })}
          />
          <TextField
            id={`minTip-${row.code}`}
            label={`Min Tip (${row.symbol})`}
            value={draft.minTip}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ minTip: value })}
          />
          <TextField
            id={`maxTip-${row.code}`}
            label={`Max Tip (${row.symbol})`}
            value={draft.maxTip}
            disabled={!canMutate}
            placeholder="No max"
            onChange={(value) => onDraftChange({ maxTip: value })}
          />
          <TextField
            id={`minFee-${row.code}`}
            label={`Min Fee (${row.symbol})`}
            value={draft.minFee}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ minFee: value })}
          />
          <TextField
            id={`maxFee-${row.code}`}
            label={`Max Fee (${row.symbol})`}
            value={draft.maxFee}
            disabled={!canMutate}
            placeholder="No max"
            onChange={(value) => onDraftChange({ maxFee: value })}
          />

          <SelectField
            label="Sender Pays Fee"
            value={draft.senderPaysFee ? "true" : "false"}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ senderPaysFee: value === "true" })}
            options={[
              { value: "true", label: "Yes" },
              { value: "false", label: "No (hunter pays)" },
            ]}
          />
          <SelectField
            label="Policy Active"
            value={draft.policyActive ? "true" : "false"}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ policyActive: value === "true" })}
            options={[
              { value: "true", label: "Active" },
              { value: "false", label: "Inactive" },
            ]}
          />
          <SelectField
            label="Currency Enabled"
            value={draft.isEnabled ? "true" : "false"}
            disabled={!canMutate}
            onChange={(value) => onDraftChange({ isEnabled: value === "true" })}
            options={[
              { value: "true", label: "Enabled" },
              { value: "false", label: "Disabled" },
            ]}
          />
        </div>

        <div className="rounded-lg border p-3">
          <p className="text-sm font-medium">Fee Vault</p>
          <p className="text-xs text-muted-foreground">
            Current balance: {row.feeVaultBalance} {row.symbol}
          </p>
          <p className="text-xs text-muted-foreground">Atomic: {row.feeVaultBalanceAtomic}</p>
        </div>

        <div className="flex justify-end">
          <Button onClick={() => void onSave()} disabled={!canMutate || saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Save {row.code}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

function TextField({
  id,
  label,
  value,
  disabled,
  placeholder,
  type = "text",
  min,
  max,
  onChange,
}: {
  id: string;
  label: string;
  value: string;
  disabled: boolean;
  placeholder?: string;
  type?: string;
  min?: number;
  max?: number;
  onChange: (value: string) => void;
}) {
  return (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      <Input
        id={id}
        type={type}
        min={min}
        max={max}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        disabled={disabled}
        placeholder={placeholder}
      />
    </div>
  );
}

function SelectField({
  label,
  value,
  disabled,
  options,
  onChange,
}: {
  label: string;
  value: string;
  disabled: boolean;
  options: Array<{ value: string; label: string }>;
  onChange: (value: string) => void;
}) {
  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      <Select value={value} onValueChange={onChange} disabled={disabled}>
        <SelectTrigger>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {options.map((option) => (
            <SelectItem key={option.value} value={option.value}>
              {option.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
