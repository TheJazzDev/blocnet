import { BadRequestException } from '@nestjs/common';
import { QuestsService } from './quests.service';

describe('QuestsService.verifyQuestSubmission — race condition on double-approve', () => {
  const questFixture = {
    id: 'quest-1',
    slug: 'follow-blocnet-on-x',
    title: 'Follow Blocnet on X',
    rewardPoints: 35,
    rewardBadgeId: null,
  };

  const submissionFixture = {
    id: 'submission-1',
    userId: 'user-1',
    userQuestId: 'user-quest-1',
    verificationStatus: 'pending',
    userQuest: { quest: questFixture },
  };

  // Transaction-scoped client. updateMany's resolved value is swapped
  // per-test to simulate whether this call "won" the race.
  const tx = {
    questSubmission: { updateMany: jest.fn() },
    userQuest: { update: jest.fn(), upsert: jest.fn(), updateMany: jest.fn() },
    miningPointLedger: { create: jest.fn(), findFirst: jest.fn() },
    profile: { update: jest.fn(), findUnique: jest.fn() },
    badge: { findUnique: jest.fn() },
    tipCurrency: { upsert: jest.fn() },
    tipAccount: { upsert: jest.fn(), findUnique: jest.fn(), updateMany: jest.fn() },
  };

  const prisma = {
    questSubmission: { findUnique: jest.fn() },
    $transaction: jest.fn((cb: (tx: unknown) => unknown) => cb(tx)),
  };

  const configService = {};
  const badgesService = { checkAndAwardBadge: jest.fn() };
  const levelsService = { updateUserLevel: jest.fn() };
  const miningConfigService = {};
  const notificationsService = { notifyMany: jest.fn() };
  const questStorageService = {};
  const auditLogService = { create: jest.fn() };

  let service: QuestsService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new QuestsService(
      prisma as any,
      configService as any,
      badgesService as any,
      levelsService as any,
      miningConfigService as any,
      notificationsService as any,
      questStorageService as any,
      auditLogService as any,
    );
    prisma.questSubmission.findUnique.mockResolvedValue(submissionFixture);
    tx.profile.update.mockResolvedValue({});
    tx.miningPointLedger.create.mockResolvedValue({});
  });

  it('only the first of two near-simultaneous approve calls succeeds; only one notification is sent', async () => {
    // Both calls read the submission as 'pending' (findUnique is mocked the
    // same way regardless of call order — that's the actual race: neither
    // caller sees the other's write yet). Only the first write actually
    // matches the WHERE clause; the second affects 0 rows.
    tx.questSubmission.updateMany
      .mockResolvedValueOnce({ count: 1 })
      .mockResolvedValueOnce({ count: 0 });

    const first = service.verifyQuestSubmission(
      { submissionId: 'submission-1' } as any,
      'admin-1',
      true,
    );
    const second = service.verifyQuestSubmission(
      { submissionId: 'submission-1' } as any,
      'admin-1',
      true,
    );

    const results = await Promise.allSettled([first, second]);

    expect(results[0].status).toBe('fulfilled');
    expect(results[1].status).toBe('rejected');
    if (results[1].status === 'rejected') {
      expect(results[1].reason).toBeInstanceOf(BadRequestException);
    }

    // This is the actual regression: before the fix, both calls could pass
    // the pre-transaction pending check and both send a notification.
    expect(notificationsService.notifyMany).toHaveBeenCalledTimes(1);
  });

  it('only the first of two near-simultaneous reject calls succeeds; only one notification is sent', async () => {
    tx.questSubmission.updateMany
      .mockResolvedValueOnce({ count: 1 })
      .mockResolvedValueOnce({ count: 0 });
    tx.userQuest.update.mockResolvedValue({});

    const results = await Promise.allSettled([
      service.verifyQuestSubmission(
        { submissionId: 'submission-1' } as any,
        'admin-1',
        false,
      ),
      service.verifyQuestSubmission(
        { submissionId: 'submission-1' } as any,
        'admin-1',
        false,
      ),
    ]);

    expect(results[0].status).toBe('fulfilled');
    expect(results[1].status).toBe('rejected');
    expect(notificationsService.notifyMany).toHaveBeenCalledTimes(1);
  });

  it('a normal single approve call still succeeds and sends exactly one notification', async () => {
    tx.questSubmission.updateMany.mockResolvedValue({ count: 1 });

    await service.verifyQuestSubmission(
      { submissionId: 'submission-1' } as any,
      'admin-1',
      true,
    );

    expect(notificationsService.notifyMany).toHaveBeenCalledTimes(1);
    expect(notificationsService.notifyMany).toHaveBeenCalledWith([
      expect.objectContaining({ type: 'quest_verified', userId: 'user-1' }),
    ]);
  });

  describe('F-52 quest BNP reaches the tip account', () => {
    const accountKey = {
      accountType_ownerRef_currencyCode: {
        accountType: 'user',
        ownerRef: 'user-1',
        currencyCode: 'BNP',
      },
    };

    it('an approved quest credits the BNP tip account by the reward', async () => {
      tx.questSubmission.updateMany.mockResolvedValue({ count: 1 });

      await service.verifyQuestSubmission(
        { submissionId: 'submission-1' } as any,
        'admin-1',
        true,
      );

      expect(tx.profile.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { miningClaimedPoints: { increment: 35n } },
        }),
      );
      expect(tx.tipAccount.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: accountKey,
          update: expect.objectContaining({
            balanceAtomic: { increment: 35_000n },
          }),
          create: expect.objectContaining({ balanceAtomic: 35_000n }),
        }),
      );
    });

    it('revoking a quest debits the tip account, never below zero', async () => {
      tx.miningPointLedger.findFirst.mockResolvedValue({ id: 'ledger-1' });
      tx.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 100n });
      tx.tipAccount.findUnique.mockResolvedValue({ balanceAtomic: 20_000n });
      tx.tipAccount.updateMany.mockResolvedValue({ count: 1 });

      await (service as any).revokeQuestRewards(
        tx,
        'user-1',
        questFixture,
        'submission-1',
        'fraud',
      );

      // 35 BNP reward, but only 20 BNP left after the member tipped some away.
      expect(tx.tipAccount.updateMany).toHaveBeenCalledWith({
        where: {
          accountType: 'user',
          ownerRef: 'user-1',
          currencyCode: 'BNP',
          balanceAtomic: { gte: 20_000n },
        },
        data: { balanceAtomic: { decrement: 20_000n } },
      });
    });
  });
});
