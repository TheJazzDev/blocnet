import { MiningCalculatorService } from './mining-calculator.service';

const CONFIG = {
  enabled: true,
  referralsEnabled: true,
  cycleHours: 24,
  basePointsPerCycle: 120,
  perActiveReferralBoostBps: 500,
  maxBoostBps: 10000,
  activeReferralWindowHours: 168,
  referralBindWindowHours: 24,
  claimWindowHours: 48,
};

describe('MiningCalculatorService', () => {
  const calculator = new MiningCalculatorService();

  function cycleTotal(base: number, cycleHours: number, boostBps: number) {
    let total = 0;
    for (let hourIndex = 1; hourIndex <= cycleHours; hourIndex += 1) {
      total += calculator.computeHourlyCheckpointPoints(
        base,
        cycleHours,
        boostBps,
        hourIndex,
      );
    }
    return total;
  }

  describe('F-48 boost is not lost to rounding', () => {
    it.each([
      [0, 120],
      [1, 126],
      [2, 132],
      [3, 138],
      [4, 144],
    ])(
      'at 120/24h with %p active referrals a cycle pays exactly %p',
      (activeReferrals, expected) => {
        const boostBps = calculator.computeBoostBps(activeReferrals, CONFIG);

        expect(calculator.computeProjectedCyclePoints(120, boostBps)).toBe(
          expected,
        );
        expect(cycleTotal(120, 24, boostBps)).toBe(expected);
      },
    );

    it('pays the floor share every hour and the remainder in the final hour', () => {
      // 126 / 24 = 5 remainder 6.
      const boostBps = 500;
      const perHour = Array.from({ length: 24 }, (_, index) =>
        calculator.computeHourlyCheckpointPoints(120, 24, boostBps, index + 1),
      );

      expect(perHour.slice(0, 23).every((points) => points === 5)).toBe(true);
      expect(perHour[23]).toBe(11);
    });

    it('never pays a negative or out-of-range hour', () => {
      expect(calculator.computeHourlyCheckpointPoints(0, 24, 0, 24)).toBe(0);
      expect(calculator.computeHourlyCheckpointPoints(120, 24, 0, 25)).toBe(0);
      expect(calculator.computeHourlyCheckpointPoints(120, 24, 0, 0)).toBe(0);
    });
  });
});
