import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  MiningPointSource,
  Prisma,
  Quest,
  QuestStatus,
  QuestVerificationStatus,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { generateUniqueSlug } from '../common/utils/slug.util';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateQuestDto } from './dto/create-quest.dto';
import { UpdateQuestDto } from './dto/update-quest.dto';
import {
  RevokeQuestSubmissionDto,
  SubmitQuestProofDto,
  VerifyQuestDto,
} from './dto/quest-action.dto';
import {
  QuestStorageService,
  UploadedQuestProofFile,
} from './quest-storage.service';

type PrismaLike = PrismaService | Prisma.TransactionClient;

type AutoQuestEligibilityResult = {
  eligible: boolean;
  current: number;
  target: number;
  metricLabel: string;
  missingRequirements: string[];
  message: string;
};

@Injectable()
export class QuestsService {
  private readonly logger = new Logger(QuestsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
    private readonly badgesService: BadgesService,
    private readonly notificationsService: NotificationsService,
    private readonly questStorageService: QuestStorageService,
    private readonly auditLogService: AuditLogService,
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
      where.OR = [{ expiresAt: null }, { expiresAt: { gt: new Date() } }];
    }

    return this.prisma.quest.findMany({
      where,
      orderBy: [
        { category: 'asc' },
        { sortOrder: 'asc' },
        { createdAt: 'asc' },
      ],
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

    const [userQuests, totalCount, completedCount, inProgressCount] =
      await Promise.all([
        this.prisma.userQuest.findMany({
          where,
          include: {
            quest: true,
          },
          orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
        }),
        this.prisma.userQuest.count({ where: { userId } }),
        this.prisma.userQuest.count({ where: { userId, status: 'completed' } }),
        this.prisma.userQuest.count({
          where: { userId, status: 'in_progress' },
        }),
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
    const userQuestMap = new Map(userQuests.map((uq) => [uq.questId, uq]));

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
  async submitQuestProof(
    userId: string,
    questSlug: string,
    dto: SubmitQuestProofDto,
  ) {
    const quest = await this.getQuestBySlug(questSlug);

    if (!quest.isActive) {
      throw new BadRequestException('This quest is not active');
    }

    if (quest.expiresAt && quest.expiresAt < new Date()) {
      throw new BadRequestException('This quest has expired');
    }

    if (quest.verificationMethod !== 'manual') {
      throw new BadRequestException(
        'This quest is auto-verified. Tap Verify instead.',
      );
    }

    if (!dto.screenshot?.trim()) {
      throw new BadRequestException(
        'Please upload a screenshot image as proof.',
      );
    }

    const existing = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
    });

    if (existing?.status === 'completed') {
      throw new BadRequestException('Quest already completed');
    }

    if (existing?.status === 'pending_verification') {
      throw new BadRequestException(
        'Your previous submission is still pending verification.',
      );
    }

    const now = new Date();
    const userQuest = await this.prisma.userQuest.upsert({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
      update: {
        status: 'in_progress',
        startedAt: existing?.startedAt ?? now,
      },
      create: {
        userId,
        questId: quest.id,
        status: 'in_progress',
        startedAt: now,
        progress: 0,
      },
    });

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
        progress: 100,
      },
    });

    return submission;
  }

  async uploadQuestProofImage(
    userId: string,
    questSlug: string,
    file: UploadedQuestProofFile,
  ) {
    const quest = await this.getQuestBySlug(questSlug);
    if (quest.verificationMethod !== 'manual') {
      throw new BadRequestException(
        'Only manual quests accept screenshot proof uploads.',
      );
    }
    if (!quest.isActive) {
      throw new BadRequestException('This quest is not active');
    }
    if (quest.expiresAt && quest.expiresAt < new Date()) {
      throw new BadRequestException('This quest has expired');
    }

    const screenshotUrl = await this.questStorageService.uploadProofImage(
      userId,
      quest.id,
      file,
    );

    return { screenshotUrl };
  }

  /**
   * Verify quest completion (for auto-verified quests)
   */
  async verifyQuest(userId: string, questSlug: string) {
    const quest = await this.getQuestBySlug(questSlug);

    if (!quest.isActive) {
      throw new BadRequestException('This quest is not active');
    }

    if (quest.expiresAt && quest.expiresAt < new Date()) {
      throw new BadRequestException('This quest has expired');
    }

    if (quest.verificationMethod !== 'auto') {
      throw new BadRequestException(
        'This quest requires manual verification. Submit proof instead.',
      );
    }

    const existing = await this.prisma.userQuest.findUnique({
      where: {
        userId_questId: {
          userId,
          questId: quest.id,
        },
      },
    });

    if (existing?.status === 'completed') {
      return {
        questId: quest.id,
        questSlug: quest.slug,
        eligible: true,
        completed: true,
        alreadyCompleted: true,
        rewardPoints: quest.rewardPoints,
        progress: {
          current: 1,
          target: 1,
          metricLabel: 'verification checks',
        },
        missingRequirements: [],
        message: 'Quest already completed.',
      };
    }

    const eligibility = await this.evaluateAutoQuestEligibility(userId, quest);
    if (!eligibility.eligible) {
      return {
        questId: quest.id,
        questSlug: quest.slug,
        eligible: false,
        completed: false,
        alreadyCompleted: false,
        rewardPoints: quest.rewardPoints,
        progress: {
          current: eligibility.current,
          target: eligibility.target,
          metricLabel: eligibility.metricLabel,
        },
        missingRequirements: eligibility.missingRequirements,
        message: eligibility.message,
      };
    }

    const completedNow = await this.completeAutoQuest(userId, quest);

    return {
      questId: quest.id,
      questSlug: quest.slug,
      eligible: true,
      completed: true,
      alreadyCompleted: !completedNow,
      rewardPoints: quest.rewardPoints,
      progress: {
        current: eligibility.target,
        target: eligibility.target,
        metricLabel: eligibility.metricLabel,
      },
      missingRequirements: [],
      message: completedNow
        ? `Quest verified. You earned ${quest.rewardPoints} BNP.`
        : 'Quest already completed.',
    };
  }

  /**
   * Claim quest reward (for auto-verified quests)
   */
  async claimQuestReward(userId: string, questSlug: string) {
    const result = await this.verifyQuest(userId, questSlug);
    if (!result.eligible) {
      throw new BadRequestException(result.message);
    }
    return result;
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

    const created = await this.prisma.quest.create({
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

    await this.auditLogService.create({
      actorId: adminId,
      action: 'quest.create',
      resourceType: 'quest',
      resourceId: created.id,
      metadata: {
        slug: created.slug,
        title: created.title,
        category: created.category,
        verificationMethod: created.verificationMethod,
        rewardPoints: created.rewardPoints,
      },
    });

    return created;
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

    const updated = await this.prisma.quest.update({
      where: { id: questId },
      data: {
        ...(nextSlug && { slug: nextSlug }),
        ...(dto.title && { title: dto.title }),
        ...(dto.description && { description: dto.description }),
        ...(dto.type && { type: dto.type }),
        ...(dto.category && { category: dto.category }),
        ...(dto.rewardPoints !== undefined && {
          rewardPoints: dto.rewardPoints,
        }),
        ...(dto.rewardBadgeId !== undefined && {
          rewardBadgeId: dto.rewardBadgeId,
        }),
        ...(dto.targetUrl !== undefined && { targetUrl: dto.targetUrl }),
        ...(dto.targetAction !== undefined && {
          targetAction: dto.targetAction,
        }),
        ...(dto.verificationMethod && {
          verificationMethod: dto.verificationMethod,
        }),
        ...(dto.requiredProof !== undefined && {
          requiredProof: dto.requiredProof,
        }),
        ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
        ...(dto.expiresAt !== undefined && { expiresAt: dto.expiresAt }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });

    await this.auditLogService.create({
      actorId: adminId,
      action: 'quest.update',
      resourceType: 'quest',
      resourceId: updated.id,
      metadata: {
        previous: {
          slug: quest.slug,
          title: quest.title,
          category: quest.category,
          verificationMethod: quest.verificationMethod,
          rewardPoints: quest.rewardPoints,
          isActive: quest.isActive,
        },
        next: {
          slug: updated.slug,
          title: updated.title,
          category: updated.category,
          verificationMethod: updated.verificationMethod,
          rewardPoints: updated.rewardPoints,
          isActive: updated.isActive,
        },
      },
    });

    return updated;
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
  async verifyQuestSubmission(
    dto: VerifyQuestDto,
    verifiedBy: string,
    approved: boolean,
  ) {
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
      const result = await this.prisma.$transaction(async (tx) => {
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
            progress: 100,
          },
        });

        const quest = submission.userQuest.quest;
        const userId = submission.userId;
        await this.awardQuestRewards(tx, userId, quest, {
          submissionId: submission.id,
          awardedBy: verifiedBy,
        });

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
            body: `Your quest "${quest.title}" has been verified. You earned ${quest.rewardPoints} BNP!`,
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

      await this.auditLogService.create({
        actorId: verifiedBy,
        action: 'quest.submission.approve',
        resourceType: 'quest_submission',
        resourceId: submission.id,
        metadata: {
          userId: submission.userId,
          questId: submission.userQuest.quest.id,
          questSlug: submission.userQuest.quest.slug,
          reviewNotes: dto.reviewNotes,
        },
      });

      return result;
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
          progress: 0,
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

      await this.auditLogService.create({
        actorId: verifiedBy,
        action: 'quest.submission.reject',
        resourceType: 'quest_submission',
        resourceId: submission.id,
        metadata: {
          userId: submission.userId,
          questId: submission.userQuest.quest.id,
          questSlug: submission.userQuest.quest.slug,
          reviewNotes: dto.reviewNotes,
          rejectionReason,
        },
      });

      return { message: 'Quest submission rejected' };
    }
  }

  async revokeQuestSubmission(
    submissionId: string,
    revokedBy: string,
    dto: RevokeQuestSubmissionDto,
  ) {
    const reason =
      dto.revocationReason?.trim() || dto.reviewNotes?.trim() || null;
    if (!reason) {
      throw new BadRequestException('Revocation reason is required');
    }

    const submission = await this.prisma.questSubmission.findUnique({
      where: { id: submissionId },
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

    if (submission.verificationStatus !== QuestVerificationStatus.approved) {
      throw new BadRequestException('Only approved submissions can be revoked');
    }

    const rewards = await this.prisma.$transaction(async (tx) => {
      await tx.questSubmission.update({
        where: { id: submission.id },
        data: {
          verificationStatus: QuestVerificationStatus.rejected,
          verifiedBy: revokedBy,
          verifiedAt: new Date(),
          reviewNotes: dto.reviewNotes ?? reason,
          rejectionReason: reason,
        },
      });

      await tx.userQuest.update({
        where: { id: submission.userQuestId },
        data: {
          status: QuestStatus.in_progress,
          progress: 0,
          completedAt: null,
        },
      });

      return this.revokeQuestRewards(
        tx,
        submission.userId,
        submission.userQuest.quest,
        submission.id,
        reason,
      );
    });

    await this.notificationsService.notifyMany([
      {
        userId: submission.userId,
        type: 'quest_rejected',
        actorUserId: revokedBy,
        projectId: null,
        updateId: null,
        urgency: null,
        title: 'Quest Approval Revoked',
        body: `A previously approved submission for "${submission.userQuest.quest.title}" was revoked: ${reason}`,
        payload: {
          questId: submission.userQuest.quest.id,
          questSlug: submission.userQuest.quest.slug,
          revocationReason: reason,
          pointsReversed: rewards.pointsReversed,
        },
        deeplink: `blocnet://quests/${submission.userQuest.quest.slug}`,
        pushData: {
          type: 'quest_rejected',
          questId: submission.userQuest.quest.id,
        },
      },
    ]);

    await this.auditLogService.create({
      actorId: revokedBy,
      action: 'quest.submission.revoke',
      resourceType: 'quest_submission',
      resourceId: submission.id,
      metadata: {
        userId: submission.userId,
        questId: submission.userQuest.quest.id,
        questSlug: submission.userQuest.quest.slug,
        reviewNotes: dto.reviewNotes,
        revocationReason: reason,
        pointsReversed: rewards.pointsReversed,
        badgeRevoked: rewards.badgeRevoked,
      },
    });

    return {
      message: 'Quest approval revoked and rewards reversed',
      ...rewards,
    };
  }

  private async awardQuestRewards(
    tx: PrismaLike,
    userId: string,
    quest: Pick<
      Quest,
      'id' | 'slug' | 'title' | 'rewardPoints' | 'rewardBadgeId'
    >,
    options?: {
      submissionId?: string;
      awardedBy?: string;
    },
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
            ...(options?.submissionId
              ? { questSubmissionId: options.submissionId }
              : {}),
            ...(options?.awardedBy ? { awardedBy: options.awardedBy } : {}),
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

  private async revokeQuestRewards(
    tx: PrismaLike,
    userId: string,
    quest: Pick<
      Quest,
      'id' | 'slug' | 'title' | 'rewardPoints' | 'rewardBadgeId'
    >,
    submissionId: string,
    reason: string,
  ) {
    let pointsReversed = 0;
    let badgeRevoked = false;

    if (quest.rewardPoints > 0) {
      const rewardLedger = await tx.miningPointLedger.findFirst({
        where: {
          userId,
          source: MiningPointSource.quest_reward,
          points: { gt: 0 },
          OR: [
            { metadata: { path: ['questSubmissionId'], equals: submissionId } },
            { metadata: { path: ['questId'], equals: quest.id } },
          ],
        },
        orderBy: [{ createdAt: 'desc' }],
      });

      await tx.miningPointLedger.create({
        data: {
          userId,
          source: MiningPointSource.quest_reward,
          points: -Math.abs(quest.rewardPoints),
          metadata: {
            questId: quest.id,
            questSlug: quest.slug,
            questTitle: quest.title,
            questSubmissionId: submissionId,
            reason,
            kind: 'quest_reward_reversal',
            reversedLedgerId: rewardLedger?.id ?? null,
          },
        },
      });

      const profile = await tx.profile.findUnique({
        where: { id: userId },
        select: { miningClaimedPoints: true },
      });
      const currentPoints =
        typeof profile?.miningClaimedPoints === 'bigint'
          ? profile.miningClaimedPoints
          : BigInt(profile?.miningClaimedPoints ?? 0);
      const reversalAmount = BigInt(Math.abs(quest.rewardPoints));
      const nextPoints =
        currentPoints > reversalAmount ? currentPoints - reversalAmount : 0n;

      await tx.profile.update({
        where: { id: userId },
        data: {
          miningClaimedPoints: nextPoints,
        },
      });

      pointsReversed = Math.abs(quest.rewardPoints);
    }

    if (quest.rewardBadgeId) {
      const userBadge = await tx.userBadge.findUnique({
        where: {
          userId_badgeId: {
            userId,
            badgeId: quest.rewardBadgeId,
          },
        },
        select: {
          badgeId: true,
          metadata: true,
        },
      });

      if (userBadge && this.wasQuestBadgeAward(userBadge.metadata, quest.id)) {
        await tx.userBadge.delete({
          where: {
            userId_badgeId: {
              userId,
              badgeId: quest.rewardBadgeId,
            },
          },
        });

        const profile = await tx.profile.findUnique({
          where: { id: userId },
          select: { primaryBadgeId: true },
        });

        if (profile?.primaryBadgeId === quest.rewardBadgeId) {
          const fallbackBadge = await tx.userBadge.findFirst({
            where: { userId },
            orderBy: [{ earnedAt: 'desc' }],
            select: { badgeId: true },
          });

          await tx.profile.update({
            where: { id: userId },
            data: { primaryBadgeId: fallbackBadge?.badgeId ?? null },
          });
        }

        badgeRevoked = true;
      }
    }

    return { pointsReversed, badgeRevoked };
  }

  private wasQuestBadgeAward(
    metadata: Prisma.JsonValue | null,
    questId: string,
  ): boolean {
    if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
      return false;
    }

    const objectMetadata = metadata;
    return objectMetadata.questId === questId;
  }

  private async completeAutoQuest(
    userId: string,
    quest: Quest,
  ): Promise<boolean> {
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
        body: `You completed "${quest.title}" and earned ${quest.rewardPoints} BNP.`,
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

  private async evaluateAutoQuestEligibility(
    userId: string,
    quest: Quest,
  ): Promise<AutoQuestEligibilityResult> {
    const action = (quest.targetAction ?? '').trim();
    switch (action) {
      case 'profile_complete': {
        const profile = await this.prisma.profile.findUnique({
          where: { id: userId },
          select: {
            displayName: true,
            username: true,
            avatarUrl: true,
            bio: true,
          },
        });
        const hasDisplayName = Boolean(profile?.displayName?.trim());
        const hasUsername = Boolean(profile?.username?.trim());
        const hasAvatar = Boolean(profile?.avatarUrl?.trim());
        const hasBio = Boolean(profile?.bio?.trim());
        const current = [hasDisplayName, hasUsername, hasAvatar, hasBio].filter(
          Boolean,
        ).length;
        const missingRequirements: string[] = [];
        if (!hasDisplayName) {
          missingRequirements.push('Add a display name to your profile.');
        }
        if (!hasUsername) {
          missingRequirements.push('Add a username to your profile.');
        }
        if (!hasAvatar) {
          missingRequirements.push('Add a profile picture.');
        }
        if (!hasBio) {
          missingRequirements.push('Add a bio to your profile.');
        }
        const eligible = current >= 4;
        return {
          eligible,
          current,
          target: 4,
          metricLabel: 'profile fields',
          missingRequirements,
          message: eligible
            ? 'Profile requirements met.'
            : 'Complete display name, username, profile picture, and bio to verify this quest.',
        };
      }
      case 'follow_5_projects': {
        const current = await this.prisma.projectFollow.count({
          where: { userId },
        });
        const target = 5;
        const eligible = current >= target;
        const remaining = Math.max(target - current, 0);
        return {
          eligible,
          current,
          target,
          metricLabel: 'projects followed',
          missingRequirements: eligible
            ? []
            : [
                `Follow ${remaining} more project${remaining == 1 ? '' : 's'} to verify this quest.`,
              ],
          message: eligible
            ? 'Follow requirement met.'
            : 'You have not followed enough projects yet.',
        };
      }
      case 'first_comment': {
        const current = await this.prisma.comment.count({
          where: {
            authorId: userId,
            status: 'active',
          },
        });
        const eligible = current >= 1;
        return {
          eligible,
          current: Math.min(current, 1),
          target: 1,
          metricLabel: 'comments made',
          missingRequirements: eligible
            ? []
            : ['Make at least one comment on an update.'],
          message: eligible
            ? 'Comment requirement met.'
            : 'You need to post your first comment.',
        };
      }
      case 'first_update': {
        const current = await this.prisma.update.count({
          where: {
            authorId: userId,
            status: 'published',
          },
        });
        const eligible = current >= 1;
        return {
          eligible,
          current: Math.min(current, 1),
          target: 1,
          metricLabel: 'updates posted',
          missingRequirements: eligible
            ? []
            : ['Create and publish your first update.'],
          message: eligible
            ? 'Update requirement met.'
            : 'You need to create your first update.',
        };
      }
      case '7_day_streak': {
        const current = await this.getClaimStreakUtcDays(userId);
        const target = 7;
        const eligible = current >= target;
        const remaining = Math.max(target - current, 0);
        return {
          eligible,
          current: Math.min(current, target),
          target,
          metricLabel: 'streak days',
          missingRequirements: eligible
            ? []
            : [
                `Claim mining rewards for ${remaining} more day${remaining == 1 ? '' : 's'} in a row.`,
              ],
          message: eligible
            ? 'Streak requirement met.'
            : 'You have not reached a 7-day streak yet.',
        };
      }
      case 'refer_3_miners': {
        const current = await this.prisma.profile.count({
          where: {
            referredById: userId,
            miningSessions: {
              some: {},
            },
          },
        });
        const target = 3;
        const eligible = current >= target;
        const remaining = Math.max(target - current, 0);
        return {
          eligible,
          current: Math.min(current, target),
          target,
          metricLabel: 'active referrals',
          missingRequirements: eligible
            ? []
            : [
                `Refer ${remaining} more active miner${remaining == 1 ? '' : 's'} to verify this quest.`,
              ],
          message: eligible
            ? 'Referral requirement met.'
            : 'You do not have enough active referrals yet.',
        };
      }
      default:
        return {
          eligible: false,
          current: 0,
          target: 1,
          metricLabel: 'verification checks',
          missingRequirements: [
            'This quest cannot be auto-verified yet. Please contact support.',
          ],
          message: 'Auto-verification rule is not configured for this quest.',
        };
    }
  }

  private async getClaimStreakUtcDays(userId: string): Promise<number> {
    const rows = await this.prisma.miningPointLedger.findMany({
      where: {
        userId,
        source: MiningPointSource.cycle_claim,
      },
      orderBy: { createdAt: 'desc' },
      take: 30,
      select: { createdAt: true },
    });

    if (rows.length === 0) {
      return 0;
    }

    const uniqueDays: number[] = [];
    for (const row of rows) {
      const day = this.toUtcDayNumber(row.createdAt);
      if (
        uniqueDays.length === 0 ||
        uniqueDays[uniqueDays.length - 1] !== day
      ) {
        uniqueDays.push(day);
      }
    }

    if (uniqueDays.length === 0) {
      return 0;
    }

    let streak = 1;
    for (let i = 1; i < uniqueDays.length; i += 1) {
      if (uniqueDays[i - 1] - 1 === uniqueDays[i]) {
        streak += 1;
        continue;
      }
      break;
    }

    return streak;
  }

  private toUtcDayNumber(date: Date): number {
    return Math.floor(
      Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()) /
        86_400_000,
    );
  }
}
