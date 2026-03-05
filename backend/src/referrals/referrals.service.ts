import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { RuntimeFeatureFlagsService } from '../runtime-flags/runtime-feature-flags.service';

type ReferralConfig = {
  referralsEnabled: boolean;
  activeReferralWindowHours: number;
  referralBindWindowHours: number;
};

const DEFAULT_REFERRAL_CONFIG = {
  referralsEnabled: true,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 24,
};
const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Injectable()
export class ReferralsService {
  private readonly logger = new Logger(ReferralsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly runtimeFeatureFlagsService: RuntimeFeatureFlagsService,
    private readonly auditLogService: AuditLogService,
    private readonly badgesService: BadgesService,
    private readonly questsService: QuestsService,
  ) {}

  async getMe(userId: string) {
    const asOf = new Date();
    const config = await this.getReferralConfig();

    const profile = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        createdAt: true,
        referralCode: true,
        referredById: true,
        referredAt: true,
      },
    });

    if (!profile) {
      throw new NotFoundException('Profile not found');
    }

    const [totalDirectReferrals, activeDirectReferrals, referrer] =
      await Promise.all([
        this.prisma.profile.count({
          where: {
            referredById: userId,
          },
        }),
        this.countActiveDirectReferrals(userId, config, asOf),
        profile.referredById
          ? this.prisma.profile.findUnique({
              where: {
                id: profile.referredById,
              },
              select: {
                id: true,
                displayName: true,
                username: true,
                referralCode: true,
              },
            })
          : Promise.resolve(null),
      ]);

    const canBindUntil = new Date(
      profile.createdAt.getTime() +
        config.referralBindWindowHours * 60 * 60 * 1000,
    );

    return {
      code: profile.referralCode,
      referredBy: referrer,
      referredAt: profile.referredAt,
      canBindUntil,
      bindWindowOpen: !profile.referredById && asOf <= canBindUntil,
      totalDirectReferrals,
      activeDirectReferrals,
    };
  }

  async validateCode(rawCode: string) {
    const code = this.normalizeCode(rawCode);

    const profile = await this.prisma.profile.findUnique({
      where: {
        referralCode: code,
      },
      select: {
        id: true,
        displayName: true,
        username: true,
      },
    });

    return {
      valid: !!profile,
      code,
      referrer: profile,
    };
  }

  async bind(userId: string, rawCode: string) {
    const config = await this.getReferralConfig();
    if (!config.referralsEnabled) {
      throw new BadRequestException('Referrals are disabled');
    }

    const code = this.normalizeCode(rawCode);

    const currentUser = await this.prisma.profile.findUnique({
      where: {
        id: userId,
      },
      select: {
        id: true,
        createdAt: true,
        referredById: true,
      },
    });

    if (!currentUser) {
      throw new NotFoundException('Profile not found');
    }

    if (currentUser.referredById) {
      throw new ConflictException('Referral has already been bound');
    }

    const bindWindowClosesAt = new Date(
      currentUser.createdAt.getTime() +
        config.referralBindWindowHours * 60 * 60 * 1000,
    );

    if (Date.now() > bindWindowClosesAt.getTime()) {
      throw new BadRequestException('Referral bind window has expired');
    }

    const referrer = await this.prisma.profile.findUnique({
      where: {
        referralCode: code,
      },
      select: {
        id: true,
        referralCode: true,
        referredById: true,
      },
    });

    if (!referrer) {
      throw new NotFoundException('Referral code not found');
    }

    if (referrer.id === userId) {
      throw new BadRequestException('You cannot use your own referral code');
    }

    if (referrer.referredById === userId) {
      throw new BadRequestException('Invalid referral loop detected');
    }

    const referredAt = new Date();
    await this.prisma.profile.update({
      where: {
        id: userId,
      },
      data: {
        referredById: referrer.id,
        referredAt,
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: 'referral.bind',
      resourceType: 'profile',
      resourceId: userId,
      metadata: {
        referrerId: referrer.id,
        code,
        referredAt: referredAt.toISOString(),
      },
    });

    // Check and award referral badges to the referrer
    await this.badgesService.checkReferralMilestones(referrer.id);
    await this.triggerReferThreeMinersQuestIfEligible(referrer.id);

    return {
      ok: true,
      referredById: referrer.id,
      code,
      referredAt,
    };
  }

  async bindByAdmin(
    actorId: string,
    rawTargetUserIdOrEmail: string,
    rawCode: string,
  ) {
    const code = this.normalizeCode(rawCode);
    const targetUser = await this.findProfileByIdOrEmail(
      rawTargetUserIdOrEmail,
    );

    if (targetUser.referredById) {
      throw new ConflictException('Target user already has a bound referrer');
    }

    const referrer = await this.prisma.profile.findUnique({
      where: {
        referralCode: code,
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        referralCode: true,
        referredById: true,
      },
    });

    if (!referrer) {
      throw new NotFoundException('Referral code not found');
    }

    if (referrer.id === targetUser.id) {
      throw new BadRequestException('You cannot use your own referral code');
    }

    if (referrer.referredById === targetUser.id) {
      throw new BadRequestException('Invalid referral loop detected');
    }

    const referredAt = new Date();
    await this.prisma.profile.update({
      where: {
        id: targetUser.id,
      },
      data: {
        referredById: referrer.id,
        referredAt,
      },
    });

    await this.auditLogService.create({
      actorId,
      action: 'referral.admin_bind',
      resourceType: 'profile',
      resourceId: targetUser.id,
      metadata: {
        targetUserId: targetUser.id,
        targetUserEmail: targetUser.email,
        referrerId: referrer.id,
        referrerEmail: referrer.email,
        code,
        referredAt: referredAt.toISOString(),
      },
    });

    await this.badgesService.checkReferralMilestones(referrer.id);
    await this.triggerReferThreeMinersQuestIfEligible(referrer.id);

    return {
      ok: true,
      targetUser: {
        id: targetUser.id,
        email: targetUser.email,
        displayName: targetUser.displayName,
      },
      referrer: {
        id: referrer.id,
        email: referrer.email,
        displayName: referrer.displayName,
        code: referrer.referralCode,
      },
      referredAt,
      source: 'admin_override' as const,
    };
  }

  async listDownline(userId: string, limit?: number, offset?: number) {
    const asOf = new Date();
    const config = await this.getReferralConfig();

    const boundedLimit = Math.min(Math.max(limit ?? 20, 1), 100);
    const boundedOffset = Math.max(offset ?? 0, 0);

    const [rows, total] = await Promise.all([
      this.prisma.profile.findMany({
        where: {
          referredById: userId,
        },
        orderBy: {
          referredAt: 'desc',
        },
        skip: boundedOffset,
        take: boundedLimit,
        select: {
          id: true,
          email: true,
          username: true,
          displayName: true,
          avatarUrl: true,
          referredAt: true,
          miningClaimedPoints: true,
          miningSessions: {
            orderBy: {
              startsAt: 'desc',
            },
            take: 1,
            select: {
              id: true,
              startsAt: true,
              endsAt: true,
              claimedAt: true,
              effectivePointsPerCycle: true,
            },
          },
        },
      }),
      this.prisma.profile.count({
        where: {
          referredById: userId,
        },
      }),
    ]);

    const cutoff = new Date(
      asOf.getTime() - config.activeReferralWindowHours * 60 * 60 * 1000,
    );

    const data = rows.map((row) => {
      const latestSession = row.miningSessions[0] ?? null;
      const status = this.resolveSessionStatus(latestSession, asOf);
      const progressPct = latestSession
        ? this.computeProgressPct(
            latestSession.startsAt,
            latestSession.endsAt,
            asOf,
          )
        : 0;

      const lastActiveAt = latestSession?.startsAt ?? row.referredAt;
      const isActive = !!latestSession && latestSession.startsAt >= cutoff;

      return {
        id: row.id,
        email: row.email,
        username: row.username,
        displayName: row.displayName,
        avatarUrl: row.avatarUrl,
        referredAt: row.referredAt,
        status,
        isActive,
        progressPct,
        cycle: latestSession
          ? {
              sessionId: latestSession.id,
              startsAt: latestSession.startsAt,
              endsAt: latestSession.endsAt,
              claimedAt: latestSession.claimedAt,
              effectivePointsPerCycle: latestSession.effectivePointsPerCycle,
            }
          : null,
        claimedTotalPoints: this.bigIntToNumber(row.miningClaimedPoints),
        lastActiveAt,
      };
    });

    return {
      data,
      total,
      limit: boundedLimit,
      offset: boundedOffset,
    };
  }

  private normalizeCode(code: string): string {
    return code.trim().toUpperCase();
  }

  private async findProfileByIdOrEmail(rawUserIdOrEmail: string) {
    const userIdOrEmail = rawUserIdOrEmail.trim();

    if (!userIdOrEmail) {
      throw new BadRequestException('target user id or email is required');
    }

    const select = {
      id: true,
      email: true,
      displayName: true,
      referredById: true,
    } as const;

    if (UUID_REGEX.test(userIdOrEmail)) {
      const byId = await this.prisma.profile.findUnique({
        where: { id: userIdOrEmail },
        select,
      });
      if (byId) {
        return byId;
      }
    }

    const byEmail = await this.prisma.profile.findFirst({
      where: {
        email: {
          equals: userIdOrEmail,
          mode: 'insensitive',
        },
      },
      select,
    });

    if (byEmail) {
      return byEmail;
    }

    throw new NotFoundException('Target user not found');
  }

  private async triggerReferThreeMinersQuestIfEligible(referrerId: string) {
    const referralCount = await this.prisma.profile.count({
      where: {
        referredById: referrerId,
      },
    });

    if (referralCount < 3) {
      return;
    }

    try {
      await this.questsService.checkAndCompleteByAction(
        referrerId,
        'refer_3_miners',
      );
    } catch (error) {
      this.logger.warn(
        `Failed to process auto quest trigger`,
        JSON.stringify({
          action: 'refer_3_miners',
          userId: referrerId,
          error: error instanceof Error ? error.message : String(error),
        }),
      );
    }
  }

  private async getReferralConfig(): Promise<ReferralConfig> {
    const configRow = await this.prisma.miningConfig.upsert({
      where: { id: 'default' },
      update: {},
      create: {
        id: 'default',
        enabled: true,
        referralsEnabled: DEFAULT_REFERRAL_CONFIG.referralsEnabled,
        cycleHours: 24,
        basePointsPerCycle: 120,
        perActiveReferralBoostBps: 500,
        maxBoostBps: 10000,
        activeReferralWindowHours:
          DEFAULT_REFERRAL_CONFIG.activeReferralWindowHours,
        referralBindWindowHours:
          DEFAULT_REFERRAL_CONFIG.referralBindWindowHours,
      },
    });

    const miningEnabledFlag = this.runtimeFeatureFlagsService.isMiningEnabled();
    const referralsEnabledFlag =
      this.runtimeFeatureFlagsService.isReferralsEnabled();

    return {
      referralsEnabled:
        configRow.referralsEnabled && miningEnabledFlag && referralsEnabledFlag,
      activeReferralWindowHours: configRow.activeReferralWindowHours,
      referralBindWindowHours: configRow.referralBindWindowHours,
    };
  }

  private async countActiveDirectReferrals(
    userId: string,
    config: ReferralConfig,
    asOf: Date,
  ): Promise<number> {
    if (!config.referralsEnabled) {
      return 0;
    }

    const cutoff = new Date(
      asOf.getTime() - config.activeReferralWindowHours * 60 * 60 * 1000,
    );

    const referrals = await this.prisma.profile.findMany({
      where: {
        referredById: userId,
      },
      select: {
        miningSessions: {
          orderBy: {
            startsAt: 'desc',
          },
          take: 1,
          select: {
            startsAt: true,
          },
        },
      },
    });

    return referrals.filter((referral) => {
      const latestStart = referral.miningSessions[0]?.startsAt;
      return !!latestStart && latestStart >= cutoff;
    }).length;
  }

  private resolveSessionStatus(
    latestSession: {
      startsAt: Date;
      endsAt: Date;
      claimedAt: Date | null;
    } | null,
    asOf: Date,
  ) {
    if (!latestSession) {
      return 'idle' as const;
    }

    if (latestSession.claimedAt) {
      return 'idle' as const;
    }

    if (latestSession.endsAt <= asOf) {
      return 'claimable' as const;
    }

    return 'running' as const;
  }

  private computeProgressPct(startsAt: Date, endsAt: Date, asOf: Date): number {
    const durationMs = endsAt.getTime() - startsAt.getTime();
    if (durationMs <= 0) return 1;

    const elapsedMs = asOf.getTime() - startsAt.getTime();
    if (elapsedMs <= 0) return 0;
    if (elapsedMs >= durationMs) return 1;

    return elapsedMs / durationMs;
  }

  private bigIntToNumber(value: bigint): number {
    return Number(value);
  }
}
