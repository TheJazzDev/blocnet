import { Injectable, NotFoundException } from '@nestjs/common';
import { UpdateStatus } from '@prisma/client';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import type { ImportUpdateReactionsDto } from './dto/import-update-reactions.dto';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type LikeState = { liked: boolean; likesCount: number };
export type BookmarkState = { bookmarked: boolean; bookmarksCount: number };
export type ImportResult = {
  likesImported: number;
  bookmarksImported: number;
};

/**
 * Likes and saves on updates.
 *
 * Every write is idempotent: adding uses `createMany({ skipDuplicates })` so a
 * double tap or a retry cannot trip the unique key, and removing uses
 * `deleteMany` so removing twice is a no-op. The returned count is read after
 * the write, so the client always shows what the server holds.
 *
 * Deliberately no audit entry and no notification: the audit log drives
 * notification fan-out, and a ping per like would be noise.
 */
@Injectable()
export class UpdateReactionsService {
  constructor(private readonly prisma: PrismaService) {}

  async like(actor: AuthUser, updateId: string): Promise<LikeState> {
    await this.assertPublished(updateId);
    await this.prisma.updateLike.createMany({
      data: [{ updateId, userId: actor.id }],
      skipDuplicates: true,
    });
    return {
      liked: true,
      likesCount: await this.prisma.updateLike.count({ where: { updateId } }),
    };
  }

  async unlike(actor: AuthUser, updateId: string): Promise<LikeState> {
    await this.assertPublished(updateId);
    await this.prisma.updateLike.deleteMany({
      where: { updateId, userId: actor.id },
    });
    return {
      liked: false,
      likesCount: await this.prisma.updateLike.count({ where: { updateId } }),
    };
  }

  async bookmark(actor: AuthUser, updateId: string): Promise<BookmarkState> {
    await this.assertPublished(updateId);
    await this.prisma.updateBookmark.createMany({
      data: [{ updateId, userId: actor.id }],
      skipDuplicates: true,
    });
    return {
      bookmarked: true,
      bookmarksCount: await this.prisma.updateBookmark.count({
        where: { updateId },
      }),
    };
  }

  async unbookmark(actor: AuthUser, updateId: string): Promise<BookmarkState> {
    await this.assertPublished(updateId);
    await this.prisma.updateBookmark.deleteMany({
      where: { updateId, userId: actor.id },
    });
    return {
      bookmarked: false,
      bookmarksCount: await this.prisma.updateBookmark.count({
        where: { updateId },
      }),
    };
  }

  /**
   * One-time move of the phone's local likes and saves. Ids that are not
   * published updates are dropped; ones already held are skipped. The counts
   * are rows actually inserted, so a repeat import reports 0.
   */
  async importReactions(
    actor: AuthUser,
    dto: ImportUpdateReactionsDto,
  ): Promise<ImportResult> {
    const liked = uniqueUuids(dto.likedUpdateIds);
    const bookmarked = uniqueUuids(dto.bookmarkedUpdateIds);
    const known = await this.publishedIds([
      ...new Set([...liked, ...bookmarked]),
    ]);

    const likeRows = liked
      .filter((id) => known.has(id))
      .map((updateId) => ({ updateId, userId: actor.id }));
    const bookmarkRows = bookmarked
      .filter((id) => known.has(id))
      .map((updateId) => ({ updateId, userId: actor.id }));

    const [likes, bookmarks] = await Promise.all([
      likeRows.length > 0
        ? this.prisma.updateLike.createMany({
            data: likeRows,
            skipDuplicates: true,
          })
        : { count: 0 },
      bookmarkRows.length > 0
        ? this.prisma.updateBookmark.createMany({
            data: bookmarkRows,
            skipDuplicates: true,
          })
        : { count: 0 },
    ]);

    return { likesImported: likes.count, bookmarksImported: bookmarks.count };
  }

  private async assertPublished(updateId: string): Promise<void> {
    const update = await this.prisma.update.findFirst({
      where: { id: updateId, status: UpdateStatus.published },
      select: { id: true },
    });
    if (!update) {
      throw new NotFoundException('Update not found');
    }
  }

  private async publishedIds(ids: string[]): Promise<Set<string>> {
    if (ids.length === 0) return new Set();
    const rows = await this.prisma.update.findMany({
      where: { id: { in: ids }, status: UpdateStatus.published },
      select: { id: true },
    });
    return new Set(rows.map((row) => row.id));
  }
}

/** Uuid-shaped ids only (anything else would fail the uuid cast), deduped. */
function uniqueUuids(ids: string[]): string[] {
  return [
    ...new Set(
      ids
        .map((id) => id.trim().toLowerCase())
        .filter((id) => UUID_PATTERN.test(id)),
    ),
  ];
}
