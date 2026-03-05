import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { BadgeModel, UserSearchResult } from "@/components/features/badges/_components/badge-models";

interface BadgesState {
  // Data
  badges: BadgeModel[];
  isLoading: boolean;
  error: string | null;

  // Dialogs
  createOpen: boolean;
  editOpen: boolean;
  grantOpen: boolean;
  selectedBadge: BadgeModel | null;

  // Create form
  newName: string;
  newDescription: string;
  newImageUrl: string;
  newCategory: string;
  newRarity: string;
  newPoints: string;
  creating: boolean;

  // Edit form
  editName: string;
  editDescription: string;
  editImageUrl: string;
  editCategory: string;
  editRarity: string;
  editPoints: string;
  editActive: boolean;
  editSaving: boolean;

  // Grant dialog
  grantUserIdentifier: string;
  grantMatches: UserSearchResult[];
  grantSearchLoading: boolean;
  grantSelected: UserSearchResult | null;
  granting: boolean;
  grantFeedback: { type: "success" | "error"; message: string } | null;

  // Actions - Data
  setBadges: (badges: BadgeModel[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;

  // Actions - Dialogs
  openCreate: () => void;
  closeCreate: () => void;
  openEdit: (badge: BadgeModel) => void;
  closeEdit: () => void;
  openGrant: (badge: BadgeModel) => void;
  closeGrant: () => void;

  // Actions - Create form
  setNewName: (name: string) => void;
  setNewDescription: (description: string) => void;
  setNewImageUrl: (url: string) => void;
  setNewCategory: (category: string) => void;
  setNewRarity: (rarity: string) => void;
  setNewPoints: (points: string) => void;
  setCreating: (creating: boolean) => void;
  resetCreateForm: () => void;

  // Actions - Edit form
  setEditName: (name: string) => void;
  setEditDescription: (description: string) => void;
  setEditImageUrl: (url: string) => void;
  setEditCategory: (category: string) => void;
  setEditRarity: (rarity: string) => void;
  setEditPoints: (points: string) => void;
  setEditActive: (active: boolean) => void;
  setEditSaving: (saving: boolean) => void;

  // Actions - Grant
  setGrantUserIdentifier: (identifier: string) => void;
  setGrantMatches: (matches: UserSearchResult[]) => void;
  setGrantSearchLoading: (loading: boolean) => void;
  setGrantSelected: (user: UserSearchResult | null) => void;
  setGranting: (granting: boolean) => void;
  setGrantFeedback: (feedback: { type: "success" | "error"; message: string } | null) => void;
  resetGrantForm: () => void;

  reset: () => void;
}

const initialCreateForm = {
  newName: "",
  newDescription: "",
  newImageUrl: "",
  newCategory: "engagement",
  newRarity: "common",
  newPoints: "0",
  creating: false,
};

const initialEditForm = {
  editName: "",
  editDescription: "",
  editImageUrl: "",
  editCategory: "engagement",
  editRarity: "common",
  editPoints: "0",
  editActive: true,
  editSaving: false,
};

const initialGrantForm = {
  grantUserIdentifier: "",
  grantMatches: [],
  grantSearchLoading: false,
  grantSelected: null,
  granting: false,
  grantFeedback: null,
};

const initialState = {
  badges: [],
  isLoading: false,
  error: null,
  createOpen: false,
  editOpen: false,
  grantOpen: false,
  selectedBadge: null,
  ...initialCreateForm,
  ...initialEditForm,
  ...initialGrantForm,
};

export const useBadgesStore = create<BadgesState>()(
  devtools(
    (set) => ({
      ...initialState,

      // Data actions
      setBadges: (badges) => set({ badges, error: null, isLoading: false }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error, isLoading: false }),

      // Dialog actions
      openCreate: () => set({ createOpen: true, ...initialCreateForm }),
      closeCreate: () => set({ createOpen: false }),

      openEdit: (badge) =>
        set({
          editOpen: true,
          selectedBadge: badge,
          editName: badge.name,
          editDescription: badge.description,
          editImageUrl: badge.imageUrl,
          editCategory: badge.category,
          editRarity: badge.rarity,
          editPoints: badge.pointsRequirement.toString(),
          editActive: badge.isActive,
          editSaving: false,
        }),

      closeEdit: () => set({ editOpen: false, selectedBadge: null }),

      openGrant: (badge) =>
        set({
          grantOpen: true,
          selectedBadge: badge,
          ...initialGrantForm,
        }),

      closeGrant: () => set({ grantOpen: false, selectedBadge: null }),

      // Create form actions
      setNewName: (newName) => set({ newName }),
      setNewDescription: (newDescription) => set({ newDescription }),
      setNewImageUrl: (newImageUrl) => set({ newImageUrl }),
      setNewCategory: (newCategory) => set({ newCategory }),
      setNewRarity: (newRarity) => set({ newRarity }),
      setNewPoints: (newPoints) => set({ newPoints }),
      setCreating: (creating) => set({ creating }),
      resetCreateForm: () => set(initialCreateForm),

      // Edit form actions
      setEditName: (editName) => set({ editName }),
      setEditDescription: (editDescription) => set({ editDescription }),
      setEditImageUrl: (editImageUrl) => set({ editImageUrl }),
      setEditCategory: (editCategory) => set({ editCategory }),
      setEditRarity: (editRarity) => set({ editRarity }),
      setEditPoints: (editPoints) => set({ editPoints }),
      setEditActive: (editActive) => set({ editActive }),
      setEditSaving: (editSaving) => set({ editSaving }),

      // Grant actions
      setGrantUserIdentifier: (grantUserIdentifier) =>
        set({ grantUserIdentifier, grantSelected: null }),
      setGrantMatches: (grantMatches) => set({ grantMatches }),
      setGrantSearchLoading: (grantSearchLoading) => set({ grantSearchLoading }),
      setGrantSelected: (grantSelected) =>
        set({
          grantSelected,
          grantUserIdentifier: grantSelected?.email ?? "",
          grantMatches: [],
        }),
      setGranting: (granting) => set({ granting }),
      setGrantFeedback: (grantFeedback) => set({ grantFeedback }),
      resetGrantForm: () => set(initialGrantForm),

      reset: () => set(initialState),
    }),
    { name: "badges-store" }
  )
);
