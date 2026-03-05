import type { TipCurrencyKind } from "./server-types-tips-mining";
import type { WalletAssetCode } from "./server-types-wallet";

export interface AdminWalletHealth {
  timestamp: string;
  flags: {
    walletEnabled: boolean;
    depositsEnabled: boolean;
    withdrawalsEnabled: boolean;
    turnkeyMode: string;
    turnkeyExecutionMode: string;
  };
  turnkey: {
    provider: string;
    mode: string;
    configured: {
      organizationId: boolean;
      apiPublicKey: boolean;
      apiPrivateKey: boolean;
      apiKeyId: boolean;
    };
    connectivity: {
      ok: boolean;
      simulated: boolean;
      organizationId?: string;
      organizationName?: string;
      userId?: string;
      username?: string;
      error: string | null;
    };
  };
  networks: Array<{
    chainEnvironment: "testnet" | "mainnet";
    chainId: number;
    rpcConfigured: boolean;
    rpcReachable: boolean;
    latestBlock: string | null;
    rpcError: string | null;
    tokenAddressConfigured: boolean;
    tokenAddress: string | null;
    treasuryWalletIdConfigured: boolean;
    treasurySweepAddressConfigured: boolean;
    confirmationsRequired: number;
    depositStartBlock: string | null;
  }>;
  counts: {
    walletsByStatus: Record<string, number>;
    depositsByStatus: Record<string, number>;
    sweepJobsByStatus: Record<string, number>;
    withdrawalsByStatus: Record<string, number>;
  };
  economy: {
    walletAssetHoldings: Array<{
      asset: string;
      accounts: number;
      totalAvailable: string;
      totalPending: string;
      totalLocked: string;
      totalBalance: string;
    }>;
    tipCurrencyTotals: Array<{
      currencyCode: string;
      symbol: string;
      decimals: number;
      kind: TipCurrencyKind;
      holders: number;
      transactions: number;
      totalUserBalanceAtomic: string;
      totalUserBalance: string;
      totalTippedAtomic: string;
      totalTipped: string;
      totalFeesAtomic: string;
      totalFees: string;
    }>;
    creditedDepositsTotals: Array<{
      asset: WalletAssetCode;
      count: number;
      totalAmount: string;
    }>;
    mining: {
      lifetimeMinedMcr: number;
      lifetimeClaimedMcr: number;
      lifetimeUnclaimedMcr: number;
      totalMiners: number;
    };
    quests: {
      rewardPointsTotal: number;
      rewardEventsTotal: number;
      rewardedUsersTotal: number;
      completedUserQuestsTotal: number;
      totalQuests: number;
      activeQuests: number;
      submissions: {
        pending: number;
        approved: number;
        rejected: number;
        total: number;
      };
    };
  };
}

export interface AdminWalletDepositReprocessNetworkResult {
  asset: WalletAssetCode;
  detectedCount: number;
  creditedCount: number;
  depositIds: string[];
  matched: boolean;
  reason?: string;
}

export interface AdminWalletDepositReprocessResponse {
  txHash: string;
  chainEnvironment: "testnet" | "mainnet";
  txBlockNumber: string;
  headBlockNumber: string;
  networkResults: AdminWalletDepositReprocessNetworkResult[];
  summary: {
    matchedAssets: number;
    detectedDeposits: number;
    creditedDeposits: number;
  };
}
