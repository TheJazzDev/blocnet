"use client";

import { useState } from "react";
import {
  parseAdjustmentAmount,
  previewAdjustment,
  signedAmount,
  validateAdjustmentForm,
  type BnpBalances,
} from "@/lib/api/bnp-adjustments";
import { useCreateBnpAdjustmentMutation } from "@/lib/hooks/queries";
import type { AdjustBnpFormValues } from "./AdjustBnpFormStep";

export type AdjustBnpStep = "form" | "confirm";

/** State for one opening of the "Adjust BNP" dialog. */
export function useAdjustBnpForm(input: {
  userId: string;
  before: BnpBalances;
  onDone: () => void;
}) {
  // One key per dialog opening: a double-submit or retry cannot move BNP twice.
  const [idempotencyKey] = useState(() => crypto.randomUUID());
  const [step, setStep] = useState<AdjustBnpStep>("form");
  const [values, setValues] = useState<AdjustBnpFormValues>({
    direction: "add",
    amountRaw: "",
    reason: "",
  });
  const mutation = useCreateBnpAdjustmentMutation(input.userId);

  const formError = validateAdjustmentForm({ ...values, before: input.before });
  const amount = parseAdjustmentAmount(values.amountRaw) ?? 0;
  const signed = signedAmount(values.direction, amount);
  const touched = values.amountRaw !== "" && values.reason !== "";

  return {
    step,
    values,
    amount,
    signed,
    after: previewAdjustment(input.before, signed),
    formError,
    visibleFormError: step === "form" && touched ? formError : null,
    serverError: mutation.error instanceof Error ? mutation.error.message : null,
    isPending: mutation.isPending,
    setValues(next: AdjustBnpFormValues) {
      mutation.reset();
      setValues(next);
    },
    review() {
      if (!formError) setStep("confirm");
    },
    back() {
      mutation.reset();
      setStep("form");
    },
    submit() {
      mutation.mutate(
        { amount: signed, reason: values.reason.trim(), idempotencyKey },
        { onSuccess: input.onDone },
      );
    },
  };
}
