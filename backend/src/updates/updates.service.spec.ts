import { Test } from '@nestjs/testing';
import { AuditLogService } from '../audit-log/audit-log.service';
import { BadgesService } from '../badges/badges.service';
import { BlocksService } from '../blocks/blocks.service';
import { FcmService } from '../notifications/fcm.service';
import { LevelsService } from '../levels/levels.service';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { QuestsService } from '../quests/quests.service';
import { AppRole } from '../common/enums/role.enum';
import { UpdatesService } from './updates.service';

const ACTOR = {
  id: '6d1f3c2a-8b4e-4f6a-9c1d-2e3f4a5b6c7d',
  email: 'member@example.com',
  roles: [AppRole.USER],
} as never;

/**
 * Query-shape check for the feed read.
 *
 * `updateInclude` pulls author (+roles, +primaryBadge, +currentLevel), project
 * (+primaryTag) and secondaryTags. Under Prisma's default relation strategy
 * each of those is its own round trip — measured at 8 for one feed page, on top
 * of the blocked-ids and commented-ids reads, so 10 in total. With a database
 * that is not co-located that is ten times the network latency for one screen.
 * `relationLoadStrategy: 'join'` collapses the eight into a single lateral join
 * and returns a byte-identical payload.
 */
describe('UpdatesService.listUpdates', () => {
  const prisma = {
    update: { findMany: jest.fn(), findFirst: jest.fn() },
    comment: { findMany: jest.fn() },
  };
  const blocksService = { getBlockedUserIds: jest.fn() };

  let service: UpdatesService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        UpdatesService,
        { provide: PrismaService, useValue: prisma },
        { provide: BlocksService, useValue: blocksService },
        { provide: NotificationsService, useValue: {} },
        { provide: AuditLogService, useValue: {} },
        { provide: BadgesService, useValue: {} },
        { provide: FcmService, useValue: {} },
        { provide: QuestsService, useValue: {} },
        { provide: LevelsService, useValue: {} },
      ],
    }).compile();

    service = moduleRef.get(UpdatesService);
  });

  beforeEach(() => {
    jest.clearAllMocks();
    blocksService.getBlockedUserIds.mockResolvedValue([]);
    prisma.update.findMany.mockResolvedValue([]);
    prisma.comment.findMany.mockResolvedValue([]);
  });

  it('reads the feed relations in one join instead of a query per relation', async () => {
    await service.listUpdates(ACTOR, { limit: 20, offset: 0 });

    expect(prisma.update.findMany).toHaveBeenCalledTimes(1);
    expect(prisma.update.findMany.mock.calls[0][0]).toMatchObject({
      relationLoadStrategy: 'join',
    });
  });

  it('still scopes, orders and pages the feed the same way', async () => {
    await service.listUpdates(ACTOR, { limit: 20, offset: 40 });

    expect(prisma.update.findMany.mock.calls[0][0]).toMatchObject({
      orderBy: { createdAt: 'desc' },
      skip: 40,
      take: 20,
    });
  });

  it('still excludes updates from blocked authors', async () => {
    blocksService.getBlockedUserIds.mockResolvedValue(['blocked-user']);

    await service.listUpdates(ACTOR, { limit: 20, offset: 0 });

    expect(prisma.update.findMany.mock.calls[0][0].where).toMatchObject({
      authorId: { notIn: ['blocked-user'] },
    });
  });

  it('does not query commented ids when the page is empty', async () => {
    await service.listUpdates(ACTOR, { limit: 20, offset: 0 });

    expect(prisma.comment.findMany).not.toHaveBeenCalled();
  });

  describe('getUpdate', () => {
    beforeEach(() => {
      prisma.update.findFirst.mockResolvedValue({
        id: 'update-1',
        title: 'An update',
        contentMd: 'body',
        urgency: 'normal',
        status: 'published',
        createdAt: new Date(0),
        updatedAt: new Date(0),
        projectId: 'project-1',
        authorId: 'author-1',
        author: {
          id: 'author-1',
          email: 'author@example.com',
          username: 'author',
          displayName: 'Author',
          avatarUrl: null,
          roles: [],
          primaryBadge: null,
          currentLevel: null,
        },
        project: {
          id: 'project-1',
          name: 'Project',
          description: '',
          primaryTag: { id: 'tag-1', name: 'Tag', slug: 'tag' },
          ownerAdminId: 'author-1',
          createdAt: new Date(0),
        },
        secondaryTags: [],
      });
    });

    it('reads the detail relations in one join too', async () => {
      await service.getUpdate(ACTOR, 'update-1');

      expect(prisma.update.findFirst.mock.calls[0][0]).toMatchObject({
        relationLoadStrategy: 'join',
      });
    });

    it('still refuses an update from a blocked author', async () => {
      blocksService.getBlockedUserIds.mockResolvedValue(['blocked-user']);

      await service.getUpdate(ACTOR, 'update-1');

      expect(prisma.update.findFirst.mock.calls[0][0].where).toMatchObject({
        id: 'update-1',
        authorId: { notIn: ['blocked-user'] },
      });
    });
  });
});
