import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { QuestModel, BadgeOption } from "@/components/features/quests/_components/quest-models";

interface QuestsState {
  // Data
  quests: QuestModel[];
  badges: BadgeOption[];
  isLoading: boolean;
  error: string | null;

  // Dialogs
  createOpen: boolean;
  editOpen: boolean;
  selectedQuest: QuestModel | null;
  createSubmitError: string | null;
  editSubmitError: string | null;

  // Actions - Data
  setQuests: (quests: QuestModel[]) => void;
  setBadges: (badges: BadgeOption[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;

  // Actions - Dialogs
  openCreate: () => void;
  closeCreate: () => void;
  openEdit: (quest: QuestModel) => void;
  closeEdit: () => void;
  setCreateSubmitError: (error: string | null) => void;
  setEditSubmitError: (error: string | null) => void;

  reset: () => void;
}

const initialState = {
  quests: [],
  badges: [],
  isLoading: true,
  error: null,
  createOpen: false,
  editOpen: false,
  selectedQuest: null,
  createSubmitError: null,
  editSubmitError: null,
};

export const useQuestsStore = create<QuestsState>()(
  devtools(
    (set) => ({
      ...initialState,

      // Data actions
      setQuests: (quests) => set({ quests }),
      setBadges: (badges) => set({ badges }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error, isLoading: false }),

      // Dialog actions
      openCreate: () => set({ createOpen: true, createSubmitError: null }),
      closeCreate: () => set({ createOpen: false, createSubmitError: null }),
      openEdit: (quest) =>
        set({
          editOpen: true,
          selectedQuest: quest,
          editSubmitError: null,
        }),
      closeEdit: () =>
        set({
          editOpen: false,
          selectedQuest: null,
          editSubmitError: null,
        }),
      setCreateSubmitError: (createSubmitError) => set({ createSubmitError }),
      setEditSubmitError: (editSubmitError) => set({ editSubmitError }),

      reset: () => set(initialState),
    }),
    { name: "quests-store" }
  )
);
