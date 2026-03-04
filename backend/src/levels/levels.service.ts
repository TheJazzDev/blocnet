import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserLevel, UserLevelProgress } from '@prisma/client';
import { LevelEventsService } from './level-events.service';

export interface UserMetrics {
  totalBnpEarned: bigint;
  totalComments: number;
  totalDaysActive: number;
  totalQuestsCompleted: number;
  totalUpdates: number;
  totalProjects: number;
}

@Injectable()
export class LevelsService {
  private readonly logger = new Logger(LevelsService.name);

  constructor(
    private prisma: PrismaService,
    private levelEvents: LevelEventsService,
  ) {}

  /**
   * Calculate user metrics from database
   */
  async getUserMetrics(userId: string): Promise<UserMetrics> {
    const [
      bnpTotal,
      commentsCount,
      questsCompleted,
      updatesCount,
      projectsCount,
      profile,
    ] = await Promise.all([
      // Total BNP earned (from mining ledger)
      this.prisma.miningPointLedger.aggregate({
        where: { userId },
        _sum: { points: true },
      }),
      // Total comments
      this.prisma.comment.count({
        where: { authorId: userId },
      }),
      // Total quests completed
      this.prisma.userQuest.count({
        where: {
          userId,
          status: 'completed',
        },
      }),
      // Total updates authored
      this.prisma.update.count({
        where: { authorId: userId },
      }),
      // Total projects owned
      this.prisma.project.count({
        where: { ownerAdminId: userId },
      }),
      // Profile for createdAt
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: { createdAt: true },
      }),
    ]);

    // Calculate days active (days since account creation)
    const daysActive = profile
      ? Math.floor(
          (Date.now() - profile.createdAt.getTime()) / (1000 * 60 * 60 * 24),
        )
      : 0;

    return {
      totalBnpEarned: BigInt(bnpTotal._sum.points || 0),
      totalComments: commentsCount,
      totalDaysActive: daysActive,
      totalQuestsCompleted: questsCompleted,
      totalUpdates: updatesCount,
      totalProjects: projectsCount,
    };
  }

  /**
   * Check if user qualifies for a specific level
   */
  private qualifiesForLevel(
    metrics: UserMetrics,
    level: UserLevel,
  ): boolean {
    return (
      metrics.totalBnpEarned >= level.requiredBnp &&
      metrics.totalComments >= level.requiredComments &&
      metrics.totalDaysActive >= level.requiredDaysActive &&
      metrics.totalQuestsCompleted >= level.requiredQuests &&
      metrics.totalUpdates >= level.requiredUpdates &&
      metrics.totalProjects >= level.requiredProjects
    );
  }

  /**
   * Calculate the appropriate level for a user based on their metrics
   */
  async calculateUserLevel(userId: string): Promise<UserLevel> {
    const metrics = await this.getUserMetrics(userId);

    // Get all active levels, sorted by level descending (highest first)
    const levels = await this.prisma.userLevel.findMany({
      where: { isActive: true },
      orderBy: { level: 'desc' },
    });

    // Find the highest level the user qualifies for
    for (const level of levels) {
      if (this.qualifiesForLevel(metrics, level)) {
        return level;
      }
    }

    // Fallback to level 1 if no qualification found
    const defaultLevel = await this.prisma.userLevel.findFirst({
      where: { level: 1, isActive: true },
    });

    if (!defaultLevel) {
      throw new Error('Level 1 not found in database');
    }

    return defaultLevel;
  }

  /**
   * Update or create user level progress
   */
  async updateUserLevel(userId: string): Promise<{
    levelChanged: boolean;
    previousLevel: UserLevel | null;
    currentLevel: UserLevel;
    progress: UserLevelProgress;
  }> {
    const metrics = await this.getUserMetrics(userId);
    const newLevel = await this.calculateUserLevel(userId);

    // Get existing progress
    const existingProgress = await this.prisma.userLevelProgress.findUnique({
      where: { userId },
      include: { currentLevel: true },
    });

    const previousLevel = existingProgress?.currentLevel || null;
    const levelChanged =
      !previousLevel || previousLevel.level !== newLevel.level;

    // Upsert progress
    const progress = await this.prisma.userLevelProgress.upsert({
      where: { userId },
      update: {
        currentLevelId: newLevel.id,
        achievedAt: levelChanged ? new Date() : existingProgress?.achievedAt,
        totalBnpEarned: metrics.totalBnpEarned,
        totalComments: metrics.totalComments,
        totalDaysActive: metrics.totalDaysActive,
        totalQuestsCompleted: metrics.totalQuestsCompleted,
        totalUpdates: metrics.totalUpdates,
        totalProjects: metrics.totalProjects,
        lastRecalculatedAt: new Date(),
      },
      create: {
        userId,
        currentLevelId: newLevel.id,
        totalBnpEarned: metrics.totalBnpEarned,
        totalComments: metrics.totalComments,
        totalDaysActive: metrics.totalDaysActive,
        totalQuestsCompleted: metrics.totalQuestsCompleted,
        totalUpdates: metrics.totalUpdates,
        totalProjects: metrics.totalProjects,
      },
    });

    // Update profile's currentLevelId
    await this.prisma.profile.update({
      where: { id: userId },
      data: { currentLevelId: newLevel.id },
    });

    if (levelChanged) {
      this.logger.log(
        `User ${userId} level changed: ${previousLevel?.level || 0} → ${newLevel.level}`,
      );

      // Emit level-up event for notifications
      await this.levelEvents.emitLevelUp({
        userId,
        previousLevel,
        newLevel,
        timestamp: new Date(),
      });
    }

    return {
      levelChanged,
      previousLevel,
      currentLevel: newLevel,
      progress,
    };
  }

  /**
   * Get user's current level with progress to next level
   */
  async getUserLevelWithProgress(userId: string): Promise<{
    currentLevel: UserLevel;
    progress: UserLevelProgress;
    nextLevel: UserLevel | null;
    progressToNext: {
      bnp: { current: bigint; required: bigint; percentage: number };
      comments: { current: number; required: number; percentage: number };
      daysActive: { current: number; required: number; percentage: number };
      quests: { current: number; required: number; percentage: number };
      updates: { current: number; required: number; percentage: number };
      projects: { current: number; required: number; percentage: number };
    } | null;
  }> {
    const progressData = await this.prisma.userLevelProgress.findUnique({
      where: { userId },
      include: { currentLevel: true },
    });

    if (!progressData) {
      // User has no level progress yet, initialize them
      const result = await this.updateUserLevel(userId);
      return this.getUserLevelWithProgress(userId); // Recursive call after initialization
    }

    const nextLevel = await this.prisma.userLevel.findFirst({
      where: {
        level: progressData.currentLevel.level + 1,
        isActive: true,
      },
    });

    let progressToNext: {
      bnp: { current: bigint; required: bigint; percentage: number };
      comments: { current: number; required: number; percentage: number };
      daysActive: { current: number; required: number; percentage: number };
      quests: { current: number; required: number; percentage: number };
      updates: { current: number; required: number; percentage: number };
      projects: { current: number; required: number; percentage: number };
    } | null = null;

    if (nextLevel) {
      const calculatePercentage = (
        current: number | bigint,
        required: number | bigint,
      ): number => {
        const curr = Number(current);
        const req = Number(required);
        if (req === 0) return 100;
        return Math.min(100, Math.floor((curr / req) * 100));
      };

      progressToNext = {
        bnp: {
          current: progressData.totalBnpEarned,
          required: nextLevel.requiredBnp,
          percentage: calculatePercentage(
            progressData.totalBnpEarned,
            nextLevel.requiredBnp,
          ),
        },
        comments: {
          current: progressData.totalComments,
          required: nextLevel.requiredComments,
          percentage: calculatePercentage(
            progressData.totalComments,
            nextLevel.requiredComments,
          ),
        },
        daysActive: {
          current: progressData.totalDaysActive,
          required: nextLevel.requiredDaysActive,
          percentage: calculatePercentage(
            progressData.totalDaysActive,
            nextLevel.requiredDaysActive,
          ),
        },
        quests: {
          current: progressData.totalQuestsCompleted,
          required: nextLevel.requiredQuests,
          percentage: calculatePercentage(
            progressData.totalQuestsCompleted,
            nextLevel.requiredQuests,
          ),
        },
        updates: {
          current: progressData.totalUpdates,
          required: nextLevel.requiredUpdates,
          percentage: calculatePercentage(
            progressData.totalUpdates,
            nextLevel.requiredUpdates,
          ),
        },
        projects: {
          current: progressData.totalProjects,
          required: nextLevel.requiredProjects,
          percentage: calculatePercentage(
            progressData.totalProjects,
            nextLevel.requiredProjects,
          ),
        },
      };
    }

    return {
      currentLevel: progressData.currentLevel,
      progress: progressData,
      nextLevel,
      progressToNext,
    };
  }

  /**
   * Get all levels
   */
  async getAllLevels(): Promise<UserLevel[]> {
    return this.prisma.userLevel.findMany({
      where: { isActive: true },
      orderBy: { level: 'asc' },
    });
  }

  /**
   * Get level by ID
   */
  async getLevelById(id: string): Promise<UserLevel | null> {
    return this.prisma.userLevel.findUnique({
      where: { id },
    });
  }

  /**
   * Admin: Update level configuration
   */
  async updateLevelConfig(
    id: string,
    data: Partial<
      Omit<UserLevel, 'id' | 'createdAt' | 'updatedAt'>
    >,
  ): Promise<UserLevel> {
    return this.prisma.userLevel.update({
      where: { id },
      data: {
        ...data,
        updatedAt: new Date(),
      },
    });
  }

  /**
   * Get leaderboard (top users by level)
   */
  async getLeaderboard(limit: number = 100): Promise<any[]> {
    const topUsers = await this.prisma.userLevelProgress.findMany({
      take: limit,
      orderBy: [
        { currentLevel: { level: 'desc' } },
        { totalBnpEarned: 'desc' },
      ],
      include: {
        user: {
          select: {
            id: true,
            username: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        currentLevel: true,
      },
    });

    return topUsers.map((entry, index) => ({
      rank: index + 1,
      user: entry.user,
      level: entry.currentLevel,
      metrics: {
        totalBnpEarned: entry.totalBnpEarned.toString(),
        totalComments: entry.totalComments,
        totalDaysActive: entry.totalDaysActive,
        totalQuestsCompleted: entry.totalQuestsCompleted,
      },
      achievedAt: entry.achievedAt,
    }));
  }
}
