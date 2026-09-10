import { createHash } from 'crypto';

export const IDEMPOTENCY_KEY_MAX_LENGTH = 128;

export function normalizeIdempotencyKey(
  value: string | undefined | null,
): string | null {
  if (!value) {
    return null;
  }

  const normalized = value.trim();
  if (!normalized) {
    return null;
  }

  return normalized.slice(0, IDEMPOTENCY_KEY_MAX_LENGTH);
}

export function createDeterministicIdempotencyKey(
  ...parts: Array<string | number | boolean | null | undefined>
): string {
  const payload = parts
    .map((part) => (part === null || part === undefined ? '' : String(part)))
    .join('|');

  return createHash('sha256').update(payload).digest('hex');
}

/**
 * Coarse time bucket for idempotency-key fallbacks. Two requests with
 * identical action/actor/amount fields that land in the same window are
 * treated as the same logical attempt (a retry), not two random UUIDs
 * that could never collide. Do not use randomUUID() here — it defeats
 * the entire point of a deterministic fallback key.
 */
export function idempotencyTimeBucket(windowMs = 2 * 60 * 1000): number {
  return Math.floor(Date.now() / windowMs);
}
