export type TipCurrencyKind = "points" | "token";
export type TipDirection = "all" | "sent" | "received";

export interface TipFeePolicy {
  feeBps: number;
  minTipAtomic: string;
  minTip: string;
  maxTipAtomic: string | null;
  maxTip: string | null;
  minFeeAtomic: string;
  minFee: string;
  maxFeeAtomic: string | null;
  maxFee: string | null;
  senderPaysFee: boolean;
  isActive: boolean;
}

export interface AdminTipCurrencySettings {
  code: string;
  name: string;
  symbol: string;
  decimals: number;
  kind: TipCurrencyKind;
  isEnabled: boolean;
  isActiveTippingCurrency: boolean;
  feePolicy: TipFeePolicy | null;
  feeVaultBalanceAtomic: string;
  feeVaultBalance: string;
}

export interface AdminTipSettings {
  activeCurrencyCode: string | null;
  currencies: AdminTipCurrencySettings[];
}

export interface TipUserPreview {
  id: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
}

export interface AdminTipTransaction {
  id: string;
  type: "tip" | "conversion" | "adjustment";
  direction: "sent" | "received" | "neutral";
  currency: {
    code: string;
    name: string;
    symbol: string;
    decimals: number;
  };
  amountAtomic: string;
  amount: string;
  feeAtomic: string;
  fee: string;
  totalDebitAtomic: string;
  totalDebit: string;
  sender: TipUserPreview;
  recipient: TipUserPreview;
  note: string | null;
  contextType: string | null;
  contextId: string | null;
  metadata: Record<string, unknown> | null;
  createdAt: string;
}

export interface AdminTipTransactionsResponse {
  data: AdminTipTransaction[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminMiningConfig {
  enabled: boolean;
  referralsEnabled: boolean;
  cycleHours: number;
  basePointsPerCycle: number;
  perActiveReferralBoostBps: number;
  maxBoostBps: number;
  activeReferralWindowHours: number;
  referralBindWindowHours: number;
}

export interface AdminMiningMetrics {
  asOf: string;
  dauMiners: number;
  startsDay: number;
  claimsDay: number;
  averageBoostBps: number;
  referralBindRate: number;
  activeReferralRatio: number;
  totalDirectReferrals: number;
  activeDirectReferrals: number;
  lifetimeMinedMcr: number;
  lifetimeClaimedMcr: number;
  lifetimeUnclaimedMcr: number;
  totalMiners: number;
}

export interface AdminMiningLeaderboardEntry {
  rank: number;
  userId: string;
  email?: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  claimedTotalPoints: number;
  maturedUnclaimedPoints: number;
  lifetimeEarnedPoints: number;
  sessionStatus: "idle" | "running" | "claimable";
  sessionProgressPct: number;
  sessionEndsAt: string | null;
  boostBpsSnapshot: number;
  activeReferralsSnapshot: number;
}

export interface AdminMiningLeaderboardResponse {
  asOf: string;
  total: number;
  limit: number;
  offset: number;
  data: AdminMiningLeaderboardEntry[];
}

export interface AdminBindReferralRequest {
  userIdOrEmail: string;
  code: string;
}

export interface AdminBindUserReferralRequest {
  code: string;
}

export interface AdminBindReferralResponse {
  ok: boolean;
  targetUser: {
    id: string;
    email: string;
    displayName: string | null;
  };
  referrer: {
    id: string;
    email: string;
    displayName: string | null;
    code: string | null;
  };
  referredAt: string;
  source: "admin_override";
}

