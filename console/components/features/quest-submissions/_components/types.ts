export interface QuestSubmission {
  id: string;
  userId: string;
  questId: string;
  status: string;
  proofUrl: string | null;
  proofText: string | null;
  screenshotUrl: string | null;
  reviewedBy: string | null;
  reviewNotes: string | null;
  submittedAt: string;
  reviewedAt: string | null;
  user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  quest: {
    id: string;
    slug: string;
    title: string;
    description: string;
    type: string;
    category: string;
    rewardPoints: number;
    rewardBadge: {
      id: string;
      name: string;
      imageUrl: string;
    } | null;
    requiredProof: string | null;
  };
}

export type StatusFilter = "all" | "pending" | "approved" | "rejected";

export function formatDateTime(dateString: string | null): string {
  if (!dateString) return "—";
  try {
    return new Date(dateString).toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "Invalid Date";
  }
}
