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

type PushConfirmDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  sending: boolean;
  title: string;
  body: string;
  targetLabel: string;
  isSpecific: boolean;
  selectedUsersCount: number;
  onConfirm: () => Promise<void>;
};

export function PushConfirmDialog({
  open,
  onOpenChange,
  sending,
  title,
  body,
  targetLabel,
  isSpecific,
  selectedUsersCount,
  onConfirm,
}: PushConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Send notification?</DialogTitle>
          <DialogDescription>
            This will send a push notification and create an in-app notification for{" "}
            <strong>
              {isSpecific
                ? `${selectedUsersCount} selected user${selectedUsersCount !== 1 ? "s" : ""}`
                : targetLabel.toLowerCase()}
            </strong>
            . This cannot be undone.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-1 rounded-lg border bg-muted/40 p-3">
          <p className="text-sm font-semibold">{title}</p>
          <p className="text-xs text-muted-foreground">{body}</p>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={sending}>
            Cancel
          </Button>
          <Button onClick={() => void onConfirm()} disabled={sending}>
            {sending && <Loader2 className="h-4 w-4 animate-spin" />}
            Confirm & Send
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
