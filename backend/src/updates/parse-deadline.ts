import { BadRequestException } from '@nestjs/common';

/**
 * How far ahead a hunter may set a window's closing time.
 *
 * Two years. Not a product rule so much as a guard against a typo in the year
 * turning into a deadline in 2125, which would sort to the end of every
 * "closing soon" list forever and never expire out of it.
 */
export const MAX_DEADLINE_AHEAD_MS = 2 * 365 * 24 * 60 * 60 * 1000;

/**
 * Turns the `deadlineAt` an API caller sent into something safe to store.
 *
 * A deadline in the *past* is allowed on purpose: a hunter may be reporting a
 * window that has already shut, and the product states that plainly ("Window
 * closed 9 days ago") rather than hiding it. What is rejected is a value that
 * cannot be a real closing time at all — unparseable, or absurdly far ahead.
 *
 * `null` and `''` both clear the field, because a client that binds an empty
 * form input should not have to know the difference.
 */
export function parseDeadline(
  value: string | null | undefined,
  now: Date = new Date(),
): Date | null {
  if (value === undefined || value === null) return null;
  const trimmed = value.trim();
  if (trimmed === '') return null;

  const parsed = new Date(trimmed);
  if (Number.isNaN(parsed.getTime())) {
    throw new BadRequestException('deadlineAt must be a valid date');
  }
  if (parsed.getTime() - now.getTime() > MAX_DEADLINE_AHEAD_MS) {
    throw new BadRequestException(
      'deadlineAt is too far in the future to be a real window',
    );
  }
  return parsed;
}
