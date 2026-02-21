import { NotificationType, Prisma, UpdateUrgency } from '@prisma/client';

export type NotificationEvent = {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  actorUserId?: string | null;
  projectId?: string | null;
  updateId?: string | null;
  urgency?: UpdateUrgency | null;
  payload?: Prisma.InputJsonValue | null;
  deeplink?: string | null;
  dedupeKey?: string | null;
  pushData?: Record<string, string | number | boolean | null | undefined>;
  skipSelfNotify?: boolean;
};

export type NotifyManyOptions = {
  push?: boolean;
};
