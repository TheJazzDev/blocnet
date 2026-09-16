/**
 * Response shapes for the member-facing wallet reads (`/wallet/me`,
 * `/wallet/transactions`, `/wallet/withdrawals`). Pure functions.
 */
import {
  LedgerAccountType,
  LedgerReason,
  Prisma,
  WalletAsset,
  WithdrawalStatus,
  type LedgerEntry,
  type UserWallet,
} from '@prisma/client';
import { toDecimalString } from './types/decimal';
import { normalizeWalletAsset } from './wallet-asset.util';

/**
 * User-facing wallet block for `GET /wallet/me`.
 *
 * Custody internals stay out: `provider` and `providerWalletId` are the
 * custody provider's own identifiers and `failureReason` is a raw provider
 * error string. None of the three is actionable for the wallet owner, and
 * all three are operational detail that belongs on the admin surface only
 * (`GET /admin/wallet/*`, which serialises them separately in
 * `WalletAdminService`). `status` already tells a user whether their wallet
 * is provisioning, ready, errored or disabled.
 */
export function toWalletSummary(wallet: UserWallet) {
  return {
    id: wallet.id,
    status: wallet.status,
    address: wallet.address,
    chainId: wallet.chainId,
    chainEnvironment: wallet.chainEnvironment,
    provisionedAt: wallet.provisionedAt,
  };
}

export function toTransactionResponse(
  userId: string,
  entry: LedgerEntry & {
    debitAccount: {
      userId: string | null;
      accountType: LedgerAccountType;
      currency: string;
      user: {
        id: string;
        username: string | null;
        displayName: string | null;
      } | null;
      wallet: {
        address: string | null;
      } | null;
    };
    creditAccount: {
      userId: string | null;
      accountType: LedgerAccountType;
      currency: string;
      user: {
        id: string;
        username: string | null;
        displayName: string | null;
      } | null;
      wallet: {
        address: string | null;
      } | null;
    };
  },
) {
  const isDebit = entry.debitAccount.userId === userId;
  const isCredit = entry.creditAccount.userId === userId;
  const reason = entry.reason;

  let direction: 'outgoing' | 'incoming' | 'internal';
  if (
    reason === LedgerReason.withdrawal_hold ||
    reason === LedgerReason.withdrawal_finalize ||
    reason === LedgerReason.withdrawal_fee
  ) {
    direction = 'outgoing';
  } else if (reason === LedgerReason.withdrawal_reject_release) {
    direction = 'incoming';
  } else {
    direction =
      isDebit && !isCredit
        ? 'outgoing'
        : !isDebit && isCredit
          ? 'incoming'
          : 'internal';
  }

  const metadata = normalizeLedgerMetadata(entry.metadata);

  const asset =
    normalizeWalletAsset(entry.debitAccount.currency) ??
    normalizeWalletAsset(entry.creditAccount.currency) ??
    WalletAsset.BNT;

  const sourceAccount =
    direction === 'incoming'
      ? entry.debitAccount
      : direction === 'outgoing'
        ? entry.creditAccount
        : null;
  const counterparty =
    sourceAccount && sourceAccount.userId && sourceAccount.userId !== userId
      ? {
          userId: sourceAccount.userId,
          username: sourceAccount.user?.username ?? null,
          displayName: sourceAccount.user?.displayName ?? null,
          walletAddress: sourceAccount.wallet?.address ?? null,
        }
      : null;

  return {
    id: entry.id,
    asset,
    direction,
    reason,
    amount: toDecimalString(entry.amount),
    feeAmount: toDecimalString(entry.feeAmount),
    debit: {
      userId: entry.debitAccount.userId,
      accountType: entry.debitAccount.accountType,
    },
    credit: {
      userId: entry.creditAccount.userId,
      accountType: entry.creditAccount.accountType,
    },
    referenceId: entry.referenceId,
    metadata,
    counterparty,
    createdAt: entry.createdAt,
  };
}

export function normalizeLedgerMetadata(
  input: Prisma.JsonValue | null,
): Prisma.JsonObject | null {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return null;
  }
  return input;
}

export function toWithdrawalResponse(withdrawal: {
  id: string;
  asset: WalletAsset;
  toAddress: string;
  amount: Prisma.Decimal;
  feeAmount: Prisma.Decimal;
  netAmount: Prisma.Decimal;
  status: WithdrawalStatus;
  reason: string;
  rejectReason: string | null;
  broadcastTxHash: string | null;
  requestedAt: Date;
  reviewedAt: Date | null;
  confirmedAt: Date | null;
  failureReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: withdrawal.id,
    asset: withdrawal.asset,
    toAddress: withdrawal.toAddress,
    amount: toDecimalString(withdrawal.amount),
    feeAmount: toDecimalString(withdrawal.feeAmount),
    netAmount: toDecimalString(withdrawal.netAmount),
    status: withdrawal.status,
    reason: withdrawal.reason,
    rejectReason: withdrawal.rejectReason,
    broadcastTxHash: withdrawal.broadcastTxHash,
    failureReason: withdrawal.failureReason,
    requestedAt: withdrawal.requestedAt,
    reviewedAt: withdrawal.reviewedAt,
    confirmedAt: withdrawal.confirmedAt,
    createdAt: withdrawal.createdAt,
    updatedAt: withdrawal.updatedAt,
  };
}

export function getAssetLabel(asset: WalletAsset) {
  switch (asset) {
    case WalletAsset.BNB:
      return 'Binance Coin';
    case WalletAsset.USDT:
      return 'Tether';
    case WalletAsset.BNT:
    default:
      return 'Blocnet';
  }
}
