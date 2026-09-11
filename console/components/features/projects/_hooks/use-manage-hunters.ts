"use client";

import { useMemo, useState } from "react";
import type { AdminUser } from "@/lib/api-client";
import {
  useAssignHunterMutation,
  useInviteHunterMutation,
  useProjectInvitesQuery,
} from "@/lib/hooks/queries";
import { useProjectsStore } from "@/lib/stores";
import { groupInvites } from "../_lib/project-hunters";

export const HUNTER_NOTE_MAX_LENGTH = 500;

export type HunterAction = "assign" | "invite";

function errorMessage(error: unknown, fallback: string): string | null {
  if (!error) return null;
  return error instanceof Error ? error.message : fallback;
}

/**
 * State for the "Manage hunters" sheet: which project is open (Zustand),
 * the project's invites (TanStack Query), the optional note, and the
 * assign/invite actions.
 */
export function useManageHunters() {
  const project = useProjectsStore((state) => state.hunterSheetProject);
  const closeHunterSheet = useProjectsStore((state) => state.closeHunterSheet);
  const [note, setNote] = useState("");

  const invitesQuery = useProjectInvitesQuery(project?.id ?? null);
  const assignMutation = useAssignHunterMutation();
  const inviteMutation = useInviteHunterMutation();

  const grouped = useMemo(() => groupInvites(invitesQuery.data ?? []), [invitesQuery.data]);

  const pendingMutation = assignMutation.isPending
    ? assignMutation
    : inviteMutation.isPending
      ? inviteMutation
      : null;
  const busyHunterId = pendingMutation?.variables?.hunterId ?? null;

  function close() {
    closeHunterSheet();
    setNote("");
  }

  async function runAction(kind: HunterAction, hunter: AdminUser) {
    if (!project) return;
    const mutation = kind === "assign" ? assignMutation : inviteMutation;
    try {
      await mutation.mutateAsync({
        projectId: project.id,
        hunterId: hunter.id,
        note: note.trim() || undefined,
      });
    } catch {
      // apiFetch already surfaced the error as a toast (e.g. 403 for admins
      // who do not own this project).
    }
  }

  return {
    project,
    note,
    setNote,
    grouped,
    busyHunterId,
    invitesLoading: invitesQuery.isLoading,
    invitesError: errorMessage(invitesQuery.error, "Failed to load invites"),
    close,
    runAction,
  };
}
