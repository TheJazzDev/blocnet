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

type EmailConfirmDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  sending: boolean;
  subject: string;
  message: string;
  targetLabel: string;
  isSpecific: boolean;
  selectedUsersCount: number;
  onConfirm: () => Promise<void>;
};

export function EmailConfirmDialog({
  open,
  onOpenChange,
  sending,
  subject,
  message,
  targetLabel,
  isSpecific,
  selectedUsersCount,
  onConfirm,
}: EmailConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Send email broadcast?</DialogTitle>
          <DialogDescription>
            This will send email to{" "}
            <strong>
              {isSpecific
                ? `${selectedUsersCount} selected user${selectedUsersCount !== 1 ? "s" : ""}`
                : targetLabel.toLowerCase()}
            </strong>
            . Delivery speed follows your configured per-minute rate.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-1 rounded-lg border bg-muted/40 p-3">
          <p className="text-sm font-semibold">{subject || "Untitled"}</p>
          <p className="line-clamp-4 text-xs text-muted-foreground">
            {message || "No message"}
          </p>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={sending}>
            Cancel
          </Button>
          <Button onClick={() => void onConfirm()} disabled={sending}>
            {sending && <Loader2 className="h-4 w-4 animate-spin" />}
            Confirm & Send Email
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
