/**
 * BNP (Blocnet Points) as a wallet asset.
 *
 * BNP is off-chain: its balance and movements live in the tip ledger
 * (`TipAccount` / `TipTransaction`), not in custody. This service reads that
 * ledger and presents it in the wallet's own asset and transaction shapes, so
 * BNP shows (and moves) whatever the on-chain wallet status is. Transfers are
 * written by `TipTransfersService` (`POST /tips/transfers`).
 */
import { Injectable } from '@nestjs/common';
import { TipTransactionType, type TipTransaction } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { formatAtomicAmount } from '../tips/tip-amount.util';
import { ensureUserTipAccount } from '../tips/tip-ledger.util';
import { BNP_CURRENCY_CODE, BNP_DECIMALS } from '../tips/tip.constants';

export const POINTS_ASSET = BNP_CURRENCY_CODE;

/** Wallet transaction `reason` for each ledger row type. */
const POINTS_REASON: Record<TipTransactionType, string> = {
  [TipTransactionType.transfer]: 'bnp_transfer',
  [TipTransactionType.tip]: 'bnp_tip',
  [TipTransactionType.conversion]: 'bnp_conversion',
  [TipTransactionType.adjustment]: 'bnp_adjustment',
};

const POINTS_LABEL: Record<TipTransactionType, string> = {
  [TipTransactionType.transfer]: 'BNP transfer',
  [TipTransactionType.tip]: 'Tip',
  [TipTransactionType.conversion]: 'BNP conversion',
  [TipTransactionType.adjustment]: 'BNP adjustment',
};

const partySelect = {
  id: true,
  username: true,
  displayName: true,
} as const;

type PointsParty = {
  id: string;
  username: string | null;
  displayName: string | null;
};

type PointsTxRow = TipTransaction & {
  sender: PointsParty;
  recipient: PointsParty;
};

@Injectable()
export class WalletPointsService {
  constructor(private readonly prisma: PrismaService) {}

  /** The BNP entry for `GET /wallet/me` `assets`. */
  async getPointsAsset(userId: string) {
    const currency = await this.prisma.tipCurrency.findUnique({
      where: { code: POINTS_ASSET },
      select: { code: true, name: true, decimals: true, isEnabled: true },
    });
    const decimals = currency?.decimals ?? BNP_DECIMALS;
    // The currency row is seeded by tips/mining; until then there is no
    // account to read and nothing to move.
    const balanceAtomic = currency
      ? (await ensureUserTipAccount(this.prisma, userId, currency.code))
          .balanceAtomic
      : 0n;
    const enabled = currency?.isEnabled ?? false;

    return {
      asset: POINTS_ASSET,
      symbol: POINTS_ASSET,
      name: currency?.name ?? 'Blocnet Points',
      network: 'blocnet',
      assetKind: 'points',
      available: formatAtomicAmount(balanceAtomic, decimals),
      pending: '0',
      locked: '0',
      usdPrice: '0',
      usdValue: '0',
      priceSource: 'none',
      // Points-only fields.
      decimals,
      balanceAtomic: balanceAtomic.toString(),
      canSend: enabled,
      canReceive: enabled,
    };
  }

  /**
   * The member's BNP movements (transfers in/out, tips sent/received), newest
   * first, in the `GET /wallet/transactions` row shape. One query.
   */
  async listPointsTransactions(
    userId: string,
    page: { skip: number; take: number },
  ) {
    const rows = await this.prisma.tipTransaction.findMany({
      where: {
        currencyCode: POINTS_ASSET,
        OR: [{ senderUserId: userId }, { recipientUserId: userId }],
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      skip: page.skip,
      take: page.take,
      include: {
        sender: { select: partySelect },
        recipient: { select: partySelect },
      },
    });
    return rows.map((row) => toPointsTransactionResponse(userId, row));
  }
}

export function toPointsTransactionResponse(userId: string, row: PointsTxRow) {
  const isOutgoing = row.senderUserId === userId;
  const other = isOutgoing ? row.recipient : row.sender;
  // Only tips carry a fee. When the sender paid it the recipient got the full
  // amount; a recipient-pays tip (metadata.senderPaysFee === false) credited
  // amount minus fee.
  const recipientPaidFee =
    !!row.metadata &&
    typeof row.metadata === 'object' &&
    !Array.isArray(row.metadata) &&
    row.metadata.senderPaysFee === false;
  const feeAtomic = isOutgoing !== recipientPaidFee ? row.feeAtomic : 0n;
  const amountAtomic =
    !isOutgoing && recipientPaidFee
      ? row.amountAtomic - row.feeAtomic
      : row.amountAtomic;

  return {
    id: row.id,
    asset: POINTS_ASSET,
    direction: isOutgoing ? ('outgoing' as const) : ('incoming' as const),
    reason: POINTS_REASON[row.type],
    amount: formatAtomicAmount(amountAtomic, BNP_DECIMALS),
    feeAmount: formatAtomicAmount(feeAtomic, BNP_DECIMALS),
    debit: { userId: row.senderUserId, accountType: 'user' },
    credit: { userId: row.recipientUserId, accountType: 'user' },
    referenceId: row.id,
    metadata: {
      source: 'bnp_ledger',
      ledgerType: row.type,
      label: POINTS_LABEL[row.type],
      note: row.note,
      contextType: row.contextType,
      contextId: row.contextId,
    },
    counterparty: {
      userId: other.id,
      username: other.username,
      displayName: other.displayName,
      walletAddress: null,
    },
    createdAt: row.createdAt,
  };
}
