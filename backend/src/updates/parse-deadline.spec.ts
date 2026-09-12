import { BadRequestException } from '@nestjs/common';
import { MAX_DEADLINE_AHEAD_MS, parseDeadline } from './parse-deadline';

const now = new Date('2026-09-12T12:00:00.000Z');

describe('parseDeadline', () => {
  it('clears the field for null, undefined and an empty string', () => {
    // A client binding an empty form input should not have to know the
    // difference between these.
    expect(parseDeadline(undefined, now)).toBeNull();
    expect(parseDeadline(null, now)).toBeNull();
    expect(parseDeadline('', now)).toBeNull();
    expect(parseDeadline('   ', now)).toBeNull();
  });

  it('accepts an ISO timestamp and keeps the instant', () => {
    const parsed = parseDeadline('2026-09-19T18:00:00.000Z', now);
    expect(parsed?.toISOString()).toBe('2026-09-19T18:00:00.000Z');
  });

  it('accepts a deadline in the past', () => {
    // Deliberate. A hunter may be reporting a window that has already shut,
    // and the app states that rather than hiding it.
    const parsed = parseDeadline('2026-09-01T00:00:00.000Z', now);
    expect(parsed?.toISOString()).toBe('2026-09-01T00:00:00.000Z');
  });

  it('rejects a value that is not a date', () => {
    expect(() => parseDeadline('next friday', now)).toThrow(
      BadRequestException,
    );
    expect(() => parseDeadline('2026-13-45', now)).toThrow(
      BadRequestException,
    );
  });

  it('rejects a deadline absurdly far ahead', () => {
    // Guards a typo in the year, which would otherwise sort to the end of
    // every "closing soon" list and never expire out of it.
    const farFuture = new Date(
      now.getTime() + MAX_DEADLINE_AHEAD_MS + 60_000,
    ).toISOString();
    expect(() => parseDeadline(farFuture, now)).toThrow(BadRequestException);
  });

  it('accepts a deadline just inside the ceiling', () => {
    const justInside = new Date(
      now.getTime() + MAX_DEADLINE_AHEAD_MS - 60_000,
    ).toISOString();
    expect(parseDeadline(justInside, now)).toBeInstanceOf(Date);
  });

  it('trims surrounding whitespace before parsing', () => {
    const parsed = parseDeadline('  2026-09-19T18:00:00.000Z  ', now);
    expect(parsed?.toISOString()).toBe('2026-09-19T18:00:00.000Z');
  });
});
