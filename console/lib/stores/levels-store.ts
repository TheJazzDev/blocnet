import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { UpdateLevelInput, UserLevel } from "@/lib/api/levels";

export type LevelEditForm = Required<UpdateLevelInput>;

interface LevelsState {
  // Edit state (one level is edited at a time)
  editingId: string | null;
  editForm: LevelEditForm | null;

  // Actions
  startEdit: (level: UserLevel) => void;
  patchEditForm: (patch: Partial<LevelEditForm>) => void;
  cancelEdit: () => void;
}

export function toLevelEditForm(level: UserLevel): LevelEditForm {
  return {
    name: level.name,
    description: level.description,
    iconUrl: level.iconUrl,
    requiredBnp: level.requiredBnp,
    requiredComments: level.requiredComments,
    requiredDaysActive: level.requiredDaysActive,
    requiredQuests: level.requiredQuests,
    requiredUpdates: level.requiredUpdates,
    requiredProjects: level.requiredProjects,
    color: level.color ?? "",
    isActive: level.isActive,
    sortOrder: level.sortOrder,
  };
}

export const useLevelsStore = create<LevelsState>()(
  devtools(
    (set) => ({
      editingId: null,
      editForm: null,

      startEdit: (level) => set({ editingId: level.id, editForm: toLevelEditForm(level) }),
      patchEditForm: (patch) =>
        set((state) => ({
          editForm: state.editForm ? { ...state.editForm, ...patch } : state.editForm,
        })),
      cancelEdit: () => set({ editingId: null, editForm: null }),
    }),
    { name: "levels-store" },
  ),
);
