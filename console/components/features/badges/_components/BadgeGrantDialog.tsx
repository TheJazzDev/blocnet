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
import { Input } from "@/components/ui/input";
import type { UserSearchResult } from "./badge-models";

type BadgeGrantDialogProps = {
  open: boolean;
  canMutate: boolean;
  granting: boolean;
  selectedBadgeName: string | null;
  userIdentifier: string;
  selectedUser: UserSearchResult | null;
  grantMatches: UserSearchResult[];
  searching: boolean;
  onOpenChange: (open: boolean) => void;
  onUserIdentifierChange: (value: string) => void;
  onSelectUser: (entry: UserSearchResult) => void;
  onSubmit: (event: React.FormEvent) => Promise<void>;
};

export function BadgeGrantDialog({
  open,
  canMutate,
  granting,
  selectedBadgeName,
  userIdentifier,
  selectedUser,
  grantMatches,
  searching,
  onOpenChange,
  onUserIdentifierChange,
  onSelectUser,
  onSubmit,
}: BadgeGrantDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Grant Badge</DialogTitle>
          <DialogDescription>
            Manually grant &quot;{selectedBadgeName}&quot; badge to a user.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={(event) => void onSubmit(event)} className="space-y-4">
          <div>
            <label className="text-sm font-medium">User Email or UUID</label>
            <Input
              value={userIdentifier}
              onChange={(e) => onUserIdentifierChange(e.target.value)}
              placeholder="Search by email or paste user UUID"
              disabled={!canMutate || granting}
            />
            {searching && (
              <p className="mt-2 text-xs text-muted-foreground">Searching users...</p>
            )}
            {!searching && grantMatches.length > 0 && !selectedUser && (
              <div className="mt-2 max-h-40 space-y-1 overflow-auto rounded-md border p-2">
                {grantMatches.map((entry) => (
                  <button
                    key={entry.id}
                    type="button"
                    className="w-full rounded-sm px-2 py-1 text-left text-sm hover:bg-accent"
                    onClick={() => onSelectUser(entry)}
                  >
                    <span className="font-medium">{entry.displayName ?? entry.email}</span>
                    <span className="ml-2 text-xs text-muted-foreground">{entry.email}</span>
                  </button>
                ))}
              </div>
            )}
            {selectedUser && (
              <p className="mt-2 text-xs text-emerald-300">
                Selected: {selectedUser.displayName ?? selectedUser.email} ({selectedUser.id})
              </p>
            )}
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={granting}>
              Cancel
            </Button>
            <Button type="submit" disabled={!canMutate || granting}>
              {granting && <Loader2 className="h-4 w-4 animate-spin" />}
              Grant Badge
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
