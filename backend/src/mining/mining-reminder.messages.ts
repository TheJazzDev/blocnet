import { NotificationType, Prisma } from '@prisma/client';
import type { NotificationEvent } from '../notifications/types/notification-event.type';

export const MINING_DEEPLINK = '/mining';

/** A claim reminder switches from "ready" to "expiring" at this threshold. */
export const MINING_EXPIRING_THRESHOLD_HOURS = 6;

const HOUR_MS = 60 * 60 * 1000;

export type ReminderKind = 'ready' | 'expiring';

export type ReminderCandidate = {
  sessionId: string;
  userId: string;
  points: number;
  claimDeadline: Date;
};

export function reminderDedupeKey(kind: ReminderKind, sessionId: string) {
  return `mining.${kind}:${sessionId}`;
}

/**
 * Which reminder a claimable cycle is due, given how long its claim window
 * has left. `expiring` wins at or below the threshold, so a cycle first seen
 * late (server down, short window) gets the more urgent message only.
 */
export function reminderKindFor(claimDeadline: Date, asOf: Date): ReminderKind {
  const remainingMs = claimDeadline.getTime() - asOf.getTime();
  return remainingMs <= MINING_EXPIRING_THRESHOLD_HOURS * HOUR_MS
    ? 'expiring'
    : 'ready';
}

function hoursLeft(claimDeadline: Date, asOf: Date) {
  const remainingMs = claimDeadline.getTime() - asOf.getTime();
  return Math.max(1, Math.ceil(remainingMs / HOUR_MS));
}

export function buildReminderEvent(
  kind: ReminderKind,
  candidate: ReminderCandidate,
  asOf: Date,
): NotificationEvent {
  const type =
    kind === 'ready'
      ? NotificationType.mining_cycle_ready
      : NotificationType.mining_claim_expiring;
  const points = Math.max(candidate.points, 0);
  const hours = hoursLeft(candidate.claimDeadline, asOf);

  // Copy matches the approved Mine design (state 12): short, number first.
  const title =
    kind === 'ready'
      ? `${points} BNP ready to claim`
      : `${points} BNP expires in ${hours}h`;
  const body =
    kind === 'ready'
      ? 'Tap to claim and start your next cycle.'
      : "Claim it before it's gone.";

  return {
    userId: candidate.userId,
    type,
    actorUserId: null,
    title,
    body,
    payload: {
      sessionId: candidate.sessionId,
      points: String(points),
      claimDeadline: candidate.claimDeadline.toISOString(),
    } as Prisma.InputJsonValue,
    deeplink: MINING_DEEPLINK,
    dedupeKey: reminderDedupeKey(kind, candidate.sessionId),
    pushData: {
      type,
      sessionId: candidate.sessionId,
      target: MINING_DEEPLINK,
      deeplink: MINING_DEEPLINK,
    },
  };
}
