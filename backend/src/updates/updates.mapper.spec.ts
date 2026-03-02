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
  });
});
