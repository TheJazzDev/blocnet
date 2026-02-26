import {
  NotificationCategory,
  NotificationType,
  DigestCadence,
} from '@prisma/client';
import { NotificationPreferencesService } from './notification-preferences.service';

describe('NotificationPreferencesService', () => {
  const prisma = {
    profile: {
      findUnique: jest.fn(),
    },
    userNotificationSettings: {
      findMany: jest.fn(),
    },
    userNotificationCategoryPreference: {
      findMany: jest.fn(),
    },
    userNotificationTypeOverride: {
      findMany: jest.fn(),
    },
    $transaction: jest.fn(async (callback: any) => callback(prisma)),
  };

  let service: NotificationPreferencesService;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.profile.findUnique.mockResolvedValue({ id: 'user-1' });
    prisma.userNotificationSettings.findMany.mockResolvedValue([]);
    prisma.userNotificationCategoryPreference.findMany.mockResolvedValue([]);
    prisma.userNotificationTypeOverride.findMany.mockResolvedValue([]);
    service = new NotificationPreferencesService(prisma);
  });

  it('returns catalog with categories and critical types', async () => {
    const catalog = await service.getCatalog();
    expect(catalog.categories.length).toBeGreaterThan(0);
    expect(catalog.criticalTypes).toContain(NotificationType.role_changed);
  });

  it('returns defaults when user has no saved preference rows', async () => {
    const prefs = await service.getPreferences('user-1');

    expect(prefs.masterEnabled).toBe(true);
    expect(prefs.digestEmailEnabled).toBe(true);
    expect(prefs.digestCadence).toBe(DigestCadence.daily);
    expect(prefs.categories[NotificationCategory.wallet]).toBe(true);
  });

  it('filters non-critical events when a type override disables them', async () => {
    prisma.userNotificationTypeOverride.findMany.mockResolvedValue([
      {
        userId: 'user-1',
        type: NotificationType.wallet_transfer_received,
        enabled: false,
      },
    ]);

    const result = await service.filterEventsByPreference([
      {
        userId: 'user-1',
        type: NotificationType.wallet_transfer_received,
        title: 'Transfer',
        body: 'Body',
      },
      {
        userId: 'user-1',
        type: NotificationType.wallet_withdrawal_rejected,
        title: 'Rejected',
        body: 'Body',
      },
    ] as any);

    expect(result.deliverable).toHaveLength(1);
    expect(result.deliverable[0].type).toBe(
      NotificationType.wallet_withdrawal_rejected,
    );
    expect(result.suppressed).toHaveLength(1);
  });
});
