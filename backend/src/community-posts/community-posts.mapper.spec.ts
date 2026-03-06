import {
  toCommunityPostCommentResponse,
  toCommunityPostResponse,
  type CommunityPostCommentWithAuthor,
  type CommunityPostWithViewerState,
} from './community-posts.mapper';

describe('community-posts.mapper', () => {
  it('does not leak author email in public post payloads', () => {
    const post = {
      id: 'post-1',
      authorId: 'abc123def456',
      topic: 'general',
      content: 'hello',
      createdAt: new Date(),
      updatedAt: new Date(),
      _count: {
        reactions: 3,
        comments: 2,
      },
      reactions: [],
      bookmarks: [],
      comments: [],
      author: {
        id: 'abc123def456',
        email: 'person@example.com',
        username: null,
        displayName: null,
        avatarUrl: null,
        roles: [],
        primaryBadge: null,
      },
    } as unknown as CommunityPostWithViewerState;

    const response = toCommunityPostResponse(post);

    expect((response.author as any).email).toBeUndefined();
    expect(response.admin.name).toBe('Blocnet Member');
    expect(response.admin.username).toBe('@abc123');
    expect(response.commentsCount).toBe(2);
  });

  it('does not leak author email in public comment payloads', () => {
    const comment = {
      id: 'comment-1',
      postId: 'post-1',
      authorId: 'def456abc123',
      content: 'comment',
      createdAt: new Date(),
      updatedAt: new Date(),
      replyToId: null,
      replyTo: null,
      reactions: [],
      _count: {
        reactions: 0,
      },
      author: {
        id: 'def456abc123',
        email: 'commenter@example.com',
        username: null,
        displayName: null,
        avatarUrl: null,
        roles: [],
        primaryBadge: null,
      },
    } as unknown as CommunityPostCommentWithAuthor;

    const response = toCommunityPostCommentResponse(comment);

    expect((response.author as any).email).toBeUndefined();
    expect(response.admin.name).toBe('Blocnet Member');
    expect(response.admin.username).toBe('@def456');
  });
});
