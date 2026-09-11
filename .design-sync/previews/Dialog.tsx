import * as React from "react";
import {
  Button,
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  Input,
  Label,
} from "blocnet-admin";

export const InviteModerator = () => (
  <Dialog open>
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Invite moderator</DialogTitle>
        <DialogDescription>They will get content-moderation access only.</DialogDescription>
      </DialogHeader>
      <div className="space-y-2">
        <Label htmlFor="invite-email">Email</Label>
        <Input id="invite-email" type="email" placeholder="name@blocnet.io" />
      </div>
      <DialogFooter>
        <DialogClose asChild>
          <Button variant="outline">Cancel</Button>
        </DialogClose>
        <Button>Send invite</Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
);

export const DestructiveConfirm = () => (
  <Dialog open>
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Suspend this user?</DialogTitle>
        <DialogDescription>
          @ada will lose access to mining, quests and the wallet until an admin lifts the
          suspension. This action is logged.
        </DialogDescription>
      </DialogHeader>
      <DialogFooter>
        <DialogClose asChild>
          <Button variant="outline">Keep active</Button>
        </DialogClose>
        <Button variant="destructive">Suspend user</Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
);
