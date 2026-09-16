"use client";

import { Loader2, RotateCcw, Save } from "lucide-react";
import { Button } from "@/components/ui/button";

type MiningConfigActionsProps = {
  changedCount: number;
  canSave: boolean;
  saving: boolean;
  onReset: () => void;
  onSave: () => Promise<void>;
};

export function MiningConfigActions({
  changedCount,
  canSave,
  saving,
  onReset,
  onSave,
}: MiningConfigActionsProps) {
  const dirty = changedCount > 0;

  return (
    <div className="flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-end">
      {dirty && (
        <p className="text-xs text-muted-foreground sm:mr-auto">
          {changedCount} unsaved change{changedCount === 1 ? "" : "s"}
        </p>
      )}
      <Button variant="outline" onClick={onReset} disabled={!dirty || saving}>
        <RotateCcw className="h-4 w-4" />
        Discard
      </Button>
      <Button onClick={() => void onSave()} disabled={!canSave || !dirty || saving}>
        {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
        Save Mining Config
      </Button>
    </div>
  );
}
