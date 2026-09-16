"use client";

import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

type MiningNumberFieldProps = {
  id: string;
  label: string;
  hint?: string;
  value: number | undefined;
  changed: boolean;
  disabled: boolean;
  onChange: (value: number) => void;
};

export function MiningNumberField({
  id,
  label,
  hint,
  value,
  changed,
  disabled,
  onChange,
}: MiningNumberFieldProps) {
  const unavailable = value === undefined;

  return (
    <div className="space-y-1.5 sm:space-y-2">
      <Label htmlFor={id} className="text-xs sm:text-sm">
        {label}
      </Label>
      <Input
        id={id}
        type="number"
        min={0}
        step={1}
        value={value ?? ""}
        placeholder={unavailable ? "Not reported by the API" : undefined}
        className={cn("h-9 sm:h-10", changed && "border-primary/60")}
        onChange={(e) => {
          if (e.target.value === "") return;
          onChange(Number(e.target.value));
        }}
        disabled={disabled || unavailable}
      />
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}
