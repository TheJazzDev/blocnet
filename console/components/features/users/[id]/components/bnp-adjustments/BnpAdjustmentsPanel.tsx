"use client";

import { useState } from "react";
import { SlidersHorizontal } from "lucide-react";
import { Button } from "@/components/ui/button";
import type { AdminUserDetail } from "@/lib/api-client";
import { currentBnpBalances } from "@/lib/api/bnp-adjustments";
import { AdjustBnpDialog } from "./AdjustBnpDialog";
import { BnpAdjustmentHistory } from "./BnpAdjustmentHistory";

type BnpAdjustmentsPanelProps = {
  user: AdminUserDetail;
  canAdjust: boolean;
  onAdjusted?: () => void;
};

/** F-66: "Adjust BNP" (owner/admin only) and the manual adjustment history. */
export function BnpAdjustmentsPanel({ user, canAdjust, onAdjusted }: BnpAdjustmentsPanelProps) {
  const [open, setOpen] = useState(false);
  const adjustable = canAdjust && !user.isDeactivated;

  return (
    <div className="space-y-2">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <h4 className="text-xs font-semibold sm:text-sm">Manual BNP Adjustments</h4>
        {canAdjust && (
          <Button
            size="sm"
            variant="outline"
            className="min-h-[44px] self-start sm:min-h-0"
            disabled={!adjustable}
            title={adjustable ? undefined : "Deactivated accounts cannot be adjusted"}
            onClick={() => setOpen(true)}
          >
            <SlidersHorizontal />
            Adjust BNP
          </Button>
        )}
      </div>

      <BnpAdjustmentHistory userId={user.id} />

      {adjustable && (
        <AdjustBnpDialog
          open={open}
          onOpenChange={setOpen}
          userId={user.id}
          memberLabel={user.displayName || user.email}
          before={currentBnpBalances(user)}
          onAdjusted={onAdjusted}
        />
      )}
    </div>
  );
}
