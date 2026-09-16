/** F-66 wire shapes. BigInt balances are serialized as strings. */
export type BnpAdjustmentBalances = {
  /** `Profile.miningClaimedPoints`, whole BNP. */
  claimedPoints: string;
  /** BNP wallet (tip account) balance, up to 3 decimals. */
  walletBalance: string;
};

export type BnpAdjustmentActor = {
  id: string;
  displayName: string | null;
  username: string | null;
};

export type BnpAdjustmentResponse = {
  id: string;
  userId: string;
  amount: number;
  reason: string;
  actor: BnpAdjustmentActor | null;
  balanceBefore: BnpAdjustmentBalances | null;
  balanceAfter: BnpAdjustmentBalances | null;
  createdAt: Date;
  /** True when this idempotency key was already applied; nothing moved. */
  replayed: boolean;
};

export type BnpAdjustmentListResponse = {
  total: number;
  limit: number;
  offset: number;
  data: BnpAdjustmentResponse[];
};
