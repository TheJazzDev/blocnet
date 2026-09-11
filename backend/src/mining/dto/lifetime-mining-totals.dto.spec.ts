import { buildLifetimeMiningTotals } from './lifetime-mining-totals.dto';

describe('buildLifetimeMiningTotals', () => {
  it('derives unclaimed from mined minus claimed', () => {
    const totals = buildLifetimeMiningTotals(1200, 450);

    expect(totals.lifetimeMinedBnp).toBe(1200);
    expect(totals.lifetimeClaimedBnp).toBe(450);
    expect(totals.lifetimeUnclaimedBnp).toBe(750);
  });

  it('treats null aggregates as zero and never goes negative', () => {
    expect(buildLifetimeMiningTotals(null, undefined)).toMatchObject({
      lifetimeMinedBnp: 0,
      lifetimeClaimedBnp: 0,
      lifetimeUnclaimedBnp: 0,
    });
    expect(buildLifetimeMiningTotals(10, 25).lifetimeUnclaimedBnp).toBe(0);
  });

  it('mirrors every value onto the deprecated *Mcr aliases', () => {
    const totals = buildLifetimeMiningTotals(1200, 450);

    expect(totals.lifetimeMinedMcr).toBe(totals.lifetimeMinedBnp);
    expect(totals.lifetimeClaimedMcr).toBe(totals.lifetimeClaimedBnp);
    expect(totals.lifetimeUnclaimedMcr).toBe(totals.lifetimeUnclaimedBnp);
  });
});
