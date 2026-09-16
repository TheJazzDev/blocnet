import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { MiningPointSource, TipTransactionType } from '@prisma/client';
import { LevelsService } from '../levels/levels.service';
import { toPointsTransactionResponse } from '../wallet/wallet-points.mapper';
import type { CreateBnpAdjustmentDto } from './dto/create-bnp-adjustment.dto';
import {
  createFakeAdjustmentDb,
  type FakeProfile,
} from './mining-adjustment.fake';
import {
  ADMIN_ADJUSTMENT_AUDIT_ACTION,
  MiningAdjustmentService,
} from './mining-adjustment.service';

const ACTOR = '00000000-0000-4000-8000-00000000000a';
const MEMBER = '00000000-0000-4000-8000-00000000000b';
const KEY_1 = '11111111-1111-4111-8111-111111111111';
const KEY_2 = '22222222-2222-4222-8222-222222222222';
const REASON = 'Compensation for the outage on 12 Sep';

function profile(overrides: Partial<FakeProfile> = {}): FakeProfile {
  return {
    id: MEMBER,
    displayName: 'Member',
    username: 'member',
    isDeactivated: false,
    miningClaimedPoints: 100n,
    ...overrides,
  };
}

function dto(amount: number, idempotencyKey = KEY_1): CreateBnpAdjustmentDto {
  return { amount, reason: REASON, idempotencyKey };
}

describe('MiningAdjustmentService (F-66)', () => {
  let db: ReturnType<typeof createFakeAdjustmentDb>;
  let levels: { updateUserLevel: jest.Mock };
  let service: MiningAdjustmentService;

  function setup(member: FakeProfile = profile()) {
    db = createFakeAdjustmentDb([
      member,
      {
        id: ACTOR,
        displayName: 'Ada Admin',
        username: 'ada',
        isDeactivated: false,
        miningClaimedPoints: 0n,
      },
    ]);
    levels = { updateUserLevel: jest.fn().mockResolvedValue({}) };
    service = new MiningAdjustmentService(
      db.client as never,
      levels as unknown as LevelsService,
    );
  }

  beforeEach(() => setup());

  it('credits both balances, writes the ledger and tip rows, and recalculates the level', async () => {
    const result = await service.createAdjustment(ACTOR, MEMBER, dto(50));

    expect(db.profile(MEMBER).miningClaimedPoints).toBe(150n);
    // A new wallet is seeded from the 100 claimed, then credited 50.
    expect(db.walletAtomic(MEMBER)).toBe(150_000n);

    expect(db.state.ledger).toHaveLength(1);
    const ledger = db.state.ledger[0];
    expect(ledger).toMatchObject({
      id: result.id,
      userId: MEMBER,
      source: MiningPointSource.admin_adjustment,
      points: 50,
      metadata: expect.objectContaining({ reason: REASON, actorId: ACTOR }),
    });

    expect(db.state.tipTransactions).toEqual([
      expect.objectContaining({
        type: TipTransactionType.adjustment,
        contextType: 'admin_adjustment',
        contextId: result.id,
        idempotencyKey: `admin-adjustment:${KEY_1}`,
        note: REASON,
        amountAtomic: 50_000n,
      }),
    ]);

    expect(result).toMatchObject({
      amount: 50,
      reason: REASON,
      replayed: false,
      actor: { id: ACTOR, displayName: 'Ada Admin', username: 'ada' },
      balanceBefore: { claimedPoints: '100', walletBalance: '100' },
      balanceAfter: { claimedPoints: '150', walletBalance: '150' },
    });
    expect(levels.updateUserLevel).toHaveBeenCalledWith(MEMBER);
  });

  it('debits both balances', async () => {
    const result = await service.createAdjustment(ACTOR, MEMBER, dto(-40));

    expect(db.profile(MEMBER).miningClaimedPoints).toBe(60n);
    expect(db.walletAtomic(MEMBER)).toBe(60_000n);
    expect(db.state.ledger[0].points).toBe(-40);
    expect(db.state.tipTransactions[0]).toMatchObject({
      type: TipTransactionType.adjustment,
      amountAtomic: 40_000n,
      metadata: expect.objectContaining({ direction: 'debit' }),
    });
    expect(result.balanceAfter).toEqual({
      claimedPoints: '60',
      walletBalance: '60',
    });
  });

  it('rejects a debit larger than the wallet with 409 insufficient_balance and moves nothing', async () => {
    // The member tipped most of their BNP away: wallet 30.5 < claimed 100.
    db.setWalletAtomic(MEMBER, 30_500n);

    const error = await service
      .createAdjustment(ACTOR, MEMBER, dto(-40))
      .catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ConflictException);
    expect((error as ConflictException).getResponse()).toMatchObject({
      code: 'insufficient_balance',
      currentBalance: { claimedPoints: '100', walletBalance: '30.5' },
    });
    expect((error as ConflictException).message).toContain('30.5');
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(100n);
    expect(db.walletAtomic(MEMBER)).toBe(30_500n);
    expect(db.state.ledger).toHaveLength(0);
    expect(db.state.tipTransactions).toHaveLength(0);
    expect(db.state.auditLogs).toHaveLength(0);
    expect(levels.updateUserLevel).not.toHaveBeenCalled();
  });

  it('rejects a debit larger than the claimed points', async () => {
    setup(profile({ miningClaimedPoints: 10n }));
    db.setWalletAtomic(MEMBER, 500_000n);

    await expect(
      service.createAdjustment(ACTOR, MEMBER, dto(-11)),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(10n);
    expect(db.walletAtomic(MEMBER)).toBe(500_000n);
  });

  it('allows a debit down to exactly zero', async () => {
    await service.createAdjustment(ACTOR, MEMBER, dto(-100));

    expect(db.profile(MEMBER).miningClaimedPoints).toBe(0n);
    expect(db.walletAtomic(MEMBER)).toBe(0n);
  });

  it('returns the original result for a repeated idempotency key without moving BNP again', async () => {
    const first = await service.createAdjustment(ACTOR, MEMBER, dto(25));
    const second = await service.createAdjustment(ACTOR, MEMBER, dto(25));

    expect(second).toEqual({ ...first, replayed: true });
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(125n);
    expect(db.walletAtomic(MEMBER)).toBe(125_000n);
    expect(db.state.ledger).toHaveLength(1);
    expect(db.state.tipTransactions).toHaveLength(1);
    expect(db.state.auditLogs).toHaveLength(1);
  });

  it('treats a lost insert race on the key as a replay', async () => {
    const first = await service.createAdjustment(ACTOR, MEMBER, dto(25));
    // The pre-check misses (the other request had not committed yet), so the
    // tip row insert hits the unique key and the transaction rolls back.
    db.client.tipTransaction.findUnique.mockResolvedValueOnce(null);

    const second = await service.createAdjustment(ACTOR, MEMBER, dto(25));

    expect(second).toEqual({ ...first, replayed: true });
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(125n);
    expect(db.state.ledger).toHaveLength(1);
  });

  it('rejects a reused key with a different amount', async () => {
    await service.createAdjustment(ACTOR, MEMBER, dto(25));

    await expect(
      service.createAdjustment(ACTOR, MEMBER, dto(26)),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'idempotency_key_conflict' }),
    });
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(125n);
  });

  it('writes the audit row with actor, target, amount, reason and balances', async () => {
    const result = await service.createAdjustment(ACTOR, MEMBER, dto(-5));

    expect(db.state.auditLogs).toEqual([
      expect.objectContaining({
        actorId: ACTOR,
        action: ADMIN_ADJUSTMENT_AUDIT_ACTION,
        resourceType: 'profile',
        resourceId: MEMBER,
        metadata: {
          targetUserId: MEMBER,
          ledgerId: result.id,
          amount: -5,
          reason: REASON,
          idempotencyKey: KEY_1,
          balanceBefore: { claimedPoints: '100', walletBalance: '100' },
          balanceAfter: { claimedPoints: '95', walletBalance: '95' },
        },
      }),
    ]);
  });

  it('404s an unknown user', async () => {
    await expect(
      service.createAdjustment(
        ACTOR,
        '00000000-0000-4000-8000-0000000000ff',
        dto(5),
      ),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.listAdjustments('00000000-0000-4000-8000-0000000000ff', {}),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('refuses a deactivated member', async () => {
    setup(profile({ isDeactivated: true }));

    await expect(
      service.createAdjustment(ACTOR, MEMBER, dto(5)),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(db.state.ledger).toHaveLength(0);
  });

  it('keeps the adjustment when the level recalculation fails', async () => {
    levels.updateUserLevel.mockRejectedValue(new Error('boom'));

    await expect(
      service.createAdjustment(ACTOR, MEMBER, dto(5)),
    ).resolves.toMatchObject({ amount: 5 });
    expect(db.profile(MEMBER).miningClaimedPoints).toBe(105n);
  });

  it('lists the history newest first with the actor name', async () => {
    await service.createAdjustment(ACTOR, MEMBER, dto(5, KEY_1));
    await service.createAdjustment(ACTOR, MEMBER, dto(-3, KEY_2));

    const page = await service.listAdjustments(MEMBER, { limit: 1 });

    expect(page).toMatchObject({ total: 2, limit: 1, offset: 0 });
    expect(page.data).toHaveLength(1);
    expect(page.data[0]).toMatchObject({
      amount: -3,
      actor: { displayName: 'Ada Admin' },
      balanceAfter: { claimedPoints: '102' },
    });
  });

  it('shows up in the member wallet with the right direction', async () => {
    await service.createAdjustment(ACTOR, MEMBER, dto(5, KEY_1));
    await service.createAdjustment(ACTOR, MEMBER, dto(-3, KEY_2));
    const party = { id: MEMBER, username: 'member', displayName: 'Member' };

    const [credit, debit] = db.state.tipTransactions.map((row) =>
      toPointsTransactionResponse(MEMBER, {
        ...row,
        sender: party,
        recipient: party,
      } as never),
    );

    expect(credit).toMatchObject({
      direction: 'incoming',
      amount: '5',
      metadata: { label: 'Balance adjustment', note: REASON },
    });
    expect(debit).toMatchObject({ direction: 'outgoing', amount: '3' });
  });
});
