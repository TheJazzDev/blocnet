"use client";

import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

type UserConfirmDialogProps = {
  open: boolean;
  confirmText: string | null;
  /** Action key such as "revoke-admin"; drives the destructive styling. */
  actionKey: string | null;
  loading: boolean;
  onOpenChange: (open: boolean) => void;
  onConfirm: () => void;
};

function isDestructiveAction(key: string | null) {
  if (!key) return false;
  return key.includes("revoke") || key.includes("delete") || key.includes("deactivate");
}

export function UserConfirmDialog({
  open,
  confirmText,
  actionKey,
  loading,
  onOpenChange,
  onConfirm,
}: UserConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Confirm Action</DialogTitle>
          <DialogDescription>
            {confirmText ?? "Please confirm this action."}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            variant={isDestructiveAction(actionKey) ? "destructive" : "default"}
            onClick={onConfirm}
            disabled={!actionKey || loading}
          >
            {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Confirm
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
