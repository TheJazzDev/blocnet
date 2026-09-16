import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DialogFooter } from "@/components/ui/dialog";
import type { AdjustBnpStep } from "./use-adjust-bnp-form";

type AdjustBnpDialogFooterProps = {
  step: AdjustBnpStep;
  isRemoval: boolean;
  canReview: boolean;
  isPending: boolean;
  onCancel: () => void;
  onReview: () => void;
  onBack: () => void;
  onSubmit: () => void;
};

export function AdjustBnpDialogFooter(props: AdjustBnpDialogFooterProps) {
  const { step, isRemoval, isPending } = props;

  if (step === "form") {
    return (
      <DialogFooter className="flex-col-reverse gap-2 sm:flex-row">
        <Button variant="outline" onClick={props.onCancel}>
          Cancel
        </Button>
        <Button disabled={!props.canReview} onClick={props.onReview}>
          Review
        </Button>
      </DialogFooter>
    );
  }

  return (
    <DialogFooter className="flex-col-reverse gap-2 sm:flex-row">
      <Button variant="outline" disabled={isPending} onClick={props.onBack}>
        Back
      </Button>
      <Button
        variant={isRemoval ? "destructive" : "default"}
        disabled={isPending}
        onClick={props.onSubmit}
      >
        {isPending && <Loader2 className="animate-spin" />}
        {isRemoval ? "Remove BNP" : "Add BNP"}
      </Button>
    </DialogFooter>
  );
}
