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
    miningPointLedger: { create: jest.fn() },
    profile: { update: jest.fn() },
    badge: { findUnique: jest.fn() },
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
});
