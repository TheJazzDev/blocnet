import type { LifetimeMiningTotals } from './lifetime-mining-totals.dto';

/** Response shape of GET /admin/mining/metrics. */
export interface MiningAdminMetricsResponse extends LifetimeMiningTotals {
  asOf: Date;
  dauMiners: number;
  startsDay: number;
  claimsDay: number;
  averageBoostBps: number;
  referralBindRate: number;
  activeReferralRatio: number;
  totalDirectReferrals: number;
  activeDirectReferrals: number;
  totalMiners: number;
}
