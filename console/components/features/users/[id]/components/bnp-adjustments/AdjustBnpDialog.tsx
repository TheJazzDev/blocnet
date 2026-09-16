"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { BnpBalances } from "@/lib/api/bnp-adjustments";
import { AdjustBnpDialogFooter } from "./AdjustBnpDialogFooter";
import { AdjustBnpFormStep } from "./AdjustBnpFormStep";
import { BalancePreview } from "./BalancePreview";
import { useAdjustBnpForm } from "./use-adjust-bnp-form";

type AdjustBnpDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  userId: string;
  memberLabel: string;
  before: BnpBalances;
  onAdjusted?: () => void;
};

export function AdjustBnpDialog({ open, onOpenChange, ...rest }: AdjustBnpDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] max-w-[calc(100%-2rem)] overflow-y-auto p-4 sm:max-w-lg sm:p-6">
        {/* Mounted only while open, so each opening gets a fresh form and key. */}
        {open && <AdjustBnpDialogBody {...rest} onClose={() => onOpenChange(false)} />}
      </DialogContent>
    </Dialog>
  );
}

type BodyProps = Omit<AdjustBnpDialogProps, "open" | "onOpenChange"> & {
  onClose: () => void;
};

function describe(memberLabel: string, signed: number, amount: number): string {
  const verb = signed > 0 ? "Add" : "Remove";
  const preposition = signed > 0 ? "to" : "from";
  return `${verb} ${amount.toLocaleString("en-US")} BNP ${preposition} ${memberLabel}.`;
}

function AdjustBnpDialogBody({ userId, memberLabel, before, onAdjusted, onClose }: BodyProps) {
  const form = useAdjustBnpForm({
    userId,
    before,
    onDone: () => {
      onAdjusted?.();
      onClose();
    },
  });
  const confirming = form.step === "confirm";

  return (
    <>
      <DialogHeader>
        <DialogTitle className="text-base sm:text-lg">
          {confirming ? "Confirm adjustment" : "Adjust BNP"}
        </DialogTitle>
        <DialogDescription className="text-xs sm:text-sm">
          {confirming
            ? describe(memberLabel, form.signed, form.amount)
            : `Manually add or remove BNP for ${memberLabel}.`}
        </DialogDescription>
      </DialogHeader>

      {confirming ? (
        <div className="space-y-3">
          <BalancePreview before={before} after={form.after} />
          <p className="break-words rounded-md border p-3 text-xs text-muted-foreground sm:text-sm">
            {form.values.reason.trim()}
          </p>
        </div>
      ) : (
        <AdjustBnpFormStep values={form.values} onChange={form.setValues} />
      )}

      {form.visibleFormError && (
        <p className="text-xs text-destructive sm:text-sm">{form.visibleFormError}</p>
      )}
      {form.serverError && (
        <p
          role="alert"
          className="rounded-md border border-destructive/35 bg-destructive/10 p-3 text-xs text-destructive sm:text-sm"
        >
          {form.serverError}
        </p>
      )}

      <AdjustBnpDialogFooter
        step={form.step}
        isRemoval={form.signed < 0}
        canReview={!form.formError}
        isPending={form.isPending}
        onCancel={onClose}
        onReview={form.review}
        onBack={form.back}
        onSubmit={form.submit}
      />
    </>
  );
}
