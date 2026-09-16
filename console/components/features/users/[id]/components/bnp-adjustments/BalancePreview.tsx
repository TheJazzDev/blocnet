import { ArrowRight } from "lucide-react";
import {
  formatAtomicBnp,
  formatWholeBnp,
  type BnpBalances,
} from "@/lib/api/bnp-adjustments";

type BalancePreviewProps = {
  before: BnpBalances;
  after: BnpBalances;
};

function Row({ label, from, to }: { label: string; from: string; to: string }) {
  return (
    <div className="flex flex-col gap-0.5 sm:flex-row sm:items-center sm:justify-between sm:gap-3">
      <span className="text-muted-foreground">{label}</span>
      <span className="flex items-center gap-1.5 font-medium tabular-nums">
        {from}
        <ArrowRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
        {to} BNP
      </span>
    </div>
  );
}

/** Before -> after for both BNP balances an adjustment moves. */
export function BalancePreview({ before, after }: BalancePreviewProps) {
  return (
    <div className="space-y-2 rounded-md border bg-muted/30 p-3 text-xs sm:text-sm">
      <Row
        label="Wallet balance"
        from={formatAtomicBnp(before.walletAtomic)}
        to={formatAtomicBnp(after.walletAtomic)}
      />
      <Row
        label="Claimed BNP"
        from={formatWholeBnp(before.claimedPoints)}
        to={formatWholeBnp(after.claimedPoints)}
      />
    </div>
  );
}
