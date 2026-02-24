import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import {
  MiningPointSource,
  Prisma,
  Quest,
  QuestStatus,
  QuestVerificationStatus,
} from '@prisma/client';
import { BadgesService } from '../badges/badges.service';
import { generateUniqueSlug } from '../common/utils/slug.util';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateQuestDto } from './dto/create-quest.dto';
import { UpdateQuestDto } from './dto/update-quest.dto';
import { SubmitQuestProofDto, VerifyQuestDto } from './dto/quest-action.dto';

type PrismaLike = PrismaService | Prisma.TransactionClient;

@Injectable()
export class QuestsService {
  private readonly logger = new Logger(QuestsService.name);

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
      const completedAt = new Date();

      // Mark quest as completed
      const completedRows = await tx.userQuest.updateMany({
        where: {
          id: userQuest.id,
          status: { not: 'completed' },
        },
        data: {
          status: 'completed',
          completedAt,
        },
      });
      if (completedRows.count === 0) {
        throw new ConflictException('Quest already completed');
      }

      const completedQuest = await tx.userQuest.findUniqueOrThrow({
        where: { id: userQuest.id },
        include: { quest: true },
      });

      await this.awardQuestRewards(tx, userId, quest);

      return completedQuest;
    });
  }

  /**
   * Admin: Create a new quest
   */
  async createQuest(dto: CreateQuestDto, adminId: string) {
    const slug = await generateUniqueSlug({
      source: dto.title,
      desiredSlug: dto.slug,
      fallback: 'quest',
      exists: async (candidate) => {
        const existing = await this.prisma.quest.findUnique({
          where: { slug: candidate },
          select: { id: true },
        });
        return Boolean(existing);
      },
    });

    return this.prisma.quest.create({
      data: {
        slug,
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
   * Admin: Update an existing quest
   */
  async updateQuest(questId: string, dto: UpdateQuestDto, adminId: string) {
    const quest = await this.prisma.quest.findUnique({
      where: { id: questId },
    });

    if (!quest) {
      throw new NotFoundException(`Quest with ID "${questId}" not found`);
    }

    let nextSlug: string | undefined;
    if (dto.title !== undefined && dto.title !== quest.title) {
      nextSlug = await generateUniqueSlug({
        source: dto.title,
        fallback: 'quest',
        exists: async (candidate) => {
          const existing = await this.prisma.quest.findFirst({
            where: {
              slug: candidate,
              NOT: { id: questId },
            },
            select: { id: true },
          });
          return Boolean(existing);
        },
      });
    }

    return this.prisma.quest.update({
      where: { id: questId },
      data: {
        ...(nextSlug && { slug: nextSlug }),
        ...(dto.title && { title: dto.title }),
        ...(dto.description && { description: dto.description }),
        ...(dto.type && { type: dto.type }),
        ...(dto.category && { category: dto.category }),
        ...(dto.rewardPoints !== undefined && { rewardPoints: dto.rewardPoints }),
        ...(dto.rewardBadgeId !== undefined && { rewardBadgeId: dto.rewardBadgeId }),
        ...(dto.targetUrl !== undefined && { targetUrl: dto.targetUrl }),
        ...(dto.targetAction !== undefined && { targetAction: dto.targetAction }),
        ...(dto.verificationMethod && { verificationMethod: dto.verificationMethod }),
        ...(dto.requiredProof !== undefined && { requiredProof: dto.requiredProof }),
        ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
        ...(dto.expiresAt !== undefined && { expiresAt: dto.expiresAt }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });
  }

  /**
   * Admin: Get all quest submissions pending verification
   */
  async getPendingSubmissions(limit = 50, offset = 0) {
    return this.getSubmissionsByStatus('pending', limit, offset);
  }

  /**
   * Admin: Get quest submissions by status
   */
  async getSubmissionsByStatus(status: string, limit = 50, offset = 0) {
    const normalizedStatus = status.toLowerCase();
    const where: Prisma.QuestSubmissionWhereInput = {};
    if (normalizedStatus !== 'all') {
      if (
        normalizedStatus !== QuestVerificationStatus.pending &&
        normalizedStatus !== QuestVerificationStatus.approved &&
        normalizedStatus !== QuestVerificationStatus.rejected
      ) {
        throw new BadRequestException(
          `Invalid submission status "${status}". Expected one of: all, pending, approved, rejected`,
        );
      }
      where.verificationStatus = normalizedStatus;
    }

    const submissions = await this.prisma.questSubmission.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            displayName: true,
            avatarUrl: true,
          },
        },
        userQuest: {
          include: {
            quest: true,
          },
        },
      },
      orderBy: { submittedAt: 'desc' },
      take: limit,
      skip: offset,
    });

    const rewardBadgeIds = Array.from(
      new Set(
        submissions
          .map((submission) => submission.userQuest.quest.rewardBadgeId)
          .filter((badgeId): badgeId is string => Boolean(badgeId)),
      ),
    );

    const badgesById = new Map<
      string,
      {
        id: string;
        name: string;
        imageUrl: string;
      }
    >();

    if (rewardBadgeIds.length > 0) {
      const badges = await this.prisma.badge.findMany({
        where: { id: { in: rewardBadgeIds } },
        select: {
          id: true,
          name: true,
          imageUrl: true,
        },
      });

      for (const badge of badges) {
        badgesById.set(badge.id, badge);
      }
    }

    // Transform the response to match frontend expectations
    return submissions.map((submission) => ({
      id: submission.id,
      userId: submission.userId,
      questId: submission.userQuest.questId,
      status: submission.verificationStatus,
      proofUrl: submission.proofUrl,
      proofText: submission.proofText,
      screenshotUrl: submission.screenshot,
      reviewedBy: submission.verifiedBy,
      reviewNotes: submission.reviewNotes ?? submission.rejectionReason,
      submittedAt: submission.submittedAt.toISOString(),
      reviewedAt: submission.verifiedAt?.toISOString() ?? null,
      user: submission.user,
      quest: {
        id: submission.userQuest.quest.id,
        slug: submission.userQuest.quest.slug,
        title: submission.userQuest.quest.title,
        description: submission.userQuest.quest.description,
        type: submission.userQuest.quest.type,
        category: submission.userQuest.quest.category,
        rewardPoints: submission.userQuest.quest.rewardPoints,
        rewardBadge: submission.userQuest.quest.rewardBadgeId
          ? (badgesById.get(submission.userQuest.quest.rewardBadgeId) ?? null)
          : null,
        requiredProof: submission.userQuest.quest.requiredProof,
      },
    }));
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
            reviewNotes: dto.reviewNotes,
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
        await this.awardQuestRewards(tx, userId, quest);

        // Send notification
        await this.notificationsService.notifyMany([
          {
            userId,
            type: 'quest_verified',
            actorUserId: verifiedBy,
            projectId: null,
            updateId: null,
            urgency: null,
            title: 'Quest Completed!',
            body: `Your quest "${quest.title}" has been verified. You earned ${quest.rewardPoints} points!`,
            payload: {
              questId: quest.id,
              questSlug: quest.slug,
              rewardPoints: quest.rewardPoints,
            },
            deeplink: `blocnet://quests/${quest.slug}`,
            pushData: {
              type: 'quest_verified',
              questId: quest.id,
            },
          },
        ]);

        return { message: 'Quest verified and rewards awarded' };
      });
    } else {
      const rejectionReason =
        dto.rejectionReason?.trim() || dto.reviewNotes?.trim() || null;

      // Reject submission
      await this.prisma.questSubmission.update({
        where: { id: submission.id },
        data: {
          verificationStatus: 'rejected',
          verifiedBy,
          verifiedAt: new Date(),
          reviewNotes: dto.reviewNotes,
          rejectionReason,
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
      await this.notificationsService.notifyMany([
        {
          userId: submission.userId,
          type: 'quest_rejected',
          actorUserId: verifiedBy,
          projectId: null,
          updateId: null,
          urgency: null,
          title: 'Quest Submission Rejected',
          body:
            rejectionReason ||
            'Your quest submission was rejected. Please try again.',
          payload: {
            questId: submission.userQuest.quest.id,
            questSlug: submission.userQuest.quest.slug,
            rejectionReason,
          },
          deeplink: `blocnet://quests/${submission.userQuest.quest.slug}`,
          pushData: {
            type: 'quest_rejected',
            questId: submission.userQuest.quest.id,
          },
        },
      ]);

      return { message: 'Quest submission rejected' };
    }
  }

  private async awardQuestRewards(
    tx: PrismaLike,
    userId: string,
    quest: Pick<Quest, 'id' | 'slug' | 'title' | 'rewardPoints' | 'rewardBadgeId'>,
  ) {
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
  }

  private async completeAutoQuest(userId: string, quest: Quest): Promise<boolean> {
    const completedAt = new Date();

    const completed = await this.prisma.$transaction(async (tx) => {
      await tx.userQuest.upsert({
        where: {
          userId_questId: {
            userId,
            questId: quest.id,
          },
        },
        update: {},
        create: {
          userId,
          questId: quest.id,
          status: 'in_progress',
          startedAt: completedAt,
          progress: 100,
        },
      });

      const marked = await tx.userQuest.updateMany({
        where: {
          userId,
          questId: quest.id,
          status: { not: 'completed' },
        },
        data: {
          status: 'completed',
          completedAt,
          progress: 100,
        },
      });

      if (marked.count === 0) {
        return false;
      }

      await this.awardQuestRewards(tx, userId, quest);
      return true;
    });

    if (!completed) {
      return false;
    }

    await this.notificationsService.notifyMany([
      {
        userId,
        type: 'quest_verified',
        actorUserId: null,
        projectId: null,
        updateId: null,
        urgency: null,
        title: 'Quest Completed!',
        body: `You completed "${quest.title}" and earned ${quest.rewardPoints} points.`,
        payload: {
          questId: quest.id,
          questSlug: quest.slug,
          rewardPoints: quest.rewardPoints,
          autoCompleted: true,
        },
        deeplink: `blocnet://quests/${quest.slug}`,
        pushData: {
          type: 'quest_verified',
          questId: quest.id,
        },
      },
    ]);

    return true;
  }

  async checkAndCompleteByAction(userId: string, action: string) {
    const now = new Date();
    const quests = await this.prisma.quest.findMany({
      where: {
        isActive: true,
        verificationMethod: 'auto',
        targetAction: action,
        OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
      },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    });

    let completed = 0;
    for (const quest of quests) {
      try {
        if (await this.completeAutoQuest(userId, quest)) {
          completed += 1;
        }
      } catch (error) {
        this.logger.warn(
          `Auto quest completion failed`,
          JSON.stringify({
            action,
            userId,
            questId: quest.id,
            questSlug: quest.slug,
            error: error instanceof Error ? error.message : String(error),
          }),
        );
      }
    }

    return { checked: quests.length, completed };
  }

  /**
   * Internal helper kept for backward compatibility with slug-based triggers.
   */
  async checkAndCompleteQuest(userId: string, questSlug: string) {
    const quest = await this.prisma.quest.findUnique({
      where: { slug: questSlug },
    });
    if (!quest || !quest.isActive || quest.verificationMethod !== 'auto') {
      return null;
    }

    const completed = await this.completeAutoQuest(userId, quest);
    return completed ? { questId: quest.id, questSlug: quest.slug } : null;
  }
}
