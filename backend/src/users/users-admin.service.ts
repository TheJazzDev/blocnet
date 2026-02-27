import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { NotificationType, Prisma, RoleName } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { AdminDeleteUserDto } from './dto/admin-delete-user.dto';
import { AdminHardDeleteUserDto } from './dto/admin-hard-delete-user.dto';
import { AdminReactivateUserDto } from './dto/admin-reactivate-user.dto';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';

@Injectable()
export class UsersAdminService {
  private readonly logger = new Logger(UsersAdminService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async getAdminStats() {
    const [
      totalProjects,
      totalUsers,
      activeUsers,
      deactivatedUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
      usersWithPushEnabled,
    ] = await Promise.all([
      this.prisma.project.count(),
      this.prisma.profile.count(),
      this.prisma.profile.count({
        where: { isDeactivated: false },
      }),
      this.prisma.profile.count({
        where: { isDeactivated: true },
      }),
      this.prisma.adminApplication.count({ where: { status: 'pending' } }),
      this.prisma.update.count(),
      this.prisma.comment.count(),
      this.prisma.userRole.count({
        where: {
          role: 'hunter',
          user: {
            isDeactivated: false,
          },
        },
      }),
      this.prisma.projectProposal.count({ where: { status: 'pending' } }),
      this.prisma.primaryTag.count(),
      // Count distinct users who have at least one device token registered
      this.prisma.deviceToken
        .findMany({ select: { userId: true }, distinct: ['userId'] })
        .then((rows) => rows.length),
    ]);

    return {
      totalProjects,
      totalUsers,
      activeUsers,
      deactivatedUsers,
      pendingAdminApps,
      totalUpdates,
      totalComments,
      activeHunters,
      pendingProposals,
      totalTags,
      usersWithPushEnabled,
    };
  }

  async listAllUsers(opts: {
    limit?: number;
    offset?: number;
    role?: string;
    q?: string;
    status?: string;
  }) {
    const { limit = 50, offset = 0, role, q, status } = opts;

    const validRoles = Object.values(RoleName);
    const roleFilter =
      role && validRoles.includes(role as RoleName)
        ? (role as RoleName)
        : undefined;
    const statusFilter =
      status === 'active' ? false : status === 'deactivated' ? true : undefined;

    // Only include UUID filter if q looks like a valid UUID to avoid Postgres cast errors
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q.trim()) : false;

    const where = {
      ...(roleFilter ? { roles: { some: { role: roleFilter } } } : {}),
      ...(statusFilter !== undefined
        ? {
            isDeactivated: statusFilter,
          }
        : {}),
      ...(q
        ? {
            OR: [
              { email: { contains: q, mode: 'insensitive' as const } },
              { displayName: { contains: q, mode: 'insensitive' as const } },
              { username: { contains: q, mode: 'insensitive' as const } },
              ...(isUuid ? [{ id: { equals: q } }] : []),
            ],
          }
        : {}),
    };

    const [users, total] = await Promise.all([
      this.prisma.profile.findMany({
        where,
        skip: offset,
        take: limit,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        include: {
          roles: { select: { role: true } },
          primaryBadge: {
            select: {
              id: true,
              slug: true,
              name: true,
              imageUrl: true,
              category: true,
              rarity: true,
            },
          },
          _count: {
            select: {
              hunterAssignments: true,
              authoredUpdates: true,
              earnedBadges: true,
            },
          },
        },
      }),
      this.prisma.profile.count({ where }),
    ]);

    return {
      data: users.map((u) => ({
        id: u.id,
        email: u.email,
        username: u.username,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isDeactivated: u.isDeactivated,
        deactivatedAt: u.deactivatedAt,
        roles: u.roles.map((r) => r.role),
        projectsAssigned: u._count.hunterAssignments,
        updatesPosted: u._count.authoredUpdates,
        badgesCount: u._count.earnedBadges,
        primaryBadge: u.primaryBadge,
        createdAt: u.createdAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async getAdminUserById(userId: string) {
    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
        primaryBadge: {
          select: {
            id: true,
            slug: true,
            name: true,
            imageUrl: true,
            category: true,
            rarity: true,
          },
        },
        earnedBadges: {
          orderBy: { earnedAt: 'desc' },
          take: 20,
          select: {
            earnedAt: true,
            badge: {
              select: {
                id: true,
                slug: true,
                name: true,
                imageUrl: true,
                category: true,
                rarity: true,
              },
            },
          },
        },
        referrer: {
          select: {
            id: true,
            email: true,
            displayName: true,
            referralCode: true,
          },
        },
        tipAccounts: {
          orderBy: [{ currencyCode: 'asc' }],
          select: {
            id: true,
            accountType: true,
            ownerRef: true,
            currencyCode: true,
            balanceAtomic: true,
            updatedAt: true,
            currency: {
              select: {
                code: true,
                symbol: true,
                decimals: true,
                kind: true,
                isEnabled: true,
              },
            },
          },
        },
        wallet: true,
        kycProfile: true,
        _count: {
          select: {
            referrals: true,
            followerLinks: true,
            followingLinks: true,
            follows: true,
            bookmarks: true,
            authoredUpdates: true,
            authoredComments: true,
            communityPosts: true,
            communityPostComments: true,
            withdrawalRequests: true,
            deviceTokens: true,
            earnedBadges: true,
            tipTransactionsSent: true,
            tipTransactionsReceived: true,
            tipConversions: true,
          },
        },
      },
    });

    if (!profile) {
      throw new NotFoundException('User not found');
    }

    const [tipSentByCurrency, tipReceivedByCurrency, tipConversionsByPair] =
      await Promise.all([
        this.prisma.tipTransaction.groupBy({
          by: ['currencyCode'],
          where: { senderUserId: userId },
          _count: { _all: true },
          _sum: {
            amountAtomic: true,
            feeAtomic: true,
            totalDebitAtomic: true,
          },
        }),
        this.prisma.tipTransaction.groupBy({
          by: ['currencyCode'],
          where: { recipientUserId: userId },
          _count: { _all: true },
          _sum: {
            amountAtomic: true,
          },
        }),
        this.prisma.tipConversion.groupBy({
          by: ['fromCurrencyCode', 'toCurrencyCode'],
          where: { userId },
          _count: { _all: true },
          _sum: {
            amountInAtomic: true,
            amountOutAtomic: true,
          },
        }),
      ]);

    const currencyCodes = new Set<string>([
      ...profile.tipAccounts.map((row) => row.currencyCode),
      ...tipSentByCurrency.map((row) => row.currencyCode),
      ...tipReceivedByCurrency.map((row) => row.currencyCode),
      ...tipConversionsByPair.flatMap((row) => [
        row.fromCurrencyCode,
        row.toCurrencyCode,
      ]),
    ]);

    const currencies =
      currencyCodes.size === 0
        ? []
        : await this.prisma.tipCurrency.findMany({
            where: {
              code: {
                in: [...currencyCodes],
              },
            },
            select: {
              code: true,
              symbol: true,
              decimals: true,
              kind: true,
              isEnabled: true,
            },
          });
    const currencyMap = new Map(currencies.map((row) => [row.code, row]));

    return {
      id: profile.id,
      email: profile.email,
      username: profile.username,
      referralCode: profile.referralCode,
      referredAt: profile.referredAt,
      referredBy: profile.referrer
        ? {
            id: profile.referrer.id,
            email: profile.referrer.email,
            displayName: profile.referrer.displayName,
            referralCode: profile.referrer.referralCode,
          }
        : null,
      displayName: profile.displayName,
      avatarUrl: profile.avatarUrl,
      bio: profile.bio,
      isDeactivated: profile.isDeactivated,
      deactivatedAt: profile.deactivatedAt,
      deactivatedBy: profile.deactivatedBy,
      deactivationReason: profile.deactivationReason,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      roles: profile.roles.map((row) => row.role),
      primaryBadge: profile.primaryBadge,
      badges: profile.earnedBadges.map((entry) => ({
        earnedAt: entry.earnedAt,
        badge: entry.badge,
      })),
      wallet: profile.wallet
        ? {
            id: profile.wallet.id,
            status: profile.wallet.status,
            address: profile.wallet.address,
            providerWalletId: profile.wallet.providerWalletId,
            chainEnvironment: profile.wallet.chainEnvironment,
            chainId: profile.wallet.chainId,
            createdAt: profile.wallet.createdAt,
            updatedAt: profile.wallet.updatedAt,
          }
        : null,
      kyc: profile.kycProfile
        ? {
            status: profile.kycProfile.status,
            tier: profile.kycProfile.tier,
            submittedAt: profile.kycProfile.submittedAt,
            reviewedAt: profile.kycProfile.reviewedAt,
            reviewNote: profile.kycProfile.reviewNote,
          }
        : null,
      tips: {
        accounts: profile.tipAccounts.map((row) => ({
          id: row.id,
          accountType: row.accountType,
          ownerRef: row.ownerRef,
          currencyCode: row.currencyCode,
          balanceAtomic: row.balanceAtomic.toString(),
          updatedAt: row.updatedAt,
          currency: row.currency,
        })),
        sentByCurrency: tipSentByCurrency.map((row) => {
          const currency = currencyMap.get(row.currencyCode);
          return {
            currencyCode: row.currencyCode,
            txCount: row._count._all,
            amountAtomic: (row._sum.amountAtomic ?? 0n).toString(),
            feeAtomic: (row._sum.feeAtomic ?? 0n).toString(),
            totalDebitAtomic: (row._sum.totalDebitAtomic ?? 0n).toString(),
            currency,
          };
        }),
        receivedByCurrency: tipReceivedByCurrency.map((row) => {
          const currency = currencyMap.get(row.currencyCode);
          return {
            currencyCode: row.currencyCode,
            txCount: row._count._all,
            amountAtomic: (row._sum.amountAtomic ?? 0n).toString(),
            currency,
          };
        }),
        conversionsByPair: tipConversionsByPair.map((row) => ({
          fromCurrencyCode: row.fromCurrencyCode,
          toCurrencyCode: row.toCurrencyCode,
          txCount: row._count._all,
          amountInAtomic: (row._sum.amountInAtomic ?? 0n).toString(),
          amountOutAtomic: (row._sum.amountOutAtomic ?? 0n).toString(),
          fromCurrency: currencyMap.get(row.fromCurrencyCode) ?? null,
          toCurrency: currencyMap.get(row.toCurrencyCode) ?? null,
        })),
      },
      counts: {
        directReferrals: profile._count.referrals,
        followers: profile._count.followerLinks,
        following: profile._count.followingLinks,
        watchedProjects: profile._count.follows,
        bookmarks: profile._count.bookmarks,
        updates: profile._count.authoredUpdates,
        comments: profile._count.authoredComments,
        communityPosts: profile._count.communityPosts,
        communityComments: profile._count.communityPostComments,
        withdrawals: profile._count.withdrawalRequests,
        deviceTokens: profile._count.deviceTokens,
        badges: profile._count.earnedBadges,
        tipSent: profile._count.tipTransactionsSent,
        tipReceived: profile._count.tipTransactionsReceived,
        tipConversions: profile._count.tipConversions,
      },
    };
  }

  async updateUserByAdmin(
    actor: AuthUser,
    userId: string,
    dto: AdminUpdateUserDto,
  ) {
    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    const targetRoles = target.roles.map((row) => row.role);
    this.assertAdminCanManageTarget(actor, target.id, targetRoles);

    if (target.isDeactivated) {
      throw new BadRequestException('Cannot edit a deactivated user account');
    }

    if (dto.username !== undefined && dto.username !== null) {
      const taken = await this.isUsernameTaken(dto.username, target.id);
      if (taken) {
        throw new BadRequestException('Username is already taken');
      }
    }

    const data: {
      displayName?: string | null;
      username?: string | null;
      avatarUrl?: string | null;
      bio?: string | null;
    } = {};

    if (dto.displayName !== undefined) {
      data.displayName = dto.displayName;
    }
    if (dto.username !== undefined) {
      data.username = dto.username;
    }
    if (dto.avatarUrl !== undefined) {
      data.avatarUrl = dto.avatarUrl;
    }
    if (dto.bio !== undefined) {
      data.bio = dto.bio;
    }

    if (Object.keys(data).length === 0) {
      throw new BadRequestException('No editable fields were provided');
    }

    await this.prisma.profile.update({
      where: { id: target.id },
      data,
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.update',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        fields: Object.keys(data),
      },
    });

    return this.getAdminUserById(target.id);
  }

  async deleteUserByAdmin(
    actor: AuthUser,
    userId: string,
    dto: AdminDeleteUserDto,
  ) {
    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (actor.id === target.id) {
      throw new ForbiddenException('You cannot delete your own account');
    }

    const targetRoles = target.roles.map((row) => row.role);
    this.assertAdminCanManageTarget(actor, target.id, targetRoles);
    await this.assertNotDeletingLastActiveOwner(target.id, targetRoles);

    const ownedProjectsCount = await this.prisma.project.count({
      where: { ownerAdminId: target.id },
    });
    if (ownedProjectsCount > 0) {
      throw new BadRequestException(
        'Cannot delete user while they still own projects. Reassign project ownership first.',
      );
    }

    if (target.isDeactivated) {
      return {
        deleted: false,
        reason: 'already_deactivated',
      };
    }

    const deactivatedAt = new Date();
    try {
      await this.notificationsService.notifyMany(
        [
          {
            userId: target.id,
            type: NotificationType.system,
            actorUserId: actor.id,
            title: 'Account deactivated',
            body: 'Your account was deactivated by an administrator.',
            payload: {
              action: 'admin.user.delete',
              reason: dto.reason ?? null,
            } as Prisma.InputJsonValue,
            deeplink: '/profile',
          },
        ],
        { push: true },
      );
    } catch {
      // Best-effort only; deactivation must proceed.
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { id: target.id },
        data: {
          isDeactivated: true,
          deactivatedAt,
          deactivatedBy: actor.id,
          deactivationReason:
            dto.reason ?? 'Account deleted by admin user management',
          email: this.createDeletedEmail(target.id),
          previousUsername: target.username,
          previousDisplayName: target.displayName,
          previousAvatarUrl: target.avatarUrl,
          previousBio: target.bio,
          username: null,
          displayName: 'Deleted User',
          avatarUrl: null,
          bio: null,
          homeFeedLastSeenAt: null,
        },
      });

      await tx.userRole.deleteMany({
        where: {
          userId: target.id,
        },
      });

      await tx.deviceToken.deleteMany({
        where: {
          userId: target.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.delete',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      deleted: true,
      userId: target.id,
      deactivatedAt,
    };
  }

  async reactivateUserByOwner(
    actor: AuthUser,
    userId: string,
    dto: AdminReactivateUserDto,
  ) {
    this.assertOwnerActor(actor, 'Only owner can reactivate users');

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (!target.isDeactivated) {
      return {
        reactivated: false,
        reason: 'already_active',
      };
    }

    const reactivatedAt = new Date();
    let restoredUsername: string | null = target.previousUsername ?? null;

    if (restoredUsername) {
      const usernameTaken = await this.prisma.profile.findUnique({
        where: { username: restoredUsername },
        select: { id: true },
      });
      if (usernameTaken && usernameTaken.id !== target.id) {
        restoredUsername = null;
      }
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { id: target.id },
        data: {
          isDeactivated: false,
          deactivatedAt: null,
          deactivatedBy: null,
          deactivationReason: null,
          username: restoredUsername,
          displayName: target.previousDisplayName,
          avatarUrl: target.previousAvatarUrl,
          bio: target.previousBio,
          previousUsername: null,
          previousDisplayName: null,
          previousAvatarUrl: null,
          previousBio: null,
        },
      });

      await tx.userRole.upsert({
        where: {
          userId_role: {
            userId: target.id,
            role: RoleName.user,
          },
        },
        update: {},
        create: {
          userId: target.id,
          role: RoleName.user,
          grantedBy: actor.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.reactivate',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      reactivated: true,
      userId: target.id,
      reactivatedAt,
      usernameResetRequired: restoredUsername == null,
    };
  }

  async hardDeleteUserByOwner(
    actor: AuthUser,
    userId: string,
    dto: AdminHardDeleteUserDto,
  ) {
    this.assertOwnerActor(actor, 'Only owner can hard delete users');

    const target = await this.prisma.profile.findUnique({
      where: { id: userId },
      include: {
        roles: { select: { role: true } },
      },
    });

    if (!target) {
      throw new NotFoundException('User not found');
    }

    if (actor.id === target.id) {
      throw new ForbiddenException('You cannot hard delete your own account');
    }

    if (!target.isDeactivated) {
      throw new BadRequestException(
        'Hard delete requires a deactivated user account first',
      );
    }

    const targetRoles = target.roles.map((row) => row.role);
    await this.assertNotDeletingLastActiveOwner(target.id, targetRoles);

    const ownedProjectsCount = await this.prisma.project.count({
      where: { ownerAdminId: target.id },
    });
    if (ownedProjectsCount > 0) {
      throw new BadRequestException(
        'Cannot hard delete user while they still own projects. Reassign project ownership first.',
      );
    }

    await this.prisma.profile.delete({
      where: { id: target.id },
    });

    const deletedAt = new Date();
    await this.auditLogService.create({
      actorId: actor.id,
      action: 'admin.user.hard_delete',
      resourceType: 'profile',
      resourceId: target.id,
      metadata: {
        targetUserId: target.id,
        reason: dto.reason ?? null,
      },
    });

    return {
      hardDeleted: true,
      userId: target.id,
      deletedAt,
    };
  }

  private assertAdminCanManageTarget(
    actor: AuthUser,
    targetUserId: string,
    targetRoles: RoleName[],
  ) {
    const isOwner = actor.roles.includes(AppRole.OWNER);
    const isAdmin = actor.roles.includes(AppRole.ADMIN);

    if (!isOwner && !isAdmin) {
      throw new ForbiddenException('Only owner/admin can manage users');
    }

    if (isOwner) {
      return;
    }

    const targetIsOwner = targetRoles.includes(RoleName.owner);
    const targetIsAdmin = targetRoles.includes(RoleName.admin);
    if (targetIsOwner || targetIsAdmin) {
      throw new ForbiddenException(
        'Admin users cannot manage owner/admin accounts',
      );
    }

    if (actor.id === targetUserId && targetIsAdmin) {
      throw new ForbiddenException('Admin users cannot self-manage admin role');
    }
  }

  private assertOwnerActor(actor: AuthUser, message: string) {
    if (!actor.roles.includes(AppRole.OWNER)) {
      throw new ForbiddenException(message);
    }
  }

  private async assertNotDeletingLastActiveOwner(
    targetUserId: string,
    targetRoles: RoleName[],
  ) {
    if (!targetRoles.includes(RoleName.owner)) {
      return;
    }

    const activeOwnerCount = await this.prisma.userRole.count({
      where: {
        role: RoleName.owner,
        user: {
          isDeactivated: false,
        },
      },
    });

    if (activeOwnerCount <= 1) {
      throw new ForbiddenException('Cannot delete the last active owner');
    }

    const targetIsActiveOwner = await this.prisma.userRole.findFirst({
      where: {
        userId: targetUserId,
        role: RoleName.owner,
        user: {
          isDeactivated: false,
        },
      },
      select: { id: true },
    });

    if (!targetIsActiveOwner) {
      throw new ForbiddenException('Owner account is already inactive');
    }
  }

  private createDeletedEmail(userId: string): string {
    return `deleted+${userId}@deleted.local`;
  }

  private async isUsernameTaken(
    username: string,
    excludeUserId?: string,
  ): Promise<boolean> {
    const profile = await this.prisma.profile.findUnique({
      where: { username: username.toLowerCase() },
      select: { id: true },
    });
    if (!profile) return false;
    if (excludeUserId && profile.id === excludeUserId) return false;
    return true;
  }
}
