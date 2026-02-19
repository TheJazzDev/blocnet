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
