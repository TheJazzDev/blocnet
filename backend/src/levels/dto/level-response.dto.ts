import { UserLevel } from '@prisma/client';

export class LevelResponseDto {
  id: string;
  slug: string;
  name: string;
  description: string;
  iconUrl: string;
  level: number;
  requiredBnp: string;
  requiredComments: number;
  requiredDaysActive: number;
  requiredQuests: number;
  requiredUpdates: number;
  requiredProjects: number;
  color: string | null;
  isActive: boolean;
  sortOrder: number;

  static fromEntity(level: UserLevel): LevelResponseDto {
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
}

export class UserLevelProgressDto {
  currentLevel: LevelResponseDto;
  nextLevel: LevelResponseDto | null;
  achievedAt: Date;
  metrics: {
    totalBnpEarned: string;
    totalComments: number;
    totalDaysActive: number;
    totalQuestsCompleted: number;
    totalUpdates: number;
    totalProjects: number;
  };
  progressToNext: {
    bnp: { current: string; required: string; percentage: number };
    comments: { current: number; required: number; percentage: number };
    daysActive: { current: number; required: number; percentage: number };
    quests: { current: number; required: number; percentage: number };
    updates: { current: number; required: number; percentage: number };
    projects: { current: number; required: number; percentage: number };
  } | null;
}

export class LeaderboardEntryDto {
  rank: number;
  user: {
    id: string;
    username: string | null;
    displayName: string | null;
    avatarUrl: string | null;
  };
  level: LevelResponseDto;
  metrics: {
    totalBnpEarned: string;
    totalComments: number;
    totalDaysActive: number;
    totalQuestsCompleted: number;
  };
  achievedAt: Date;
}
