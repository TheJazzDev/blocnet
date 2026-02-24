import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MiningPointSource, Prisma, QuestStatus } from '@prisma/client';
import { BadgesService } from '../badges/badges.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateQuestDto } from './dto/create-quest.dto';
import { SubmitQuestProofDto, VerifyQuestDto } from './dto/quest-action.dto';

type PrismaLike = PrismaService | Prisma.TransactionClient;

@Injectable()
export class QuestsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly badgesService: BadgesService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Get all active quests
   */
  async getAllQuests(includeInactive = false) {
    const where: Prisma.QuestWhereInput = includeInactive
      ? {}
      : { isActive: true };

    // Filter out expired quests if not including inactive
    if (!includeInactive) {
      where.OR = [
        { expiresAt: null },
        { expiresAt: { gt: new Date() } },
      ];
    }

    return this.prisma.quest.findMany({
      where,
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
    });
  }

  /**
   * Get quest by slug
   */
  async getQuestBySlug(slug: string) {
    const quest = await this.prisma.quest.findUnique({
      where: { slug },
    });

    if (!quest) {
      throw new NotFoundException(`Quest with slug "${slug}" not found`);
    }

    return quest;
  }

  /**
   * Get user's quests with progress
   */
  async getUserQuests(userId: string, status?: QuestStatus) {
    const where: Prisma.UserQuestWhereInput = { userId };
    if (status) {
      where.status = status;
    }

    const [userQuests, totalCount, completedCount, inProgressCount] = await Promise.all([
      this.prisma.userQuest.findMany({
        where,
        include: {
          quest: true,
        },
        orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
      }),
      this.prisma.userQuest.count({ where: { userId } }),
      this.prisma.userQuest.count({ where: { userId, status: 'completed' } }),
      this.prisma.userQuest.count({ where: { userId, status: 'in_progress' } }),
    ]);

    return {
      quests: userQuests,
      totalCount,
      completedCount,
      inProgressCount,
    };
  }

  /**
   * Get all active quests with user progress
   */
  async getQuestsWithProgress(userId: string) {
    const [allQuests, userQuests] = await Promise.all([
      this.getAllQuests(),
      this.prisma.userQuest.findMany({
        where: { userId },
        include: { quest: true },
      }),
    ]);

    // Create a map of questId -> userQuest for easy lookup
    const userQuestMap = new Map(
      userQuests.map((uq) => [uq.questId, uq]),
    );

    // Merge quests with user progress
    return allQuests.map((quest) => {
      const userQuest = userQuestMap.get(quest.id);
      return {
        ...quest,
        userProgress: userQuest || null,
      };
    });
  }

  /**
   * Start a quest
   */
  async startQuest(userId: string, questSlug: string) {
    const quest = await this.getQuestBySlug(questSlug);

    // Check if quest is active and not expired
    if (!quest.isActive) {
      throw new BadRequestException('This quest is not active');
    }

    if (quest.expiresAt && quest.expiresAt < new Date()) {
      throw new BadRequestException('This quest has expired');
    }

    // Check if user already started this quest
    const existing = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Quest already started');
    }

    // Create user quest
    const userQuest = await this.prisma.userQuest.create({
      data: {
        userId,
        questId: quest.id,
        status: 'in_progress',
        startedAt: new Date(),
        progress: 0,
      },
      include: {
        quest: true,
      },
    });

    return userQuest;
  }

  /**
   * Submit quest proof for verification
   */
  async submitQuestProof(userId: string, questSlug: string, dto: SubmitQuestProofDto) {
    const quest = await this.getQuestBySlug(questSlug);

    // Get user quest
    const userQuest = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
    });

    if (!userQuest) {
      throw new BadRequestException('Quest not started. Please start the quest first.');
    }

    if (userQuest.status === 'completed') {
      throw new BadRequestException('Quest already completed');
    }

    // Create submission
    const submission = await this.prisma.questSubmission.create({
      data: {
        userQuestId: userQuest.id,
        userId,
        proofUrl: dto.proofUrl,
        proofText: dto.proofText,
        screenshot: dto.screenshot,
        verificationStatus: 'pending',
      },
    });

    // Update user quest status
    await this.prisma.userQuest.update({
      where: { id: userQuest.id },
      data: {
        status: 'pending_verification',
      },
    });

    return submission;
  }

  /**
   * Claim quest reward (for auto-verified quests)
   */
  async claimQuestReward(userId: string, questSlug: string) {
    const quest = await this.getQuestBySlug(questSlug);

    // Check if quest is auto-verified
    if (quest.verificationMethod !== 'auto') {
      throw new BadRequestException('This quest requires manual verification');
    }

    // Get user quest
    const userQuest = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
      include: { quest: true },
    });

    if (!userQuest) {
      throw new BadRequestException('Quest not started');
    }

    if (userQuest.status === 'completed') {
      throw new BadRequestException('Quest already completed');
    }

    // Award rewards in a transaction
    return this.prisma.$transaction(async (tx) => {
      // Mark quest as completed
      const completedQuest = await tx.userQuest.update({
        where: { id: userQuest.id },
        data: {
          status: 'completed',
          completedAt: new Date(),
        },
        include: { quest: true },
      });

      // Award points if any
      if (quest.rewardPoints > 0) {
        await tx.miningPointLedger.create({
          data: {
            userId,
            source: MiningPointSource.quest_reward,
            points: quest.rewardPoints,
            metadata: {
              questId: quest.id,
              questSlug: quest.slug,
              questTitle: quest.title,
            },
          },
        });

        // Update profile mining points
        await tx.profile.update({
          where: { id: userId },
          data: {
            miningClaimedPoints: {
              increment: BigInt(quest.rewardPoints),
            },
          },
        });
      }

      // Award badge if any
      if (quest.rewardBadgeId) {
        const badge = await tx.badge.findUnique({
          where: { id: quest.rewardBadgeId },
        });

        if (badge) {
          await this.badgesService.checkAndAwardBadge(
            userId,
            badge.slug,
            {
              questId: quest.id,
              questSlug: quest.slug,
            },
            tx,
          );
        }
      }

      return completedQuest;
    });
  }

  /**
   * Admin: Create a new quest
   */
  async createQuest(dto: CreateQuestDto, adminId: string) {
    // Check for duplicate slug
    const existing = await this.prisma.quest.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(`Quest with slug "${dto.slug}" already exists`);
    }

    return this.prisma.quest.create({
      data: {
        slug: dto.slug,
        title: dto.title,
        description: dto.description,
        type: dto.type,
        category: dto.category,
        rewardPoints: dto.rewardPoints || 0,
        rewardBadgeId: dto.rewardBadgeId,
        targetUrl: dto.targetUrl,
        targetAction: dto.targetAction,
        verificationMethod: dto.verificationMethod || 'manual',
        requiredProof: dto.requiredProof,
        sortOrder: dto.sortOrder || 0,
        expiresAt: dto.expiresAt,
        isActive: true,
      },
    });
  }

  /**
   * Admin: Get all quest submissions pending verification
   */
  async getPendingSubmissions(limit = 50, offset = 0) {
    const [submissions, total] = await Promise.all([
      this.prisma.questSubmission.findMany({
        where: {
          verificationStatus: 'pending',
        },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              username: true,
              displayName: true,
            },
          },
          userQuest: {
            include: {
              quest: true,
            },
          },
        },
        orderBy: { submittedAt: 'asc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.questSubmission.count({
        where: { verificationStatus: 'pending' },
      }),
    ]);

    return {
      submissions,
      total,
      limit,
      offset,
    };
  }

  /**
   * Admin: Verify/approve quest submission
   */
  async verifyQuestSubmission(dto: VerifyQuestDto, verifiedBy: string, approved: boolean) {
    const submission = await this.prisma.questSubmission.findUnique({
      where: { id: dto.submissionId },
      include: {
        userQuest: {
          include: {
            quest: true,
          },
        },
      },
    });

    if (!submission) {
      throw new NotFoundException('Submission not found');
    }

    if (submission.verificationStatus !== 'pending') {
      throw new BadRequestException('Submission already processed');
    }

    if (approved) {
      // Approve submission and award rewards
      return this.prisma.$transaction(async (tx) => {
        // Update submission
        await tx.questSubmission.update({
          where: { id: submission.id },
          data: {
            verificationStatus: 'approved',
            verifiedBy,
            verifiedAt: new Date(),
          },
        });

        // Mark quest as completed
        await tx.userQuest.update({
          where: { id: submission.userQuestId },
          data: {
            status: 'completed',
            completedAt: new Date(),
          },
        });

        const quest = submission.userQuest.quest;
        const userId = submission.userId;

        // Award points if any
        if (quest.rewardPoints > 0) {
          await tx.miningPointLedger.create({
            data: {
              userId,
              source: MiningPointSource.quest_reward,
              points: quest.rewardPoints,
              metadata: {
                questId: quest.id,
                questSlug: quest.slug,
                questTitle: quest.title,
              },
            },
          });

          await tx.profile.update({
            where: { id: userId },
            data: {
              miningClaimedPoints: {
                increment: BigInt(quest.rewardPoints),
              },
            },
          });
        }

        // Award badge if any
        if (quest.rewardBadgeId) {
          const badge = await tx.badge.findUnique({
            where: { id: quest.rewardBadgeId },
          });

          if (badge) {
            await this.badgesService.checkAndAwardBadge(
              userId,
              badge.slug,
              {
                questId: quest.id,
                questSlug: quest.slug,
              },
              tx,
            );
          }
        }

        // Send notification
        await this.notificationsService.create({
          userId,
          type: 'quest_verified',
          title: 'Quest Completed!',
          body: `Your quest "${quest.title}" has been verified. You earned ${quest.rewardPoints} points!`,
          payload: {
            questId: quest.id,
            questSlug: quest.slug,
            rewardPoints: quest.rewardPoints,
          },
          deeplink: `blocnet://quests/${quest.slug}`,
        });

        return { message: 'Quest verified and rewards awarded' };
      });
    } else {
      // Reject submission
      await this.prisma.questSubmission.update({
        where: { id: submission.id },
        data: {
          verificationStatus: 'rejected',
          verifiedBy,
          verifiedAt: new Date(),
          rejectionReason: dto.rejectionReason,
        },
      });

      // Update user quest back to in_progress
      await this.prisma.userQuest.update({
        where: { id: submission.userQuestId },
        data: {
          status: 'in_progress',
        },
      });

      // Send notification
      await this.notificationsService.create({
        userId: submission.userId,
        type: 'quest_rejected',
        title: 'Quest Submission Rejected',
        body: dto.rejectionReason || 'Your quest submission was rejected. Please try again.',
        payload: {
          questId: submission.userQuest.quest.id,
          questSlug: submission.userQuest.quest.slug,
          rejectionReason: dto.rejectionReason,
        },
        deeplink: `blocnet://quests/${submission.userQuest.quest.slug}`,
      });

      return { message: 'Quest submission rejected' };
    }
  }

  /**
   * Internal: Auto-complete quest based on action
   */
  async checkAndCompleteQuest(userId: string, questSlug: string) {
    const quest = await this.prisma.quest.findUnique({
      where: { slug: questSlug },
    });

    if (!quest || !quest.isActive || quest.verificationMethod !== 'auto') {
      return null;
    }

    // Check if user has this quest
    let userQuest = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
    });

    // If not started, start it
    if (!userQuest) {
      userQuest = await this.prisma.userQuest.create({
        data: {
          userId,
          questId: quest.id,
          status: 'in_progress',
          startedAt: new Date(),
        },
      });
    }

    // If already completed, return
    if (userQuest.status === 'completed') {
      return null;
    }

    // Complete the quest
    return this.claimQuestReward(userId, questSlug);
  }
}
