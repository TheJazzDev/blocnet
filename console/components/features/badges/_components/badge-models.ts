export interface BadgeModel {
  id: string;
  slug: string;
  name: string;
  description: string;
  imageUrl: string;
  category: string;
  rarity: string;
  pointsRequirement: number;
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
}

export interface UserSearchResult {
  id: string;
  email: string;
  displayName: string | null;
}

export interface AdminUsersSearchResponse {
  data: UserSearchResult[];
  total: number;
  limit: number;
  offset: number;
}

export const CATEGORIES = ["engagement", "mining", "social", "trust", "special"];
export const RARITIES = ["common", "rare", "epic", "legendary"];
const CATEGORY_ORDER = [...CATEGORIES];
const RARITY_POWER: Record<string, number> = {
  legendary: 4,
  epic: 3,
  rare: 2,
  common: 1,
};

export function toCategoryLabel(category: string) {
  return category
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function toLabel(value: string) {
  return value
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function formatBadgeDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function getRarityColor(rarity: string) {
  switch (rarity) {
    case "legendary":
      return "text-yellow-400";
    case "epic":
      return "text-purple-400";
    case "rare":
      return "text-blue-400";
    default:
      return "text-gray-400";
  }
}

export function groupBadgesByCategory(badges: BadgeModel[]) {
  const grouped = new Map<string, BadgeModel[]>();
  for (const badge of badges) {
    const key = badge.category?.trim().toLowerCase() || "uncategorized";
    const list = grouped.get(key);
    if (list) {
      list.push(badge);
    } else {
      grouped.set(key, [badge]);
    }
  }

  return [...grouped.entries()]
    .sort(([a], [b]) => {
      const aIndex = CATEGORY_ORDER.indexOf(a);
      const bIndex = CATEGORY_ORDER.indexOf(b);
      const resolvedA = aIndex === -1 ? Number.MAX_SAFE_INTEGER : aIndex;
      const resolvedB = bIndex === -1 ? Number.MAX_SAFE_INTEGER : bIndex;
      if (resolvedA !== resolvedB) return resolvedA - resolvedB;
      return a.localeCompare(b);
    })
    .map(([category, items]) => ({
      category,
      badges: [...items].sort((left, right) => {
        const leftPower = RARITY_POWER[left.rarity] ?? 0;
        const rightPower = RARITY_POWER[right.rarity] ?? 0;
        if (leftPower !== rightPower) return rightPower - leftPower;
        if (left.pointsRequirement !== right.pointsRequirement) {
          return right.pointsRequirement - left.pointsRequirement;
        }
        if (left.sortOrder !== right.sortOrder) return left.sortOrder - right.sortOrder;
        const createdAtDiff = new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime();
        if (createdAtDiff !== 0) return createdAtDiff;
        return left.name.localeCompare(right.name);
      }),
    }));
}
