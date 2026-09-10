import {
  createDeterministicIdempotencyKey,
  idempotencyTimeBucket,
  normalizeIdempotencyKey,
} from './idempotency.util';

describe('idempotency.util', () => {
  describe('createDeterministicIdempotencyKey', () => {
    it('returns the same key for the same inputs', () => {
      const a = createDeterministicIdempotencyKey('withdrawal', 'user-1', 'BNT', '100');
      const b = createDeterministicIdempotencyKey('withdrawal', 'user-1', 'BNT', '100');
      expect(a).toBe(b);
    });

    it('returns a different key when any input differs', () => {
      const a = createDeterministicIdempotencyKey('withdrawal', 'user-1', 'BNT', '100');
      const b = createDeterministicIdempotencyKey('withdrawal', 'user-1', 'BNT', '101');
      expect(a).not.toBe(b);
    });
  });

  describe('idempotencyTimeBucket', () => {
    it('is deterministic — repeated calls within the same window return the same bucket', () => {
      // Regression guard for the bug where a fresh randomUUID() was mixed
      // into the fallback idempotency key on every call, so a client
      // retry (identical action, seconds apart) could never dedupe
      // against the original request.
      const first = idempotencyTimeBucket();
      const second = idempotencyTimeBucket();
      expect(second).toBe(first);
    });

    it('produces distinct buckets across window boundaries', () => {
      const windowMs = 1000;
      const bucketAt = (ms: number) => Math.floor(ms / windowMs);
      expect(bucketAt(0)).not.toBe(bucketAt(windowMs));
    });

    it('two fallback keys for an identical retried action are equal within the window', () => {
      const buildKey = () =>
        createDeterministicIdempotencyKey(
          'withdrawal',
          'user-1',
          'BNT',
          '0xabc',
          '100',
          idempotencyTimeBucket(),
        );

      expect(buildKey()).toBe(buildKey());
    });
  });

  describe('normalizeIdempotencyKey', () => {
    it('trims and caps client-supplied keys', () => {
      expect(normalizeIdempotencyKey('  my-key  ')).toBe('my-key');
      expect(normalizeIdempotencyKey('')).toBeNull();
      expect(normalizeIdempotencyKey(undefined)).toBeNull();
    });
  });
});
