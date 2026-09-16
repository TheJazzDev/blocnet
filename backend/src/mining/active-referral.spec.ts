import {
  activeReferralWhere,
  countActiveDirectReferrals,
  isActiveReferral,
} from './active-referral';

const HOUR = 60 * 60 * 1000;
const AS_OF = new Date('2026-09-16T12:00:00.000Z');
const WINDOW = { referralsEnabled: true, activeReferralWindowHours: 168 };

describe('active referral (F-50): started a mining cycle in the window', () => {
  it('matches referrals with a mining start between the cutoff and asOf', () => {
    expect(activeReferralWhere(AS_OF, 168)).toEqual({
      miningSessions: {
        some: {
          startsAt: {
            gte: new Date(AS_OF.getTime() - 168 * HOUR),
            lte: AS_OF,
          },
        },
      },
    });
  });

  it.each([
    [null, false],
    [new Date(AS_OF.getTime() - 168 * HOUR), true],
    [new Date(AS_OF.getTime() - 168 * HOUR - 1), false],
    [new Date(AS_OF.getTime() - HOUR), true],
    [new Date(AS_OF.getTime() + HOUR), false],
  ])('isActiveReferral(latest start %p) is %p', (latestStart, expected) => {
    expect(isActiveReferral(latestStart, AS_OF, 168)).toBe(expected);
  });

  it('counts direct referrals with the shared filter', async () => {
    const prisma = { profile: { count: jest.fn().mockResolvedValue(3) } };

    await expect(
      countActiveDirectReferrals(prisma as never, 'user-1', WINDOW, AS_OF),
    ).resolves.toBe(3);
    expect(prisma.profile.count).toHaveBeenCalledWith({
      where: { referredById: 'user-1', ...activeReferralWhere(AS_OF, 168) },
    });
  });

  it('is zero without a query when referrals are disabled', async () => {
    const prisma = { profile: { count: jest.fn() } };

    await expect(
      countActiveDirectReferrals(
        prisma as never,
        'user-1',
        { ...WINDOW, referralsEnabled: false },
        AS_OF,
      ),
    ).resolves.toBe(0);
    expect(prisma.profile.count).not.toHaveBeenCalled();
  });
});
