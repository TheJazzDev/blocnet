import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type { QuestSubmission, StatusFilter } from "@/components/features/quest-submissions/_components/types";

interface QuestSubmissionsState {
  // Data
  submissions: QuestSubmission[];
  isLoading: boolean;
  error: string | null;
  statusFilter: StatusFilter;

  // Review dialog
  reviewOpen: boolean;
  selectedSubmission: QuestSubmission | null;
  reviewNotes: string;
  isSubmitting: boolean;
  reviewError: string | null;

  // Actions - Data
  setSubmissions: (submissions: QuestSubmission[]) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  setStatusFilter: (filter: StatusFilter) => void;

  // Actions - Review dialog
  openReview: (submission: QuestSubmission) => void;
  closeReview: () => void;
  setReviewNotes: (notes: string) => void;
  setIsSubmitting: (submitting: boolean) => void;
  setReviewError: (error: string | null) => void;

  reset: () => void;
}

const initialState = {
  submissions: [],
  isLoading: true,
  error: null,
  statusFilter: "pending" as StatusFilter,
  reviewOpen: false,
  selectedSubmission: null,
  reviewNotes: "",
  isSubmitting: false,
  reviewError: null,
};

export const useQuestSubmissionsStore = create<QuestSubmissionsState>()(
  devtools(
    (set) => ({
      ...initialState,

      // Data actions
      setSubmissions: (submissions) => set({ submissions }),
      setLoading: (isLoading) => set({ isLoading }),
      setError: (error) => set({ error, isLoading: false }),
      setStatusFilter: (statusFilter) => set({ statusFilter }),

      // Review dialog actions
      openReview: (submission) =>
        set({
          selectedSubmission: submission,
          reviewNotes: submission.reviewNotes ?? "",
          reviewError: null,
          reviewOpen: true,
        }),
      closeReview: () =>
        set({
          reviewOpen: false,
          selectedSubmission: null,
          reviewNotes: "",
          reviewError: null,
        }),
      setReviewNotes: (reviewNotes) => set({ reviewNotes }),
      setIsSubmitting: (isSubmitting) => set({ isSubmitting }),
      setReviewError: (reviewError) => set({ reviewError }),

      reset: () => set(initialState),
    }),
    { name: "quest-submissions-store" }
  )
);
