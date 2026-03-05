"use client";

import { Loader2 } from "lucide-react";
import type { AdminSocialCredential } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { prettyProvider } from "../_lib/social-credentials";

type DeleteCredentialDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  target: AdminSocialCredential | null;
  deleting: boolean;
  onConfirm: () => Promise<void>;
};

export function DeleteCredentialDialog({
  open,
  onOpenChange,
  target,
  deleting,
  onConfirm,
}: DeleteCredentialDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Delete Credential?</DialogTitle>
          <DialogDescription>
            This will permanently remove{" "}
            <span className="font-medium text-foreground">
              {target ? prettyProvider(target.provider) : "this credential"}
            </span>
            . This action cannot be undone.
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={deleting}>
            Cancel
          </Button>
          <Button variant="destructive" onClick={() => void onConfirm()} disabled={deleting}>
            {deleting && <Loader2 className="h-4 w-4 animate-spin" />}
            Delete
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
