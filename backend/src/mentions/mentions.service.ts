import { Injectable, Logger } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class MentionsService {
  private readonly logger = new Logger(MentionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Extract @mentions from text content
   * Returns array of unique usernames (without the @ symbol)
   */
  extractMentions(content: string): string[] {
    // Match @username pattern (letters, numbers, dots, dashes, underscores)
    const mentionRegex = /@([a-zA-Z0-9._-]+)/g;
    const matches = content.matchAll(mentionRegex);
    const usernames = Array.from(matches, (m) => m[1]);

    // Return unique usernames
    return [...new Set(usernames)];
  }

  /**
   * Create mentions for a comment and send notifications
   */
  async createCommentMentions(
    commentId: string,
    content: string,
    authorId: string,
  ): Promise<void> {
    const usernames = this.extractMentions(content);

    if (usernames.length === 0) {
      return;
    }

    await this.processMentions(
      usernames,
      authorId,
      { commentId },
      'comment',
    );
  }

  /**
   * Create mentions for a community post and send notifications
   */
  async createCommunityPostMentions(
    communityPostId: string,
    content: string,
    authorId: string,
  ): Promise<void> {
    const usernames = this.extractMentions(content);

    if (usernames.length === 0) {
      return;
    }

    await this.processMentions(
      usernames,
      authorId,
      { communityPostId },
      'community_post',
    );
  }

  /**
   * Create mentions for a community post comment and send notifications
   */
  async createCommunityPostCommentMentions(
    communityPostCommentId: string,
    content: string,
    authorId: string,
  ): Promise<void> {
    const usernames = this.extractMentions(content);

    if (usernames.length === 0) {
      return;
    }

    await this.processMentions(
      usernames,
      authorId,
      { communityPostCommentId },
      'community_post_comment',
    );
  }

  /**
   * Search users by username for autocomplete
   */
  async searchUsers(query: string, limit = 10) {
    const normalizedQuery = query.toLowerCase().replace(/[^a-z0-9._-]/g, '');

    if (normalizedQuery.length === 0) {
      return [];
    }

    // Search by email prefix (username) or displayName
    const users = await this.prisma.profile.findMany({
      where: {
        OR: [
          {
            email: {
              startsWith: normalizedQuery,
              mode: 'insensitive',
            },
          },
          {
            displayName: {
              contains: normalizedQuery,
              mode: 'insensitive',
            },
          },
          {
            username: {
              contains: normalizedQuery,
              mode: 'insensitive',
            },
          },
        ],
        isDeactivated: false,
      },
      take: limit,
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
        avatarUrl: true,
      },
    });

    return users.map((user) => {
      const rawUsername = user.username || user.email?.split('@')[0] || user.id;
      const normalized = rawUsername
        .toLowerCase()
        .replace(/[^a-z0-9._-]/g, '')
        .trim();
      const username = normalized || user.id.slice(0, 6);

      return {
        id: user.id,
        username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
      };
    });
  }

  /**
   * Process mentions: lookup users, create mention records, send notifications
   */
  private async processMentions(
    usernames: string[],
    authorId: string,
    context:
      | { commentId: string }
      | { communityPostId: string }
      | { communityPostCommentId: string },
    contextType: 'comment' | 'community_post' | 'community_post_comment',
  ): Promise<void> {
    // Find users by username/email
    const users = await this.prisma.profile.findMany({
      where: {
        OR: usernames.map((username) => ({
          OR: [
            { email: { startsWith: username, mode: 'insensitive' } },
            { username: { equals: username, mode: 'insensitive' } },
          ],
        })),
        isDeactivated: false,
      },
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
      },
    });

    if (users.length === 0) {
      return;
    }

    // Get author info for notifications
    const author = await this.prisma.profile.findUnique({
      where: { id: authorId },
      select: {
        id: true,
        displayName: true,
        email: true,
      },
    });

    if (!author) {
      return;
    }

    const authorName = author.displayName || author.email || 'Someone';

    // Create mention records and notifications for each mentioned user
    for (const user of users) {
      // Don't mention yourself
      if (user.id === authorId) {
        continue;
      }

      try {
        // Create mention record
        await this.prisma.mention.create({
          data: {
            mentionedUserId: user.id,
            mentionText: `@${user.username || user.email?.split('@')[0] || user.id}`,
            ...context,
          },
        });

        // Send notification
        let title: string;
        let body: string;
        let deeplink: string;

        if ('commentId' in context) {
          title = 'You were mentioned';
          body = `${authorName} mentioned you in a comment`;
          deeplink = `/updates/comment/${context.commentId}`;
        } else if ('communityPostId' in context) {
          title = 'You were mentioned';
          body = `${authorName} mentioned you in a post`;
          deeplink = `/community/posts/${context.communityPostId}`;
        } else {
          title = 'You were mentioned';
          body = `${authorName} mentioned you in a comment`;
          deeplink = `/community/posts/comment/${context.communityPostCommentId}`;
        }

        await this.notificationsService.notifyMany([
          {
            userId: user.id,
            type: NotificationType.mention_received,
            actorUserId: authorId,
            title,
            body,
            deeplink,
            dedupeKey: `mention_${contextType}_${Object.values(context)[0]}_${user.id}`,
          },
        ]);
      } catch (error) {
        this.logger.warn(
          `Failed to create mention for user ${user.id}`,
          JSON.stringify({
            error: error instanceof Error ? error.message : String(error),
            contextType,
            context,
          }),
        );
      }
    }
  }
}
