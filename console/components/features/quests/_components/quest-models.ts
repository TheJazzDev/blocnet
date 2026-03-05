export interface QuestModel {
  id: string;
  slug: string;
  title: string;
  description: string;
  type: string;
  category: string;
  rewardPoints: number;
  rewardBadgeId: string | null;
  rewardBadge?: {
    id: string;
    name: string;
    imageUrl: string;
  } | null;
  targetUrl: string | null;
  targetAction: string | null;
  verificationMethod: string;
  requiredProof: string | null;
  isActive: boolean;
  sortOrder: number;
  expiresAt: string | null;
  createdAt: string;
}

export interface BadgeOption {
  id: string;
  name: string;
  slug: string;
}

export const QUEST_TYPES = [
  { value: "external_link", label: "External Link" },
  { value: "internal_action", label: "Internal Action" },
  { value: "social_media", label: "Social Media" },
];

export const QUEST_CATEGORIES = [
  { value: "special", label: "Special" },
  { value: "mining", label: "Mining" },
  { value: "engagement", label: "Engagement" },
  { value: "social", label: "Social" },
  { value: "trust", label: "Trust" },
];

export const VERIFICATION_METHODS = [
  { value: "auto", label: "Auto" },
  { value: "manual", label: "Manual" },
];

export const NONE_OPTION_VALUE = "__none__";

export function toQuestPayload(formData: FormData, includeStatus: boolean) {
  const payload: Record<string, unknown> = {
    title: formData.get("title"),
    description: formData.get("description"),
    type: formData.get("type"),
    category: formData.get("category"),
    rewardPoints: parseInt(formData.get("rewardPoints") as string, 10) || 0,
    verificationMethod: formData.get("verificationMethod"),
    targetUrl: formData.get("targetUrl") || null,
    targetAction: formData.get("targetAction") || null,
    requiredProof: formData.get("requiredProof") || null,
    expiresAt: formData.get("expiresAt") || null,
  };

  if (includeStatus) {
    payload.isActive = formData.get("isActive") === "true";
  }

  const rewardBadgeId = formData.get("rewardBadgeId") as string;
  if (rewardBadgeId && rewardBadgeId !== NONE_OPTION_VALUE) {
    payload.rewardBadgeId = rewardBadgeId;
  } else if (includeStatus) {
    payload.rewardBadgeId = null;
  }

  return payload;
}
