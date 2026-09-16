import { Prisma } from '@prisma/client';

/**
 * The one definition of an "active referral" (F-50, decided 2026-09-16):
 * a referred member who **started a mining cycle** within the last
 * `activeReferralWindowHours` (7 days by default). A mining start is harder to
 * farm than a feed visit. The referral boost, /referrals/me, the downline,
 * the admin metrics and the admin user profile all use this rule.
 */

export type ActiveReferralConfig = {
  referralsEnabled: boolean;
  activeReferralWindowHours: number;
};

type ProfileCounter = {
  profile: { count(args: { where: Prisma.ProfileWhereInput }): Promise<number> };
};

export function activeReferralWindowStart(
  asOf: Date,
  windowHours: number,
): Date {
  return new Date(asOf.getTime() - windowHours * 60 * 60 * 1000);
}

/** Profile filter: has a mining start in [asOf - window, asOf]. */
export function activeReferralWhere(
  asOf: Date,
  windowHours: number,
): Prisma.ProfileWhereInput {
  return {
    miningSessions: {
      some: {
        startsAt: {
          gte: activeReferralWindowStart(asOf, windowHours),
          lte: asOf,
        },
      },
    },
  };
}

/** Same rule for a row that already carries its latest mining start. */
export function isActiveReferral(
  latestMiningStart: Date | null | undefined,
  asOf: Date,
  windowHours: number,
): boolean {
  if (!latestMiningStart) return false;
  const startMs = latestMiningStart.getTime();
  return (
    startMs >= activeReferralWindowStart(asOf, windowHours).getTime() &&
    startMs <= asOf.getTime()
  );
}

export async function countActiveDirectReferrals(
  prisma: ProfileCounter,
  referrerId: string,
  config: ActiveReferralConfig,
  asOf: Date,
): Promise<number> {
  if (!config.referralsEnabled) {
    return 0;
  }

  return prisma.profile.count({
    where: {
      referredById: referrerId,
      ...activeReferralWhere(asOf, config.activeReferralWindowHours),
    },
  });
}
