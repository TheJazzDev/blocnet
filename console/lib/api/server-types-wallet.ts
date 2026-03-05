export type WalletStatus = "provisioning" | "ready" | "error" | "disabled";
export type WalletKycStatus =
  | "not_submitted"
  | "pending"
  | "approved"
  | "rejected";
export type WalletWithdrawalStatus =
  | "requested"
  | "pending_review"
  | "approved"
  | "rejected"
  | "broadcasting"
  | "confirmed"
  | "failed"
  | "reverted";

export interface AdminWalletUser {
  id: string;
  email: string;
  displayName: string | null;
  username: string | null;
  roles: string[];
  createdAt: string;
  wallet: {
    id: string;
    status: WalletStatus;
    address: string | null;
    providerWalletId: string | null;
    chainId: number;
  } | null;
  balances: {
    available: string;
    pending: string;
    locked: string;
  } | null;
  kyc: {
    status: WalletKycStatus;
    tier: string;
    submittedAt: string | null;
    reviewedAt: string | null;
  } | null;
}

export interface AdminWalletUsersResponse {
  data: AdminWalletUser[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminWalletUserStatusResponse {
  user: {
    id: string;
    email: string;
    displayName: string | null;
  };
  wallet: {
    id: string;
    status: WalletStatus;
    address: string | null;
    providerWalletId: string | null;
    chainId: number;
    chainEnvironment: "testnet" | "mainnet";
    updatedAt: string;
  };
}

export interface AdminWalletWithdrawal {
  id: string;
  status: WalletWithdrawalStatus;
  toAddress: string;
  amount: string;
  feeAmount: string;
  netAmount: string;
  reason: string;
  rejectReason: string | null;
  failureReason: string | null;
  broadcastTxHash: string | null;
  confirmations: number;
  requester: {
    id: string;
    email: string;
    displayName: string | null;
  };
  reviewer: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  requestedAt: string;
  reviewedAt: string | null;
  confirmedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminWalletWithdrawalsResponse {
  data: AdminWalletWithdrawal[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminWalletKycRecord {
  id: string;
  userId: string;
  user: {
    id: string;
    email: string;
    displayName: string | null;
  };
  status: WalletKycStatus;
  tier: string;
  country: string | null;
  fullName: string | null;
  documentType: string | null;
  documentNumberLast4: string | null;
  documentUrl: string | null;
  submittedAt: string | null;
  reviewedAt: string | null;
  reviewNote: string | null;
  reviewer: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminWalletKycResponse {
  data: AdminWalletKycRecord[];
  total: number;
  limit: number;
  offset: number;
}

export interface WalletRiskLimit {
  id: string;
  tier: string;
  description: string | null;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
  createdAt: string;
  updatedAt: string;
}

export interface WalletFeeConfig {
  id: string;
  key: string;
  flatFee: string;
  percentFee: string;
  minFee: string;
  maxFee: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type WalletAssetCode = "BNT" | "BNB" | "USDT";

export interface WalletAssetPriceConfig {
  id: string;
  asset: WalletAssetCode;
  providerId: string | null;
  fallbackUsdPrice: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface WalletRuntimeConfig {
  id: string;
  walletEnabled: boolean;
  depositsEnabled: boolean;
  withdrawalsEnabled: boolean;
  depositRealtimeEnabled: boolean;
  bscRpcUrl: string | null;
  bscRpcWsUrl: string | null;
  depositConfirmations: number;
  withdrawalConfirmations: number;
  walletAssetBntEnabled: boolean;
  walletAssetBnbEnabled: boolean;
  walletAssetUsdtEnabled: boolean;
  withdrawalEnabledAssets: WalletAssetCode[];
  updatedAt: string;
}

export interface RuntimeFeatureFlagsConfig {
  id: string;
  closedAlphaEnabled: boolean;
  alphaRadarEnabled: boolean;
  followPrefsEnabled: boolean;
  weeklyDigestEnabled: boolean;
  miningEnabled: boolean;
  referralsEnabled: boolean;
  updatedAt: string;
}

export interface ClosedAlphaEmailRecord {
  id: string;
  email: string;
  emailNormalized: string;
  isActive: boolean;
  source: string;
  note: string | null;
  createdById: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ClosedAlphaEmailsResponse {
  data: ClosedAlphaEmailRecord[];
  total: number;
  limit: number;
  offset: number;
}
