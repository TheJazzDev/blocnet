import { DigestCadence } from '@prisma/client';
import { NotificationDigestWorker } from './notification-digest.worker';

describe('NotificationDigestWorker', () => {
  const prisma = {
    profile: {
      findMany: jest.fn(),
    },
    userNotificationSettings: {
      upsert: jest.fn(),
    },
  };

  const configService = {
    get: jest.fn((key: string, defaultValue?: unknown) => {
      if (key === 'NOTIFICATION_DIGEST_ENABLED') return true;
      if (key === 'NOTIFICATION_DIGEST_SEND_WINDOW_MINUTES') return 10;
      if (key === 'NOTIFICATION_DIGEST_BATCH_SIZE') return 200;
      return defaultValue;
    }),
  };

  const usersService = {
    getDigestSummary: jest.fn(),
  };

  const digestComposer = {
    compose: jest.fn(),
  };

  const emailService = {
    sendDigestEmail: jest.fn(),
  };

  let worker: NotificationDigestWorker;

  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-25T08:02:00.000Z'));
    jest.clearAllMocks();
    worker = new NotificationDigestWorker(
      configService as any,
      prisma as any,
      usersService as any,
      digestComposer as any,
      emailService as any,
    );
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('sends digest and updates lastDigestSentAt when eligible', async () => {
    prisma.profile.findMany
      .mockResolvedValueOnce([
        {
          id: 'user-1',
          email: 'user1@example.com',
          displayName: 'User One',
          username: 'userone',
          notificationSettings: {
            digestEmailEnabled: true,
            digestCadence: DigestCadence.daily,
            digestHourLocal: 8,
            digestMinuteLocal: 0,
            timezone: 'UTC',
            lastDigestSentAt: null,
          },
        },
      ])
      .mockResolvedValueOnce([]);

    usersService.getDigestSummary.mockResolvedValue({
      missedHighUrgency: [],
      activeProjects: [
        { projectId: 'p-1', projectName: 'Bloc', newCount: 1, highCount: 0 },
      ],
      topCommunityPosts: [],
    });

    digestComposer.compose.mockReturnValue({
      hasContent: true,
      subject: 'Digest',
      html: '<p>Hi</p>',
      text: 'Hi',
      preheader: 'P',
    });

    emailService.sendDigestEmail.mockResolvedValue({
      delivered: true,
      skipped: false,
    });

    await worker.tick();

    expect(usersService.getDigestSummary).toHaveBeenCalledWith('user-1', 1, {
      skipAudit: true,
    });
    expect(emailService.sendDigestEmail).toHaveBeenCalledTimes(1);
    expect(prisma.userNotificationSettings.upsert).toHaveBeenCalledTimes(1);
  });

  it('skips send when composer indicates empty digest', async () => {
    prisma.profile.findMany
      .mockResolvedValueOnce([
        {
          id: 'user-2',
          email: 'user2@example.com',
          displayName: 'User Two',
          username: 'usertwo',
          notificationSettings: {
            digestEmailEnabled: true,
            digestCadence: DigestCadence.daily,
            digestHourLocal: 8,
            digestMinuteLocal: 0,
            timezone: 'UTC',
            lastDigestSentAt: null,
          },
        },
      ])
      .mockResolvedValueOnce([]);

    usersService.getDigestSummary.mockResolvedValue({
      missedHighUrgency: [],
      activeProjects: [],
      topCommunityPosts: [],
    });

    digestComposer.compose.mockReturnValue({
      hasContent: false,
      subject: 'Digest',
      html: '',
      text: '',
      preheader: 'P',
    });

    await worker.tick();

    expect(emailService.sendDigestEmail).not.toHaveBeenCalled();
    expect(prisma.userNotificationSettings.upsert).not.toHaveBeenCalled();
  });
});
