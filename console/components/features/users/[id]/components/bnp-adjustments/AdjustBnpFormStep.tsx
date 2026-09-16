import { Minus, Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  MAX_BNP_ADJUSTMENT,
  REASON_MAX,
  REASON_MIN,
  type AdjustmentDirection,
} from "@/lib/api/bnp-adjustments";
import { cn } from "@/lib/utils";

export type AdjustBnpFormValues = {
  direction: AdjustmentDirection;
  amountRaw: string;
  reason: string;
};

type AdjustBnpFormStepProps = {
  values: AdjustBnpFormValues;
  onChange: (next: AdjustBnpFormValues) => void;
};

const DIRECTIONS: Array<{ value: AdjustmentDirection; label: string; icon: typeof Plus }> = [
  { value: "add", label: "Add BNP", icon: Plus },
  { value: "remove", label: "Remove BNP", icon: Minus },
];

export function AdjustBnpFormStep({ values, onChange }: AdjustBnpFormStepProps) {
  const reasonLength = values.reason.trim().length;

  return (
    <div className="space-y-3 sm:space-y-4">
      <div className="grid grid-cols-2 gap-2" role="radiogroup" aria-label="Direction">
        {DIRECTIONS.map(({ value, label, icon: Icon }) => {
          const active = values.direction === value;
          return (
            <Button
              key={value}
              type="button"
              role="radio"
              aria-checked={active}
              variant={active ? "default" : "outline"}
              className={cn(
                "min-h-[44px] text-xs sm:text-sm",
                active && value === "remove" && "from-rose-500 via-rose-500 to-rose-400/80",
              )}
              onClick={() => onChange({ ...values, direction: value })}
            >
              <Icon />
              {label}
            </Button>
          );
        })}
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="bnp-adjust-amount" className="text-xs sm:text-sm">
          Amount (whole BNP)
        </Label>
        <Input
          id="bnp-adjust-amount"
          inputMode="numeric"
          autoComplete="off"
          placeholder={`1 – ${MAX_BNP_ADJUSTMENT.toLocaleString("en-US")}`}
          value={values.amountRaw}
          onChange={(event) =>
            onChange({ ...values, amountRaw: event.target.value.replace(/[^\d]/g, "") })
          }
        />
      </div>

      <div className="space-y-1.5">
        <Label htmlFor="bnp-adjust-reason" className="text-xs sm:text-sm">
          Reason
        </Label>
        <Textarea
          id="bnp-adjust-reason"
          rows={3}
          maxLength={REASON_MAX + 20}
          placeholder="Why is this balance changing? Visible in the audit log and the member's wallet."
          value={values.reason}
          onChange={(event) => onChange({ ...values, reason: event.target.value })}
          className="text-xs sm:text-sm"
        />
        <p className="text-[11px] text-muted-foreground">
          {reasonLength}/{REASON_MAX} · at least {REASON_MIN} characters
        </p>
      </div>
    </div>
  );
}
