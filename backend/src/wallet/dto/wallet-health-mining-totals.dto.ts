import type { LifetimeMiningTotals } from '../../mining/dto/lifetime-mining-totals.dto';

/** `economy.mining` block of the wallet-admin health response. */
export type WalletHealthMiningTotals = LifetimeMiningTotals & {
  totalMiners: number;
};
