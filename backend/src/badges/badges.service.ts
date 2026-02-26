import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Badge, BadgeCategory, BadgeRarity, Prisma } from '@prisma/client';
import { generateUniqueSlug } from '../common/utils/slug.util';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { GrantBadgeDto } from './dto/grant-badge.dto';
import { UpdateBadgeDto } from './dto/update-badge.dto';

type PrismaLike = PrismaService | Prisma.TransactionClient;
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Injectable()
export class BadgesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Get all active badges
   */
  async getAllBadges(includeInactive = false) {
    const where: Prisma.BadgeWhereInput = includeInactive
      ? {}
      : { isActive: true };

    return this.prisma.badge.findMany({
      where,
      orderBy: [
        { category: 'asc' },
        { sortOrder: 'asc' },
        { createdAt: 'asc' },
      ],
    });
  }

  /**
   * Get badge by slug
   */
  async getBadgeBySlug(slug: string): Promise<Badge> {
    const badge = await this.prisma.badge.findUnique({
      where: { slug },
    });

    if (!badge) {
      throw new NotFoundException(`Badge with slug "${slug}" not found`);
    }

    return badge;
  }

  /**
   * Get badge by ID
   */
  async getBadgeById(badgeId: string): Promise<Badge> {
    const badge = await this.prisma.badge.findUnique({
      where: { id: badgeId },
    });

    if (!badge) {
      throw new NotFoundException(`Badge with ID "${badgeId}" not found`);
    }

    return badge;
  }

  /**
   * Get all badges earned by a user
   */
  async getUserBadges(userId: string) {
    const [userBadges, profile] = await Promise.all([
      this.prisma.userBadge.findMany({
        where: { userId },
        include: {
          badge: true,
          grantor: {
            select: {
              id: true,
              displayName: true,
              username: true,
            },
          },
        },
        orderBy: { earnedAt: 'desc' },
      }),
      this.prisma.profile.findUnique({
        where: { id: userId },
        select: {
          primaryBadge: true,
        },
      }),
    ]);

    return {
      badges: userBadges,
      totalCount: userBadges.length,
      primaryBadge: profile?.primaryBadge || null,
    };
  }

  /**
   * Get user's primary badge
   */
  async getUserPrimaryBadge(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        primaryBadge: true,
      },
    });

    return profile?.primaryBadge || null;
  }

  /**
   * Set user's primary badge (must be earned)
   */
  async setUserPrimaryBadge(userId: string, badgeId: string) {
    // Check if user has earned this badge
    const userBadge = await this.prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId,
          badgeId,
        },
      },
    });

    if (!userBadge) {
      throw new BadRequestException(
        'Cannot set primary badge - badge not earned by user',
      );
    }

    // Update user's primary badge
    await this.prisma.profile.update({
      where: { id: userId },
      data: { primaryBadgeId: badgeId },
    });

    return this.getUserPrimaryBadge(userId);
  }

  /**
   * Admin: Create a new badge
   */
  async createBadge(dto: CreateBadgeDto, adminId: string) {
    const slug = await generateUniqueSlug({
      source: dto.name,
      desiredSlug: dto.slug,
      fallback: 'badge',
      exists: async (candidate) => {
        const existing = await this.prisma.badge.findUnique({
          where: { slug: candidate },
          select: { id: true },
        });
        return Boolean(existing);
      },
    });

    return this.prisma.badge.create({
      data: {
        slug,
        name: dto.name,
        description: dto.description,
        imageUrl: dto.imageUrl,
        category: dto.category,
        rarity: dto.rarity,
        pointsRequirement: dto.pointsRequirement || 0,
        sortOrder: dto.sortOrder || 0,
        isActive: true,
      },
    });
  }

  /**
   * Admin: Update an existing badge
   */
  async updateBadge(badgeId: string, dto: UpdateBadgeDto, adminId: string) {
    const badge = await this.prisma.badge.findUnique({
      where: { id: badgeId },
    });

    if (!badge) {
      throw new NotFoundException(`Badge with ID "${badgeId}" not found`);
    }

    let nextSlug: string | undefined;
    if (dto.name !== undefined && dto.name !== badge.name) {
      nextSlug = await generateUniqueSlug({
        source: dto.name,
        fallback: 'badge',
        exists: async (candidate) => {
          const existing = await this.prisma.badge.findFirst({
            where: {
              slug: candidate,
              NOT: { id: badgeId },
            },
            select: { id: true },
          });
          return Boolean(existing);
        },
      });
    }

    return this.prisma.badge.update({
      where: { id: badgeId },
      data: {
        ...(nextSlug && { slug: nextSlug }),
        ...(dto.name && { name: dto.name }),
        ...(dto.description && { description: dto.description }),
        ...(dto.imageUrl && { imageUrl: dto.imageUrl }),
        ...(dto.category && { category: dto.category }),
        ...(dto.rarity && { rarity: dto.rarity }),
        ...(dto.pointsRequirement !== undefined && {
          pointsRequirement: dto.pointsRequirement,
        }),
        ...(dto.sortOrder !== undefined && { sortOrder: dto.sortOrder }),
        ...(dto.isActive !== undefined && { isActive: dto.isActive }),
      },
    });
  }

  /**
   * Admin: Grant a badge to a user
   */
  async grantBadge(dto: GrantBadgeDto, grantedBy: string | AuthUser) {
    const badge = await this.getBadgeBySlug(dto.badgeSlug);
    const grantedById = this.resolveActorId(grantedBy);
    const resolvedUserId = await this.resolveProfileIdByIdOrEmail(
      dto.userId ?? dto.userIdentifier,
    );

    // Check if user already has this badge
    const existing = await this.prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId: resolvedUserId,
          badgeId: badge.id,
        },
      },
    });

    if (existing) {
      throw new ConflictException('User already has this badge');
    }

    // Grant the badge
    const userBadge = await this.prisma.userBadge.create({
      data: {
        userId: resolvedUserId,
        badgeId: badge.id,
        grantedBy: grantedById,
        metadata: dto.metadata,
      },
      include: {
        badge: true,
      },
    });
    await this.ensurePrimaryBadgePriority(resolvedUserId, badge, this.prisma);

    // Send notification
    await this.notificationsService.notifyMany([
      {
        userId: resolvedUserId,
        type: 'badge_earned',
        actorUserId: grantedById,
        projectId: null,
        updateId: null,
        urgency: null,
        title: 'New Badge Earned!',
        body: `You've earned the "${badge.name}" badge!`,
        payload: {
          badgeId: badge.id,
          badgeSlug: badge.slug,
          badgeName: badge.name,
          badgeRarity: badge.rarity,
        },
        deeplink: `blocnet://profile/badges`,
        pushData: {
          type: 'badge_earned',
          badgeId: badge.id,
        },
      },
    ]);

    return userBadge;
  }

  private resolveActorId(actor: string | AuthUser): string {
    if (typeof actor === 'string') {
      return actor;
    }
    return actor.id;
  }

  private async resolveProfileIdByIdOrEmail(
    userIdOrEmail: string | undefined,
  ): Promise<string> {
    const candidate = userIdOrEmail?.trim();
    if (!candidate) {
      throw new BadRequestException('userId or userIdentifier is required');
    }

    if (UUID_REGEX.test(candidate)) {
      const profile = await this.prisma.profile.findUnique({
        where: { id: candidate },
        select: { id: true, isDeactivated: true },
      });
      if (profile) {
        if (profile.isDeactivated) {
          throw new BadRequestException(
            'Cannot grant badge to deactivated user',
          );
        }
        return profile.id;
      }
    }

    const profile = await this.prisma.profile.findFirst({
      where: {
        email: {
          equals: candidate,
          mode: 'insensitive',
        },
      },
      select: { id: true, isDeactivated: true },
    });

    if (!profile) {
      throw new NotFoundException('User not found');
    }
    if (profile.isDeactivated) {
      throw new BadRequestException('Cannot grant badge to deactivated user');
    }
    return profile.id;
  }

  /**
   * Admin: Revoke a badge from a user
   */
  async revokeBadge(userId: string, badgeSlug: string, adminId: string) {
    const badge = await this.getBadgeBySlug(badgeSlug);

    const userBadge = await this.prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId,
          badgeId: badge.id,
        },
      },
    });

    if (!userBadge) {
      throw new NotFoundException('User does not have this badge');
    }

    // If this was the user's primary badge, unset it
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: { primaryBadgeId: true },
    });

    if (profile?.primaryBadgeId === badge.id) {
      await this.prisma.profile.update({
        where: { id: userId },
        data: { primaryBadgeId: null },
      });
    }

    // Delete the user badge
    await this.prisma.userBadge.delete({
      where: {
        userId_badgeId: {
          userId,
          badgeId: badge.id,
        },
      },
    });

    return { message: 'Badge revoked successfully' };
  }

  /**
   * Auto-award badge based on criteria
   */
  async checkAndAwardBadge(
    userId: string,
    badgeSlug: string,
    metadata?: Record<string, any>,
    prismaClient?: PrismaLike,
  ) {
    const prisma = prismaClient || this.prisma;

    // Check if user already has this badge
    const badge = await prisma.badge.findUnique({
      where: { slug: badgeSlug, isActive: true },
    });

    if (!badge) {
      return null; // Badge doesn't exist or is inactive
    }

    const existing = await prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId,
          badgeId: badge.id,
        },
      },
    });

    if (existing) {
      return null; // User already has this badge
    }

    // Award the badge
    const userBadge = await prisma.userBadge.create({
      data: {
        userId,
        badgeId: badge.id,
        grantedBy: null, // Auto-awarded
        metadata,
      },
      include: {
        badge: true,
      },
    });
    await this.ensurePrimaryBadgePriority(userId, badge, prisma);

    // Send notification (only if not in a transaction)
    if (!prismaClient) {
      await this.notificationsService.notifyMany([
        {
          userId,
          type: 'badge_earned',
          actorUserId: null,
          projectId: null,
          updateId: null,
          urgency: null,
          title: 'New Badge Earned!',
          body: `You've earned the "${badge.name}" badge!`,
          payload: {
            badgeId: badge.id,
            badgeSlug: badge.slug,
            badgeName: badge.name,
            badgeRarity: badge.rarity,
          },
          deeplink: `blocnet://profile/badges`,
          pushData: {
            type: 'badge_earned',
            badgeId: badge.id,
          },
        },
      ]);
    }

    return userBadge;
  }

  /**
   * Check and award mining milestone badges
   */
  async checkMiningMilestones(userId: string, totalPoints: number) {
    const milestones = [
      { points: 1000, slug: 'mining-novice' },
      { points: 10000, slug: 'mining-pro' },
      { points: 50000, slug: 'mining-expert' },
      { points: 100000, slug: 'mining-legend' },
    ];

    for (const milestone of milestones) {
      if (totalPoints >= milestone.points) {
        await this.checkAndAwardBadge(userId, milestone.slug, {
          milestonePoints: milestone.points,
          totalPoints,
        });
      }
    }
  }

  /**
   * Check and award engagement badges
   */
  async checkEngagementMilestones(userId: string) {
    const [updateCount, commentCount, followerCount] = await Promise.all([
      this.prisma.update.count({ where: { authorId: userId } }),
      this.prisma.comment.count({ where: { authorId: userId } }),
      this.prisma.userFollow.count({ where: { followeeId: userId } }),
    ]);

    // Update milestones
    if (updateCount >= 1)
      await this.checkAndAwardBadge(userId, 'first-update', { updateCount });
    if (updateCount >= 10)
      await this.checkAndAwardBadge(userId, 'content-creator', { updateCount });
    if (updateCount >= 50)
      await this.checkAndAwardBadge(userId, 'prolific-creator', {
        updateCount,
      });

    // Comment milestones
    if (commentCount >= 1)
      await this.checkAndAwardBadge(userId, 'first-comment', { commentCount });
    if (commentCount >= 50)
      await this.checkAndAwardBadge(userId, 'engaged-member', { commentCount });
    if (commentCount >= 100)
      await this.checkAndAwardBadge(userId, 'community-champion', {
        commentCount,
      });

    // Follower milestones
    if (followerCount >= 10)
      await this.checkAndAwardBadge(userId, 'rising-star', { followerCount });
    if (followerCount >= 100)
      await this.checkAndAwardBadge(userId, 'social-butterfly', {
        followerCount,
      });
    if (followerCount >= 500)
      await this.checkAndAwardBadge(userId, 'influencer', { followerCount });
  }

  /**
   * Check and award referral badges
   */
  async checkReferralMilestones(userId: string) {
    const referralCount = await this.prisma.profile.count({
      where: { referredById: userId },
    });

    if (referralCount >= 1)
      await this.checkAndAwardBadge(userId, 'first-referral', {
        referralCount,
      });
    if (referralCount >= 5)
      await this.checkAndAwardBadge(userId, 'recruiter', { referralCount });
    if (referralCount >= 25)
      await this.checkAndAwardBadge(userId, 'talent-scout', { referralCount });
    if (referralCount >= 100)
      await this.checkAndAwardBadge(userId, 'network-builder', {
        referralCount,
      });
  }

  private async ensurePrimaryBadgePriority(
    userId: string,
    candidate: Badge,
    prisma: PrismaLike,
  ) {
    const profile = await prisma.profile.findUnique({
      where: { id: userId },
      select: {
        primaryBadge: {
          select: {
            id: true,
            rarity: true,
            pointsRequirement: true,
            sortOrder: true,
            createdAt: true,
          },
        },
      },
    });

    const current = profile?.primaryBadge;
    if (!current || this.isBadgeHigherPriority(candidate, current)) {
      await prisma.profile.update({
        where: { id: userId },
        data: { primaryBadgeId: candidate.id },
      });
    }
  }

  private isBadgeHigherPriority(
    left: Pick<
      Badge,
      'rarity' | 'pointsRequirement' | 'sortOrder' | 'createdAt'
    >,
    right: Pick<
      Badge,
      'rarity' | 'pointsRequirement' | 'sortOrder' | 'createdAt'
    >,
  ) {
    const rarityDelta =
      this.badgeRarityRank(left.rarity) - this.badgeRarityRank(right.rarity);
    if (rarityDelta !== 0) return rarityDelta > 0;

    if (left.pointsRequirement !== right.pointsRequirement) {
      return left.pointsRequirement > right.pointsRequirement;
    }

    if (left.sortOrder !== right.sortOrder) {
      return left.sortOrder < right.sortOrder;
    }

    return left.createdAt.getTime() > right.createdAt.getTime();
  }

  private badgeRarityRank(rarity: BadgeRarity) {
    switch (rarity) {
      case BadgeRarity.legendary:
        return 4;
      case BadgeRarity.epic:
        return 3;
      case BadgeRarity.rare:
        return 2;
      case BadgeRarity.common:
        return 1;
    }
  }
}
