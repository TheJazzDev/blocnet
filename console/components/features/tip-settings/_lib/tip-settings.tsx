import { Badge } from "@/components/ui/badge";
import type { AdminTipSettings } from "@/lib/api-client";

export type CurrencyDraft = {
  name: string;
  symbol: string;
  isEnabled: boolean;
  feeBps: number;
  minTip: string;
  maxTip: string;
  minFee: string;
  maxFee: string;
  senderPaysFee: boolean;
  policyActive: boolean;
};

export function boolBadge(enabled: boolean, trueLabel = "Yes", falseLabel = "No") {
  if (enabled) {
    return <Badge className="bg-emerald-500/15 text-emerald-300">{trueLabel}</Badge>;
  }
  return <Badge variant="secondary">{falseLabel}</Badge>;
}

export function toDrafts(settings: AdminTipSettings): Record<string, CurrencyDraft> {
  const drafts: Record<string, CurrencyDraft> = {};
  for (const row of settings.currencies) {
    drafts[row.code] = {
      name: row.name,
      symbol: row.symbol,
      isEnabled: row.isEnabled,
      feeBps: row.feePolicy?.feeBps ?? 0,
      minTip: row.feePolicy?.minTip ?? "0.001",
      maxTip: row.feePolicy?.maxTip ?? "",
      minFee: row.feePolicy?.minFee ?? "0",
      maxFee: row.feePolicy?.maxFee ?? "",
      senderPaysFee: row.feePolicy?.senderPaysFee ?? true,
      policyActive: row.feePolicy?.isActive ?? true,
    };
  }
  return drafts;
}
