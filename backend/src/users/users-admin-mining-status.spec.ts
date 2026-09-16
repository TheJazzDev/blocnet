import {
  DEFAULT_CLAIM_WINDOW_HOURS,
  deriveAdminMiningSessionStatus,
} from './users-admin-mining-status';

const HOUR = 60 * 60 * 1000;
const asOf = new Date('2026-09-16T12:00:00.000Z');
const hoursFromNow = (h: number) => new Date(asOf.getTime() + h * HOUR);

function session(
  endsInHours: number,
  overrides: { claimedAt?: Date | null; expiredAt?: Date | null } = {},
) {
  return {
    endsAt: hoursFromNow(endsInHours),
    claimedAt: overrides.claimedAt ?? null,
    expiredAt: overrides.expiredAt ?? null,
  };
}

describe('deriveAdminMiningSessionStatus (users-admin)', () => {
  it('is running before the cycle ends', () => {
    expect(deriveAdminMiningSessionStatus(session(3), asOf, 48)).toBe(
      'running',
    );
  });

  it('is claimable once ended and inside the claim window', () => {
    expect(deriveAdminMiningSessionStatus(session(-10), asOf, 48)).toBe(
      'claimable',
    );
  });

  it('is expired once the claim window has closed, even before the sweep', () => {
    expect(deriveAdminMiningSessionStatus(session(-49), asOf, 48)).toBe(
      'expired',
    );
  });

  it('is expired when the session was forfeited', () => {
    const forfeited = session(-1, { expiredAt: hoursFromNow(-0.5) });
    expect(deriveAdminMiningSessionStatus(forfeited, asOf, 48)).toBe('expired');
  });

  it('is claimed when claimedAt is set', () => {
    const claimed = session(-100, { claimedAt: hoursFromNow(-99) });
    expect(deriveAdminMiningSessionStatus(claimed, asOf, 48)).toBe('claimed');
  });

  it('honours the configured window rather than a fixed one', () => {
    expect(deriveAdminMiningSessionStatus(session(-30), asOf, 24)).toBe(
      'expired',
    );
    expect(
      deriveAdminMiningSessionStatus(
        session(-30),
        asOf,
        DEFAULT_CLAIM_WINDOW_HOURS,
      ),
    ).toBe('claimable');
  });
});
