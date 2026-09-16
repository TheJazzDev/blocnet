import { ownersOf } from '../hunter-reliability/reliability.calc';

/** The ownership facts a handover needs about one gem. */
export interface HandoverProject {
  ownerAdminId: string;
  /** Assigned hunters, oldest first — the order `ownersOf` reads them in. */
  hunters: { id: string; hunterId: string; createdAt: Date }[];
}

/**
 * The writes that move one hunter's ownership of a gem to another.
 *
 * The receiving hunter takes the handing hunter's place in `ProjectHunter`
 * (same row, same `createdAt`), so they sit exactly where the handing hunter
 * sat in `ownersOf` — first, for a gem with one owner. When the handing hunter
 * owned the gem only through `Project.ownerAdminId` (no hunters assigned), the
 * receiver gets the gem's only `ProjectHunter` row, which `ownersOf` prefers
 * over the admin fallback. `ownerAdminId` moves too when it named the handing
 * hunter, so the single-owner field agrees with `ownersOf`.
 */
export interface HandoverPlan {
  /** A row the receiver already had (as co-owner), removed to keep theirs unique. */
  deleteRowId: string | null;
  /** Re-point this row at the receiver, keeping the earlier of the two slots. */
  moveRow: { id: string; createdAt: Date } | null;
  /** No row to move: give the receiver a fresh one. */
  createRow: boolean;
  moveOwnerAdmin: boolean;
}

/** Null when [fromId] does not own the gem (any more). */
export function planHandover(
  project: HandoverProject,
  fromId: string,
  toId: string,
): HandoverPlan | null {
  if (fromId === toId || !ownersOf(project).includes(fromId)) return null;

  const fromRow = project.hunters.find((row) => row.hunterId === fromId);
  const toRow = project.hunters.find((row) => row.hunterId === toId);
  const moveOwnerAdmin = project.ownerAdminId === fromId;

  if (!fromRow) {
    // Owner through ownerAdminId, no hunters assigned.
    return {
      deleteRowId: null,
      moveRow: null,
      createRow: true,
      moveOwnerAdmin,
    };
  }

  const createdAt =
    toRow && toRow.createdAt < fromRow.createdAt
      ? toRow.createdAt
      : fromRow.createdAt;
  return {
    deleteRowId: toRow?.id ?? null,
    moveRow: { id: fromRow.id, createdAt },
    createRow: false,
    moveOwnerAdmin,
  };
}
