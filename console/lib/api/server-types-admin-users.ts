import type { WalletKycStatus, WalletStatus } from "./server-types-wallet";

export interface AdminMe {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  roles: string[];
}

export interface AdminStats {
  totalProjects: number;
  totalUsers: number;
  activeUsers: number;
  deactivatedUsers: number;
  pendingAdminApps: number;
  totalUpdates: number;
  totalComments: number;
  activeHunters: number;
  pendingProposals: number;
  totalTags: number;
  usersWithPushEnabled: number;
}

export type AdminUserStatus = "active" | "deactivated";

export interface AdminBadgeSummary {
  id: string;
  slug: string;
  name: string;
  imageUrl: string;
  category: string;
  rarity: string;
}

export interface AdminUser {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  isDeactivated: boolean;
  deactivatedAt: string | null;
  roles: string[];
  projectsAssigned: number;
  updatesPosted: number;
  badgesCount: number;
  primaryBadge: AdminBadgeSummary | null;
  createdAt: string;
}

export interface AdminUsersResponse {
  data: AdminUser[];
  total: number;
  limit: number;
  offset: number;
}

export interface AdminUserDetail {
  id: string;
  email: string;
  username: string | null;
  referralCode: string | null;
  referredAt: string | null;
  referredBy: {
    id: string;
    email: string;
    displayName: string | null;
    referralCode: string | null;
  } | null;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
  isDeactivated: boolean;
  deactivatedAt: string | null;
  deactivatedBy: string | null;
  deactivationReason: string | null;
  createdAt: string;
  updatedAt: string;
  roles: string[];
  primaryBadge: AdminBadgeSummary | null;
  badges: Array<{
    earnedAt: string;
    badge: AdminBadgeSummary;
  }>;
  wallet: {
    id: string;
    status: WalletStatus;
    address: string | null;
    providerWalletId: string | null;
    chainEnvironment: "testnet" | "mainnet";
    chainId: number;
    createdAt: string;
    updatedAt: string;
  } | null;
  kyc: {
    status: WalletKycStatus;
    tier: string;
    submittedAt: string | null;
    reviewedAt: string | null;
    reviewNote: string | null;
  } | null;
  tips: {
    accounts: Array<{
      id: string;
      accountType: "user" | "fee_vault";
      ownerRef: string;
      currencyCode: string;
      balanceAtomic: string;
      updatedAt: string;
      currency: {
        code: string;
        symbol: string;
        decimals: number;
        kind: "points" | "token";
        isEnabled: boolean;
      };
    }>;
    sentByCurrency: Array<{
      currencyCode: string;
      txCount: number;
      amountAtomic: string;
      feeAtomic: string;
      totalDebitAtomic: string;
      currency: {
        code: string;
        symbol: string;
        decimals: number;
        kind: "points" | "token";
        isEnabled: boolean;
      } | null;
    }>;
    receivedByCurrency: Array<{
      currencyCode: string;
      txCount: number;
      amountAtomic: string;
      currency: {
        code: string;
        symbol: string;
        decimals: number;
        kind: "points" | "token";
        isEnabled: boolean;
      } | null;
    }>;
    conversionsByPair: Array<{
      fromCurrencyCode: string;
      toCurrencyCode: string;
      txCount: number;
      amountInAtomic: string;
      amountOutAtomic: string;
      fromCurrency: {
        code: string;
        symbol: string;
        decimals: number;
        kind: "points" | "token";
        isEnabled: boolean;
      } | null;
      toCurrency: {
        code: string;
        symbol: string;
        decimals: number;
        kind: "points" | "token";
        isEnabled: boolean;
      } | null;
    }>;
  };
  counts: {
    directReferrals: number;
    followers: number;
    following: number;
    watchedProjects: number;
    bookmarks: number;
    updates: number;
    comments: number;
    communityPosts: number;
    communityComments: number;
    withdrawals: number;
    deviceTokens: number;
    badges: number;
    tipSent: number;
    tipReceived: number;
    tipConversions: number;
  };
  mining: {
    claimedTotalPoints: number;
    maturedUnclaimedPoints: number;
    lifetimeEarnedPoints: number;
    totalLedgerPoints: number;
    activeDirectReferrals: number;
    hourlyRateNow: number;
    activeSession: {
      id: string;
      startsAt: string;
      endsAt: string;
      claimedAt: string | null;
      status: "running" | "claimable" | "claimed";
      progressPct: number;
      basePointsPerCycle: number;
      effectivePointsPerCycle: number;
      boostBpsSnapshot: number;
      activeReferralsSnapshot: number;
      claimedPoints: number;
    } | null;
    recentSessions: Array<{
      id: string;
      startsAt: string;
      endsAt: string;
      claimedAt: string | null;
      status: "running" | "claimable" | "claimed";
      progressPct: number;
      basePointsPerCycle: number;
      effectivePointsPerCycle: number;
      boostBpsSnapshot: number;
      activeReferralsSnapshot: number;
      claimedPoints: number;
    }>;
  };
  quests: {
    totalQuests: number;
    activeQuests: number;
    userQuestCounts: {
      notStarted: number;
      inProgress: number;
      pendingVerification: number;
      completed: number;
    };
    submissions: {
      pending: number;
      approved: number;
      rejected: number;
      total: number;
    };
    rewardPointsTotal: number;
    rewardEventsTotal: number;
    recentProgress: Array<{
      userQuestId: string;
      questId: string;
      questSlug: string;
      questTitle: string;
      questCategory: string;
      status: "not_started" | "in_progress" | "pending_verification" | "completed";
      progress: number;
      rewardPoints: number;
      verificationMethod: string;
      isActive: boolean;
      startedAt: string | null;
      completedAt: string | null;
      updatedAt: string;
      lastSubmission: {
        verificationStatus: "pending" | "approved" | "rejected";
        submittedAt: string;
        verifiedAt: string | null;
        reviewNotes: string | null;
        rejectionReason: string | null;
      } | null;
    }>;
  };
}

export interface AdminDeleteUserResponse {
  deleted: boolean;
  reason?: string;
  userId?: string;
  deactivatedAt?: string;
}

export interface AdminReactivateUserResponse {
  reactivated: boolean;
  reason?: string;
  userId?: string;
  reactivatedAt?: string;
}

export interface AdminHardDeleteUserResponse {
  hardDeleted: boolean;
  userId?: string;
  deletedAt?: string;
}
