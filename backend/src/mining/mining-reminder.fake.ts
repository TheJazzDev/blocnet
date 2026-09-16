/* eslint-disable @typescript-eslint/require-await, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access -- test fake, same relaxations as *.spec.ts */
/**
 * In-memory stand-in for the Prisma slices the mining reminder sweep and the
 * real `NotificationsService` / `NotificationPreferencesService` touch.
 *
 * The notification table enforces `@@unique([userId, dedupeKey])` the way
 * Postgres does, so specs can prove that two sweeps never double-send.
 *
 * Excluded from the build via `tsconfig.build.json`.
 */

import type { NotificationCategory, NotificationType } from '@prisma/client';

export type ReminderSessionRow = {
  id: string;
  userId: string;
  endsAt: Date;
  claimedAt: Date | null;
  expiredAt: Date | null;
  effectivePointsPerCycle: number;
};

export type ReminderNotificationRow = {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  deeplink: string | null;
  dedupeKey: string | null;
  payload: unknown;
};

type DateRange = { lt?: Date; lte?: Date; gt?: Date; gte?: Date };

function inRange(value: Date, range: DateRange | undefined): boolean {
  if (!range) return true;
  const ms = value.getTime();
  if (range.lt && !(ms < range.lt.getTime())) return false;
  if (range.lte && !(ms <= range.lte.getTime())) return false;
  if (range.gt && !(ms > range.gt.getTime())) return false;
  if (range.gte && !(ms >= range.gte.getTime())) return false;
  return true;
}

function matchesIn<T>(value: T, filter: { in?: T[]; notIn?: T[] } | T) {
  if (filter === undefined) return true;
  if (filter !== null && typeof filter === 'object') {
    const f = filter as { in?: T[]; notIn?: T[] };
    if (f.in && !f.in.includes(value)) return false;
    if (f.notIn && f.notIn.includes(value)) return false;
    return true;
  }
  return value === filter;
}

export function createFakeReminderDb(sessions: ReminderSessionRow[] = []) {
  const notifications: ReminderNotificationRow[] = [];
  const categoryPreferences: Array<{
    userId: string;
    category: NotificationCategory;
    enabled: boolean;
  }> = [];
  const typeOverrides: Array<{
    userId: string;
    type: NotificationType;
    enabled: boolean;
  }> = [];
  const settings: Array<{ userId: string; masterEnabled: boolean }> = [];

  const selectSessions = (where: any = {}) =>
    sessions.filter(
      (row) =>
        matchesIn(row.userId, where.userId) &&
        (where.claimedAt !== null || row.claimedAt === null) &&
        (where.expiredAt !== null || row.expiredAt === null) &&
        inRange(row.endsAt, where.endsAt),
    );

  const byUser = (where: any) => (row: { userId: string }) =>
    matchesIn(row.userId, where?.userId);

  const client = {
    miningSession: {
      findMany: jest.fn(async (args: any = {}) => {
        let rows = [...selectSessions(args.where)].sort((a, b) =>
          a.id.localeCompare(b.id),
        );
        if (args.cursor?.id) {
          const index = rows.findIndex((row) => row.id === args.cursor.id);
          rows = rows.slice(index + (args.skip ?? 0));
        }
        if (args.distinct?.includes('userId')) {
          const seen = new Set<string>();
          rows = rows.filter((row) => {
            if (seen.has(row.userId)) return false;
            seen.add(row.userId);
            return true;
          });
        }
        if (typeof args.take === 'number') {
          rows = rows.slice(0, args.take);
        }
        return rows.map((row) => ({ ...row }));
      }),
    },
    notification: {
      findMany: jest.fn(async ({ where }: any) =>
        notifications
          .filter(
            (row) =>
              matchesIn(row.userId, where?.userId) &&
              matchesIn(row.dedupeKey, where?.dedupeKey),
          )
          .map((row) => ({ userId: row.userId, dedupeKey: row.dedupeKey })),
      ),
      createMany: jest.fn(async ({ data }: any) => {
        notifications.push(...data);
        return { count: data.length };
      }),
      createManyAndReturn: jest.fn(async ({ data, skipDuplicates }: any) => {
        const created: Array<{ userId: string; dedupeKey: string | null }> = [];
        for (const row of data as ReminderNotificationRow[]) {
          const clash = notifications.some(
            (existing) =>
              existing.userId === row.userId &&
              existing.dedupeKey !== null &&
              existing.dedupeKey === row.dedupeKey,
          );
          if (clash) {
            if (skipDuplicates) continue;
            throw new Error('Unique constraint failed on (userId, dedupeKey)');
          }
          notifications.push(row);
          created.push({ userId: row.userId, dedupeKey: row.dedupeKey });
        }
        return created;
      }),
    },
    userNotificationSettings: {
      findMany: jest.fn(async ({ where }: any) =>
        settings.filter(byUser(where)).map((row) => ({
          ...row,
          digestEmailEnabled: true,
          digestCadence: 'daily',
          digestHourLocal: 8,
          digestMinuteLocal: 0,
          timezone: 'UTC',
          lastDigestSentAt: null,
        })),
      ),
    },
    userNotificationCategoryPreference: {
      findMany: jest.fn(async ({ where }: any) =>
        categoryPreferences.filter(byUser(where)),
      ),
    },
    userNotificationTypeOverride: {
      findMany: jest.fn(async ({ where }: any) =>
        typeOverrides.filter(byUser(where)),
      ),
    },
  };

  return {
    client,
    sessions,
    notifications,
    categoryPreferences,
    typeOverrides,
    settings,
  };
}
