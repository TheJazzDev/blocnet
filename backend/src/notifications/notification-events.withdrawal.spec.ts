import { Prisma } from '@prisma/client';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { WITHDRAWAL_FAILED_MESSAGE } from '../wallet/withdrawal-failure';
import { NotificationEventsService } from './notification-events.service';

const RAW = 'Broadcast failed: HTTP request failed. Details: nonce too low';

function createService() {
  const prisma = {
    withdrawalRequest: {
      findUnique: jest.fn().mockResolvedValue({
        id: 'w-1',
        userId: 'user-1',
        amount: new Prisma.Decimal('10'),
        asset: 'BNT',
      }),
    },
  } as any;
  const config = { get: jest.fn().mockReturnValue(true) } as any;
  const notifications = { notifyMany: jest.fn().mockResolvedValue([]) };
  const service = new NotificationEventsService(
    prisma,
    config,
    notifications as any,
  );
  const sent = () => notifications.notifyMany.mock.calls[0]?.[0] ?? [];
  return { service, sent };
}

describe('NotificationEventsService - withdrawal failures (F-37)', () => {
  it('never puts the internal failure detail in the member notification', async () => {
    const { service, sent } = createService();

    await service.emitForAudit({
      action: FinancialAuditActions.WithdrawalReverted,
      actorId: 'user-1',
      resourceId: 'w-1',
      metadata: { reason: RAW, userMessage: WITHDRAWAL_FAILED_MESSAGE },
    });

    expect(sent()).toHaveLength(1);
    expect(sent()[0].payload.reason).toBe(WITHDRAWAL_FAILED_MESSAGE);
    expect(JSON.stringify(sent())).not.toContain('nonce too low');
  });

  it('keeps the reason an admin wrote when rejecting', async () => {
    const { service, sent } = createService();

    await service.emitForAudit({
      action: FinancialAuditActions.WithdrawalRejected,
      actorId: 'admin-1',
      resourceId: 'w-1',
      metadata: { reason: 'Please verify your identity first' },
    });

    expect(sent()[0].payload.reason).toBe('Please verify your identity first');
  });
});
