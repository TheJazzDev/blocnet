import { ProjectStatus } from '@prisma/client';
import { ProjectsService } from './projects.service';

function project(id: string) {
  return {
    id,
    name: `Gem ${id}`,
    slug: `gem-${id}`,
    status: ProjectStatus.active,
    createdAt: new Date('2026-09-01T00:00:00Z'),
    updatedAt: new Date('2026-09-01T00:00:00Z'),
    primaryTag: { id: 't1', name: 'Solana' },
    secondaryTags: [],
    hunters: [],
    ownerAdmin: {
      id: 'owner-1',
      username: 'keeper',
      displayName: 'Keeper',
      avatarUrl: null,
      currentLevel: null,
    },
    _count: { follows: 3, updates: 2 },
  };
}

describe('ProjectsService.listFollowedProjects', () => {
  const lastUpdate = new Date('2026-09-15T10:00:00Z');
  const reliability = { profileId: 'h1', standing: 'reliable' };

  function setup() {
    const prisma = {
      projectFollow: {
        findMany: jest
          .fn()
          .mockResolvedValue([
            { project: project('p1') },
            { project: project('p2') },
          ]),
      },
    };
    const hunterReliability = {
      ownerReliabilityFor: jest
        .fn()
        .mockResolvedValue(new Map([['p1', reliability]])),
      lastUpdateAtFor: jest
        .fn()
        .mockResolvedValue(new Map([['p2', lastUpdate]])),
    };
    const service = new ProjectsService(
      prisma as never,
      {} as never,
      {} as never,
      hunterReliability as never,
    );
    return { prisma, hunterReliability, service };
  }

  it("reads only the caller's follows of visible gems, newest follow first", async () => {
    const { prisma, service } = setup();
    await service.listFollowedProjects('u1', { offset: 20, limit: 500 });

    const args = prisma.projectFollow.findMany.mock.calls[0][0];
    expect(args.where).toEqual({
      userId: 'u1',
      project: { status: { not: ProjectStatus.hidden } },
    });
    expect(args.orderBy).toEqual({ createdAt: 'desc' });
    expect(args.skip).toBe(20);
    expect(args.take).toBe(100);
  });

  it('carries reliability and the newest update time like the gem list', async () => {
    const { hunterReliability, service } = setup();
    const result = await service.listFollowedProjects('u1', {});

    expect(hunterReliability.lastUpdateAtFor).toHaveBeenCalledWith([
      'p1',
      'p2',
    ]);
    expect(result.map((p) => p.id)).toEqual(['p1', 'p2']);
    expect(result[0].ownerReliability).toEqual(reliability);
    expect(result[0].lastUpdateAt).toBeNull();
    expect(result[1].ownerReliability).toBeNull();
    expect(result[1].lastUpdateAt).toEqual(lastUpdate);
  });
});
