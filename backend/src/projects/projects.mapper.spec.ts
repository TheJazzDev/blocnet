import {
  toProjectResponse,
  type ProjectWithRelations,
} from './projects.mapper';

describe('projects.mapper', () => {
  it('maps project payload for API responses', () => {
    const project = {
      id: 'project-1',
      name: 'Blocnet',
      slug: 'blocnet',
      normalizedName: 'blocnet',
      symbol: 'BNT',
      websiteUrl: 'https://blocnet.io',
      websiteDomain: 'blocnet.io',
      description: 'desc',
      primaryTagId: 'tag-1',
      ownerAdminId: 'user-1',
      status: 'active',
      createdAt: new Date(),
      updatedAt: new Date(),
      primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      secondaryTags: [
        { secondaryTag: { id: 'tag-2', name: 'DeFi', slug: 'defi' } },
      ],
      ownerAdmin: {
        id: 'user-1',
        email: 'owner@blocnet.io',
        username: 'owner',
        displayName: 'Owner',
        avatarUrl: 'https://example.com/a.png',
        currentLevel: {
          id: 'level-3',
          slug: 'builder',
          name: 'Builder',
          description: 'Ships things',
          iconUrl: 'https://cdn.example/l3.png',
          level: 3,
          requiredBnp: BigInt(1000),
          requiredComments: 5,
          requiredDaysActive: 3,
          requiredQuests: 1,
          requiredUpdates: 2,
          requiredProjects: 1,
          color: '#123456',
          isActive: true,
          sortOrder: 3,
        },
      },
      _count: { follows: 8, updates: 11 },
    } as unknown as ProjectWithRelations;

    const result = toProjectResponse(project);

    expect(result.primaryTag).toBe('Layer 1');
    expect(result.secondaryTagIds).toEqual(['tag-2']);
    expect(result.followersCount).toBe(8);
    expect(result.updatesCount).toBe(11);
    expect(result.admin.username).toBe('@owner');
    expect(result.admin.currentLevel).toEqual({
      id: 'level-3',
      slug: 'builder',
      name: 'Builder',
      description: 'Ships things',
      iconUrl: 'https://cdn.example/l3.png',
      level: 3,
      requiredBnp: '1000',
      requiredComments: 5,
      requiredDaysActive: 3,
      requiredQuests: 1,
      requiredUpdates: 2,
      requiredProjects: 1,
      color: '#123456',
      isActive: true,
      sortOrder: 3,
    });
    expect(() => JSON.stringify(result)).not.toThrow();
  });

  it('emits admin.currentLevel as null when the owner has no level', () => {
    const project = {
      id: 'project-1',
      primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      secondaryTags: [],
      ownerAdmin: {
        id: 'user-1',
        email: 'owner@blocnet.io',
        username: 'owner',
        displayName: 'Owner',
        avatarUrl: null,
        currentLevel: null,
      },
      _count: { follows: 0, updates: 0 },
    } as unknown as ProjectWithRelations;

    expect(toProjectResponse(project).admin.currentLevel).toBeNull();
  });

  it('carries ownerReliability when given and never echoes hunters', () => {
    const project = {
      id: 'project-1',
      primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      secondaryTags: [],
      hunters: [{ hunterId: 'hunter-1' }],
      ownerAdmin: {
        id: 'user-1',
        email: 'owner@blocnet.io',
        username: 'owner',
        displayName: 'Owner',
        avatarUrl: null,
        currentLevel: null,
      },
      _count: { follows: 0, updates: 0 },
    } as unknown as ProjectWithRelations;

    const withReliability = toProjectResponse(project, {
      profileId: 'hunter-1',
      standing: 'reliable',
      coverage: 0.9,
    });
    expect(withReliability.ownerReliability).toEqual({
      profileId: 'hunter-1',
      standing: 'reliable',
      coverage: 0.9,
    });
    expect(withReliability).not.toHaveProperty('hunters');
    expect(toProjectResponse(project).ownerReliability).toBeNull();
  });

  it('carries the newest update time when given, else null', () => {
    const project = {
      id: 'project-1',
      primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      secondaryTags: [],
      hunters: [],
      ownerAdmin: {
        id: 'user-1',
        email: 'owner@blocnet.io',
        username: 'owner',
        displayName: 'Owner',
        avatarUrl: null,
        currentLevel: null,
      },
      _count: { follows: 0, updates: 1 },
    } as unknown as ProjectWithRelations;
    const at = new Date('2026-09-10T12:00:00Z');

    expect(toProjectResponse(project, null, at).lastUpdateAt).toBe(at);
    expect(toProjectResponse(project).lastUpdateAt).toBeNull();
  });
});
