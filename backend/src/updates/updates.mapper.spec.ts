import {
  toUpdateResponse,
  updateIncludeFor,
  type UpdateWithRelations,
} from './updates.mapper';

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
        likes: 7,
        bookmarks: 2,
      },
      likes: [{ id: 'like-1' }],
      bookmarks: [],
    } as unknown as UpdateWithRelations;

    const result = toUpdateResponse(update);

    expect(result.project.primaryTag).toBe('Layer 1');
    expect(result.secondaryTagIds).toEqual(['tag-2']);
    expect(result.admin.username).toBe('@hunter');
    expect(result.commentsCount).toBe(4);
    expect(result.likesCount).toBe(7);
    expect(result.bookmarksCount).toBe(2);
    expect(result.likedByMe).toBe(true);
    expect(result.bookmarkedByMe).toBe(false);
    // The viewer rows only drive the flags; they are not echoed back.
    expect(result).not.toHaveProperty('likes');
    expect(result).not.toHaveProperty('bookmarks');
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

  it('reports no likes and no viewer flags when the include carries none', () => {
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

    const result = toUpdateResponse(update);
    expect(result.likesCount).toBe(0);
    expect(result.bookmarksCount).toBe(0);
    expect(result.likedByMe).toBe(false);
    expect(result.bookmarkedByMe).toBe(false);
  });

  it('scopes the viewer relations to the viewer and keeps them to one row', () => {
    const include = updateIncludeFor('viewer-1');
    expect(include.likes).toEqual({
      where: { userId: 'viewer-1' },
      select: { id: true },
      take: 1,
    });
    expect(include.bookmarks).toEqual(include.likes);
    expect(include._count.select).toEqual({
      comments: true,
      likes: true,
      bookmarks: true,
    });
  });
});
