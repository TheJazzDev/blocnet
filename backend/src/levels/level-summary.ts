import { Prisma } from '@prisma/client';

/**
 * Canonical Prisma select for a user's `currentLevel` relation.
 * Use inside any `Profile` select/include so every API surface returns the
 * same level shape.
 */
export const currentLevelSelect = {
  id: true,
  slug: true,
  name: true,
  description: true,
  iconUrl: true,
  level: true,
  requiredBnp: true,
  requiredComments: true,
  requiredDaysActive: true,
  requiredQuests: true,
  requiredUpdates: true,
  requiredProjects: true,
  color: true,
  isActive: true,
  sortOrder: true,
} satisfies Prisma.UserLevelSelect;

export type CurrentLevelRecord = Prisma.UserLevelGetPayload<{
  select: typeof currentLevelSelect;
}>;

export interface CurrentLevelDto {
  id: string;
  slug: string;
  name: string;
  description: string;
  iconUrl: string;
  level: number;
  /** BigInt serialized as a decimal string. */
  requiredBnp: string;
  requiredComments: number;
  requiredDaysActive: number;
  requiredQuests: number;
  requiredUpdates: number;
  requiredProjects: number;
  color: string | null;
  isActive: boolean;
  sortOrder: number;
}

/**
 * Maps a `currentLevel` relation row to the canonical API shape
 * (BigInt `requiredBnp` -> string). Returns `null` when the user has no level.
 */
export function toCurrentLevelDto(
  level: CurrentLevelRecord | null | undefined,
): CurrentLevelDto | null {
  if (!level) {
    return null;
  }

  return {
    id: level.id,
    slug: level.slug,
    name: level.name,
    description: level.description,
    iconUrl: level.iconUrl,
    level: level.level,
    requiredBnp: level.requiredBnp.toString(),
    requiredComments: level.requiredComments,
    requiredDaysActive: level.requiredDaysActive,
    requiredQuests: level.requiredQuests,
    requiredUpdates: level.requiredUpdates,
    requiredProjects: level.requiredProjects,
    color: level.color,
    isActive: level.isActive,
    sortOrder: level.sortOrder,
  };
}
