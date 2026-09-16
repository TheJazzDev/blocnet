import { ProjectAssignmentsService } from './project-assignments.service';

const HUNTER = { id: 'hunter-1', email: 'h@blocnet.app', roles: [] } as any;

function invite(id: string, projectId: string) {
  return {
    id,
    projectId,
    hunterId: HUNTER.id,
    invitedBy: 'admin-1',
    note: null,
    kind: 'co_own',
    status: 'pending',
    reviewedBy: null,
    reviewedAt: null,
    createdAt: new Date('2026-09-10T00:00:00Z'),
    updatedAt: new Date('2026-09-10T00:00:00Z'),
    project: { id: projectId, name: projectId, slug: projectId },
    inviter: { id: 'admin-1', username: 'root', displayName: 'Root' },
  };
}

function createService() {
  const prisma = {
    projectHunterInvite: { findMany: jest.fn() },
    projectFollow: { groupBy: jest.fn().mockResolvedValue([]) },
    update: { groupBy: jest.fn().mockResolvedValue([]) },
  } as any;
  const service = new ProjectAssignmentsService(prisma, {} as any, {} as any);
  return { service, prisma };
}

describe('ProjectAssignmentsService.listMyInvites', () => {
  it('adds gem stats and the inviter in a fixed number of queries', async () => {
    const { service, prisma } = createService();
    prisma.projectHunterInvite.findMany.mockResolvedValue([
      invite('i1', 'p1'),
      invite('i2', 'p2'),
    ]);
    prisma.projectFollow.groupBy.mockResolvedValue([
      { projectId: 'p1', _count: { _all: 26 } },
    ]);
    prisma.update.groupBy.mockResolvedValue([
      {
        projectId: 'p1',
        _count: { _all: 4 },
        _max: { createdAt: new Date('2026-09-15T08:00:00Z') },
      },
    ]);

    const result = await service.listMyInvites(HUNTER, 'pending' as any);

    expect(result[0]).toMatchObject({
      id: 'i1',
      kind: 'co_own',
      project: {
        id: 'p1',
        name: 'p1',
        slug: 'p1',
        followersCount: 26,
        updatesCount: 4,
        lastUpdateAt: '2026-09-15T08:00:00.000Z',
      },
      inviter: { id: 'admin-1', username: 'root', displayName: 'Root' },
    });
    expect(result[1].project).toEqual({
      id: 'p2',
      name: 'p2',
      slug: 'p2',
      followersCount: 0,
      updatesCount: 0,
      lastUpdateAt: null,
    });

    const findArgs = prisma.projectHunterInvite.findMany.mock.calls[0][0];
    expect(findArgs.where).toEqual({ hunterId: 'hunter-1', status: 'pending' });
    expect(findArgs.include.inviter.select).toEqual({
      id: true,
      username: true,
      displayName: true,
    });
    expect(prisma.update.groupBy.mock.calls[0][0].where).toEqual({
      projectId: { in: ['p1', 'p2'] },
      status: 'published',
    });
    expect(prisma.projectFollow.groupBy).toHaveBeenCalledTimes(1);
    expect(prisma.update.groupBy).toHaveBeenCalledTimes(1);
  });

  it('skips the stats reads when there are no invites', async () => {
    const { service, prisma } = createService();
    prisma.projectHunterInvite.findMany.mockResolvedValue([]);
    await expect(service.listMyInvites(HUNTER)).resolves.toEqual([]);
    expect(prisma.projectFollow.groupBy).not.toHaveBeenCalled();
    expect(prisma.update.groupBy).not.toHaveBeenCalled();
  });
});
