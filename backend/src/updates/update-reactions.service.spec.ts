import { NotFoundException } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AppRole } from '../common/enums/role.enum';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import type { PrismaService } from '../prisma/prisma.service';
import { ImportUpdateReactionsDto } from './dto/import-update-reactions.dto';
import { UpdateReactionsService } from './update-reactions.service';

const ACTOR = {
  id: '6d1f3c2a-8b4e-4f6a-9c1d-2e3f4a5b6c7d',
  email: 'member@example.com',
  roles: [AppRole.USER],
} as AuthUser;
const UPDATE = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const GONE = '33333333-3333-4333-8333-333333333333';

function createService() {
  const prisma = {
    update: {
      findFirst: jest.fn().mockResolvedValue({ id: UPDATE }),
      findMany: jest.fn(),
    },
    updateLike: {
      createMany: jest.fn().mockResolvedValue({ count: 1 }),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      count: jest.fn().mockResolvedValue(4),
    },
    updateBookmark: {
      createMany: jest.fn().mockResolvedValue({ count: 1 }),
      deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      count: jest.fn().mockResolvedValue(2),
    },
  };
  const service = new UpdateReactionsService(
    prisma as unknown as PrismaService,
  );
  return { service, prisma };
}

describe('UpdateReactionsService', () => {
  describe('likes', () => {
    it('adds a like without tripping the unique key and returns the server count', async () => {
      const { service, prisma } = createService();

      await expect(service.like(ACTOR, UPDATE)).resolves.toEqual({
        liked: true,
        likesCount: 4,
      });
      expect(prisma.updateLike.createMany).toHaveBeenCalledWith({
        data: [{ updateId: UPDATE, userId: ACTOR.id }],
        skipDuplicates: true,
      });
      expect(prisma.updateLike.count).toHaveBeenCalledWith({
        where: { updateId: UPDATE },
      });
    });

    it('is idempotent: liking an already-liked update still answers liked', async () => {
      const { service, prisma } = createService();
      prisma.updateLike.createMany.mockResolvedValue({ count: 0 });

      await expect(service.like(ACTOR, UPDATE)).resolves.toMatchObject({
        liked: true,
      });
    });

    it('removes only this member’s like, and removing twice is a no-op', async () => {
      const { service, prisma } = createService();
      prisma.updateLike.deleteMany.mockResolvedValue({ count: 0 });
      prisma.updateLike.count.mockResolvedValue(3);

      await expect(service.unlike(ACTOR, UPDATE)).resolves.toEqual({
        liked: false,
        likesCount: 3,
      });
      expect(prisma.updateLike.deleteMany).toHaveBeenCalledWith({
        where: { updateId: UPDATE, userId: ACTOR.id },
      });
    });

    it('404s for an unknown or non-published update and writes nothing', async () => {
      const { service, prisma } = createService();
      prisma.update.findFirst.mockResolvedValue(null);

      await expect(service.like(ACTOR, UPDATE)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      await expect(service.unlike(ACTOR, UPDATE)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(prisma.update.findFirst).toHaveBeenCalledWith({
        where: { id: UPDATE, status: 'published' },
        select: { id: true },
      });
      expect(prisma.updateLike.createMany).not.toHaveBeenCalled();
      expect(prisma.updateLike.deleteMany).not.toHaveBeenCalled();
    });
  });

  describe('bookmarks', () => {
    it('saves idempotently and returns the save count', async () => {
      const { service, prisma } = createService();

      await expect(service.bookmark(ACTOR, UPDATE)).resolves.toEqual({
        bookmarked: true,
        bookmarksCount: 2,
      });
      expect(prisma.updateBookmark.createMany).toHaveBeenCalledWith({
        data: [{ updateId: UPDATE, userId: ACTOR.id }],
        skipDuplicates: true,
      });
    });

    it('unsaves idempotently', async () => {
      const { service, prisma } = createService();
      prisma.updateBookmark.count.mockResolvedValue(0);

      await expect(service.unbookmark(ACTOR, UPDATE)).resolves.toEqual({
        bookmarked: false,
        bookmarksCount: 0,
      });
      expect(prisma.updateBookmark.deleteMany).toHaveBeenCalledWith({
        where: { updateId: UPDATE, userId: ACTOR.id },
      });
    });

    it('404s for a non-published update', async () => {
      const { service, prisma } = createService();
      prisma.update.findFirst.mockResolvedValue(null);

      await expect(service.bookmark(ACTOR, UPDATE)).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(prisma.updateBookmark.createMany).not.toHaveBeenCalled();
    });
  });

  describe('importReactions', () => {
    it('keeps only published updates, dedupes, and ignores non-uuid ids', async () => {
      const { service, prisma } = createService();
      prisma.update.findMany.mockResolvedValue([{ id: UPDATE }, { id: OTHER }]);
      prisma.updateLike.createMany.mockResolvedValue({ count: 1 });
      prisma.updateBookmark.createMany.mockResolvedValue({ count: 1 });

      const result = await service.importReactions(ACTOR, {
        likedUpdateIds: [UPDATE, UPDATE.toUpperCase(), GONE, 'mock-update-7'],
        bookmarkedUpdateIds: [OTHER],
      });

      expect(result).toEqual({ likesImported: 1, bookmarksImported: 1 });
      expect(prisma.update.findMany).toHaveBeenCalledWith({
        where: { id: { in: [UPDATE, GONE, OTHER] }, status: 'published' },
        select: { id: true },
      });
      expect(prisma.updateLike.createMany).toHaveBeenCalledWith({
        data: [{ updateId: UPDATE, userId: ACTOR.id }],
        skipDuplicates: true,
      });
      expect(prisma.updateBookmark.createMany).toHaveBeenCalledWith({
        data: [{ updateId: OTHER, userId: ACTOR.id }],
        skipDuplicates: true,
      });
    });

    it('reports zero on a repeat import (rows already held are skipped)', async () => {
      const { service, prisma } = createService();
      prisma.update.findMany.mockResolvedValue([{ id: UPDATE }]);
      prisma.updateLike.createMany.mockResolvedValue({ count: 0 });

      await expect(
        service.importReactions(ACTOR, {
          likedUpdateIds: [UPDATE],
          bookmarkedUpdateIds: [],
        }),
      ).resolves.toEqual({ likesImported: 0, bookmarksImported: 0 });
      expect(prisma.updateBookmark.createMany).not.toHaveBeenCalled();
    });

    it('does not touch the database for an empty or all-garbage import', async () => {
      const { service, prisma } = createService();

      await expect(
        service.importReactions(ACTOR, {
          likedUpdateIds: ['not-a-uuid'],
          bookmarkedUpdateIds: [],
        }),
      ).resolves.toEqual({ likesImported: 0, bookmarksImported: 0 });
      expect(prisma.update.findMany).not.toHaveBeenCalled();
      expect(prisma.updateLike.createMany).not.toHaveBeenCalled();
    });
  });

  describe('ImportUpdateReactionsDto', () => {
    const errorsFor = (body: unknown) =>
      validate(plainToInstance(ImportUpdateReactionsDto, body));

    it('accepts up to 500 ids per list', async () => {
      const ids = Array.from({ length: 500 }, () => UPDATE);
      await expect(
        errorsFor({ likedUpdateIds: ids, bookmarkedUpdateIds: ids }),
      ).resolves.toHaveLength(0);
    });

    it('rejects a list over 500 ids', async () => {
      const ids = Array.from({ length: 501 }, () => UPDATE);
      const errors = await errorsFor({
        likedUpdateIds: ids,
        bookmarkedUpdateIds: [],
      });
      expect(errors.map((e) => e.property)).toEqual(['likedUpdateIds']);
    });

    it('rejects a missing list or non-string ids', async () => {
      const errors = await errorsFor({ likedUpdateIds: [1] });
      expect(errors.map((e) => e.property).sort()).toEqual([
        'bookmarkedUpdateIds',
        'likedUpdateIds',
      ]);
    });
  });
});
