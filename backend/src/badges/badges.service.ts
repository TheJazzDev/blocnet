import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Badge, BadgeCategory, Prisma } from '@prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBadgeDto } from './dto/create-badge.dto';
import { GrantBadgeDto } from './dto/grant-badge.dto';

type PrismaLike = PrismaService | Prisma.TransactionClient;

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
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { createdAt: 'asc' }],
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
    // Check for duplicate slug
    const existing = await this.prisma.badge.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(`Badge with slug "${dto.slug}" already exists`);
    }

    return this.prisma.badge.create({
      data: {
        slug: dto.slug,
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
   * Admin: Grant a badge to a user
   */
  async grantBadge(dto: GrantBadgeDto, grantedBy: string) {
    const badge = await this.getBadgeBySlug(dto.badgeSlug);

    // Check if user already has this badge
    const existing = await this.prisma.userBadge.findUnique({
      where: {
        userId_badgeId: {
          userId: dto.userId,
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
        userId: dto.userId,
        badgeId: badge.id,
        grantedBy,
        metadata: dto.metadata,
      },
      include: {
        badge: true,
      },
    });

    // Send notification
    await this.notificationsService.create({
      userId: dto.userId,
      type: 'badge_earned',
      title: 'New Badge Earned!',
      body: `You've earned the "${badge.name}" badge!`,
      payload: {
        badgeId: badge.id,
        badgeSlug: badge.slug,
        badgeName: badge.name,
        badgeRarity: badge.rarity,
      },
      deeplink: `blocnet://profile/badges`,
    });

    return userBadge;
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

    // Send notification (only if not in a transaction)
    if (!prismaClient) {
      await this.notificationsService.create({
        userId,
        type: 'badge_earned',
        title: 'New Badge Earned!',
        body: `You've earned the "${badge.name}" badge!`,
        payload: {
          badgeId: badge.id,
          badgeSlug: badge.slug,
          badgeName: badge.name,
          badgeRarity: badge.rarity,
        },
        deeplink: `blocnet://profile/badges`,
      });
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
      await this.checkAndAwardBadge(userId, 'prolific-creator', { updateCount });

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
      await this.checkAndAwardBadge(userId, 'first-referral', { referralCount });
    if (referralCount >= 5)
      await this.checkAndAwardBadge(userId, 'recruiter', { referralCount });
    if (referralCount >= 25)
      await this.checkAndAwardBadge(userId, 'talent-scout', { referralCount });
    if (referralCount >= 100)
      await this.checkAndAwardBadge(userId, 'network-builder', {
        referralCount,
      });
  }
}
