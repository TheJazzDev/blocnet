"use client";

import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Textarea } from "@/components/ui/textarea";
import type { AdminProject } from "@/lib/api-client";
import { HUNTER_NOTE_MAX_LENGTH, useManageHunters } from "../_hooks/use-manage-hunters";
import { HunterSearch } from "./HunterSearch";
import { ProjectInviteList } from "./ProjectInviteList";

function PermissionHint({ project }: { project: AdminProject | null }) {
  const ownerLabel = project?.owner
    ? project.owner.displayName?.trim() || project.owner.email
    : null;
  return (
    <p className="rounded-md border border-border/60 bg-muted/30 px-3 py-2 text-xs text-muted-foreground">
      Only the platform owner{ownerLabel ? ` or this project's owner admin (${ownerLabel})` : ""} can
      change hunters; anyone else gets a permission error.
    </p>
  );
}

/**
 * Right-hand sheet opened from the projects table: search hunters, assign or
 * invite them, and review the project's invites. Open/close state lives in
 * the projects Zustand store; server state comes from TanStack Query.
 */
export function ManageHuntersSheet() {
  const hunters = useManageHunters();
  const { project } = hunters;

  return (
    <Sheet open={Boolean(project)} onOpenChange={(open) => !open && hunters.close()}>
      <SheetContent className="overflow-y-auto">
        <SheetHeader>
          <SheetTitle>Manage hunters</SheetTitle>
          <SheetDescription>
            {project && (
              <>
                <span className="font-medium text-foreground">{project.name}</span>
                {" — "}assign a hunter right away, or send an invite they accept in the app.
              </>
            )}
          </SheetDescription>
        </SheetHeader>

        <PermissionHint project={project} />

        <div className="space-y-1.5">
          <Label htmlFor="hunter-note">Note (optional)</Label>
          <Textarea
            id="hunter-note"
            value={hunters.note}
            maxLength={HUNTER_NOTE_MAX_LENGTH}
            onChange={(event) => hunters.setNote(event.target.value)}
            placeholder="Context the hunter sees with the invite, kept in the audit log."
            rows={2}
          />
          <p className="text-[11px] text-muted-foreground">
            {hunters.note.length}/{HUNTER_NOTE_MAX_LENGTH}
          </p>
        </div>

        <HunterSearch
          grouped={hunters.grouped}
          busyHunterId={hunters.busyHunterId}
          disabled={!project}
          onAssign={(hunter) => void hunters.runAction("assign", hunter)}
          onInvite={(hunter) => void hunters.runAction("invite", hunter)}
        />

        <Separator />

        <ProjectInviteList
          grouped={hunters.grouped}
          loading={hunters.invitesLoading}
          error={hunters.invitesError}
        />
      </SheetContent>
    </Sheet>
  );
}
