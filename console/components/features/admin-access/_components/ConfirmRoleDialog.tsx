'use client';

import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import type { AdminUser } from '@/lib/api-client';

export type PendingAction =
  | 'grant_owner'
  | 'revoke_owner'
  | 'grant_dev'
  | 'revoke_dev'
  | 'grant_admin'
  | 'revoke_admin'
  | 'grant_moderator'
  | 'revoke_moderator';

export function ConfirmRoleDialog({
  open,
  onOpenChange,
  pendingAction,
  confirmNote,
  confirmError,
  actionUserId,
  onConfirm,
  onCancel,
  onNoteChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  pendingAction: { user: AdminUser; action: PendingAction } | null;
  confirmNote: string;
  confirmError: string | null;
  actionUserId: string | null;
  onConfirm: () => void;
  onCancel: () => void;
  onNoteChange: (value: string) => void;
}) {
  return (
    <Dialog
      open={open}
      onOpenChange={(nextOpen) => {
        onOpenChange(nextOpen);
        if (!nextOpen) {
          onCancel();
        }
      }}
    >
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Confirm Role Action</DialogTitle>
          <DialogDescription>
            {pendingAction
              ? `Apply ${pendingAction.action.replace('_', ' ')} for ${pendingAction.user.email}?`
              : 'Confirm role action.'}
          </DialogDescription>
        </DialogHeader>
        {pendingAction?.action.startsWith('grant') ? (
          <div className="space-y-2">
            <p className="text-sm text-muted-foreground">Optional note for audit log</p>
            <Textarea
              rows={3}
              value={confirmNote}
              onChange={(event) => onNoteChange(event.target.value)}
              placeholder="Reason/context for this role grant"
            />
          </div>
        ) : null}

        {confirmError ? <p className="text-sm text-destructive">{confirmError}</p> : null}

        <DialogFooter>
          <Button variant="outline" onClick={onCancel} disabled={Boolean(actionUserId)}>
            Cancel
          </Button>
          <Button
            variant={pendingAction?.action.startsWith('revoke') ? 'destructive' : 'default'}
            onClick={onConfirm}
            disabled={!pendingAction || Boolean(actionUserId)}
          >
            {actionUserId ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            Confirm
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
