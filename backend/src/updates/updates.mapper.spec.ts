import { toUpdateResponse, type UpdateWithRelations } from './updates.mapper';

describe('updates.mapper', () => {
  it('maps update payload for API responses', () => {
    const update = {
      id: 'update-1',
      projectId: 'project-1',
      authorId: 'user-1',
      title: 'Big update',
      contentMd: 'content',
      urgency: 'high',
      status: 'published',
      createdAt: new Date(),
      updatedAt: new Date(),
      author: {
        id: 'user-1',
        email: 'hunter@blocnet.io',
        username: 'hunter',
        displayName: 'Hunter',
        avatarUrl: 'https://example.com/h.png',
        roles: [{ role: 'hunter' }],
        primaryBadge: null,
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
      project: {
        id: 'project-1',
        name: 'Blocnet',
        description: 'desc',
        ownerAdminId: 'owner-1',
        createdAt: new Date(),
        primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      },
      secondaryTags: [
        { secondaryTag: { id: 'tag-2', name: 'DeFi', slug: 'defi' } },
      ],
      _count: {
        comments: 4,
      },
    } as unknown as UpdateWithRelations;

    const result = toUpdateResponse(update);

    expect(result.project.primaryTag).toBe('Layer 1');
    expect(result.secondaryTagIds).toEqual(['tag-2']);
    expect(result.admin.username).toBe('@hunter');
    expect(result.commentsCount).toBe(4);
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

  it('emits admin.currentLevel as null when the author has no level', () => {
    const update = {
      id: 'update-1',
      author: {
        id: 'user-1',
        username: 'hunter',
        displayName: 'Hunter',
        avatarUrl: null,
        roles: [],
        primaryBadge: null,
        currentLevel: null,
      },
      project: {
        id: 'project-1',
        name: 'Blocnet',
        description: 'desc',
        ownerAdminId: 'owner-1',
        createdAt: new Date(),
        primaryTag: { id: 'tag-1', name: 'Layer 1', slug: 'layer-1' },
      },
      secondaryTags: [],
      _count: { comments: 0 },
    } as unknown as UpdateWithRelations;

    expect(toUpdateResponse(update).admin.currentLevel).toBeNull();
  });
});
