import { MyReportsService } from './my-reports.service';

describe('MyReportsService', () => {
  function createService() {
    const prisma = {
      communityModerationReport: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        groupBy: jest.fn().mockResolvedValue([]),
      },
    } as any;
    return { service: new MyReportsService(prisma), prisma };
  }

  it('only reads the caller’s own reports', async () => {
    const { service, prisma } = createService();

    await service.listMine('member-1', { status: 'open' } as any);

    const findArgs = prisma.communityModerationReport.findMany.mock.calls[0][0];
    expect(findArgs.where).toEqual(
      expect.objectContaining({ reporterId: 'member-1', status: 'open' }),
    );
    expect(prisma.communityModerationReport.count).toHaveBeenCalledWith({
      where: findArgs.where,
    });
    expect(
      prisma.communityModerationReport.groupBy.mock.calls[0][0].where,
    ).toEqual({ reporterId: 'member-1' });
  });

  it('never selects reviewer or target account details', async () => {
    const { service, prisma } = createService();

    await service.listMine('member-1', {} as any);

    const { select } =
      prisma.communityModerationReport.findMany.mock.calls[0][0];
    expect(select).toBeDefined();
    expect(select.reviewer).toBeUndefined();
    expect(select.reviewedById).toBeUndefined();
    expect(select.targetUser).toBeUndefined();
    expect(select.targetUserId).toBeUndefined();
    expect(select.reporter).toBeUndefined();
  });

  it('returns the page with counts for every status', async () => {
    const { service, prisma } = createService();
    const row = { id: 'r1', status: 'resolved' };
    prisma.communityModerationReport.findMany.mockResolvedValue([row]);
    prisma.communityModerationReport.count.mockResolvedValue(3);
    prisma.communityModerationReport.groupBy.mockResolvedValue([
      { status: 'open', _count: { _all: 2 } },
      { status: 'resolved', _count: { _all: 1 } },
    ]);

    const result = await service.listMine('member-1', {
      limit: 1,
      offset: 0,
    } as any);

    expect(result).toEqual({
      data: [row],
      total: 3,
      limit: 1,
      offset: 0,
      counts: { open: 2, resolved: 1, dismissed: 0 },
    });
  });
});
