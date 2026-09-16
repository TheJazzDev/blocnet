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
    tipTransaction: { findUnique: jest.fn(), create: jest.fn() },
  };

  // In-memory TipTransaction table so idempotency is exercised for real.
  let tipRows: Array<Record<string, any>> = [];

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
    tx.miningPointLedger.create.mockResolvedValue({ id: 'ledger-new' });
    tx.tipAccount.upsert.mockResolvedValue({ id: 'acct-1' });
    tipRows = [];
    tx.tipTransaction.findUnique.mockImplementation(
      async ({ where }: any) =>
        tipRows.find((row) => row.idempotencyKey === where.idempotencyKey) ??
        null,
    );
    tx.tipTransaction.create.mockImplementation(async ({ data }: any) => {
      tipRows.push(data);
      return data;
    });
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

    // One approval, one BNP credit, one reward row.
    expect(tx.tipAccount.upsert).toHaveBeenCalledTimes(1);
    expect(tipRows).toHaveLength(1);
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
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 20_000n,
      });
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

    it('an approved quest writes exactly one reward row keyed by the submission', async () => {
      tx.questSubmission.updateMany.mockResolvedValue({ count: 1 });

      await service.verifyQuestSubmission(
        { submissionId: 'submission-1' } as any,
        'admin-1',
        true,
      );

      expect(tipRows).toEqual([
        expect.objectContaining({
          type: 'reward',
          senderUserId: 'user-1',
          recipientUserId: 'user-1',
          senderAccountId: 'acct-1',
          recipientAccountId: 'acct-1',
          currencyCode: 'BNP',
          amountAtomic: 35_000n,
          feeAtomic: 0n,
          totalDebitAtomic: 0n,
          contextType: 'quest_reward',
          contextId: 'submission-1',
          idempotencyKey: 'quest-reward:submission-1',
        }),
      ]);
    });

    it('a repeated award for the same submission neither credits nor writes again', async () => {
      const award = () =>
        (service as any).awardQuestRewards(tx, 'user-1', questFixture, {
          submissionId: 'submission-1',
        });

      await award();
      await award();

      expect(tx.tipAccount.upsert).toHaveBeenCalledTimes(1);
      expect(tipRows).toHaveLength(1);
    });

    it('an auto-completed quest keys its reward row by the ledger row', async () => {
      await (service as any).awardQuestRewards(tx, 'user-1', questFixture);

      expect(tipRows).toEqual([
        expect.objectContaining({
          type: 'reward',
          contextType: 'quest_reward',
          contextId: 'ledger-new',
          idempotencyKey: 'quest-reward:ledger:ledger-new',
        }),
      ]);
    });

    it('a revoke writes one adjustment row for the amount actually debited', async () => {
      tx.miningPointLedger.findFirst.mockResolvedValue({ id: 'ledger-1' });
      tx.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 100n });
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 20_000n,
      });
      tx.tipAccount.updateMany.mockResolvedValue({ count: 1 });

      const revoke = () =>
        (service as any).revokeQuestRewards(
          tx,
          'user-1',
          questFixture,
          'submission-1',
          'fraud',
        );
      await revoke();
      await revoke();

      expect(tx.tipAccount.updateMany).toHaveBeenCalledTimes(1);
      expect(tipRows).toEqual([
        expect.objectContaining({
          type: 'adjustment',
          senderUserId: 'user-1',
          recipientUserId: 'user-1',
          amountAtomic: 20_000n,
          contextType: 'quest_reward_revoked',
          contextId: 'submission-1',
          idempotencyKey: 'quest-reward-revoked:submission-1',
        }),
      ]);
    });

    it('a revoke that debits nothing writes no row', async () => {
      tx.miningPointLedger.findFirst.mockResolvedValue({ id: 'ledger-1' });
      tx.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 100n });
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 0n,
      });

      await (service as any).revokeQuestRewards(
        tx,
        'user-1',
        questFixture,
        'submission-1',
        'fraud',
      );

      expect(tipRows).toHaveLength(0);
    });

    it('only one of two concurrent revokes reverses the reward', async () => {
      prisma.questSubmission.findUnique.mockResolvedValue({
        ...submissionFixture,
        verificationStatus: 'approved',
      });
      tx.questSubmission.updateMany
        .mockResolvedValueOnce({ count: 1 })
        .mockResolvedValueOnce({ count: 0 });
      tx.userQuest.update.mockResolvedValue({});
      tx.miningPointLedger.findFirst.mockResolvedValue({ id: 'ledger-1' });
      tx.profile.findUnique.mockResolvedValue({ miningClaimedPoints: 100n });
      tx.tipAccount.findUnique.mockResolvedValue({
        id: 'acct-1',
        balanceAtomic: 90_000n,
      });
      tx.tipAccount.updateMany.mockResolvedValue({ count: 1 });

      const revoke = () =>
        service.revokeQuestSubmission('submission-1', 'admin-1', {
          revocationReason: 'fraud',
        } as any);
      const results = await Promise.allSettled([revoke(), revoke()]);

      expect(results.map((result) => result.status).sort()).toEqual([
        'fulfilled',
        'rejected',
      ]);
      expect(tx.questSubmission.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'submission-1', verificationStatus: 'approved' },
        }),
      );
      expect(tx.tipAccount.updateMany).toHaveBeenCalledTimes(1);
      expect(tipRows).toHaveLength(1);
    });
  });
});
