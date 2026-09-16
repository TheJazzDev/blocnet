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
import { PrismaService } from '../prisma/prisma.service';
import { formatAtomicAmount } from '../tips/tip-amount.util';
import { ensureUserTipAccount } from '../tips/tip-ledger.util';
import { BNP_DECIMALS } from '../tips/tip.constants';
import {
  POINTS_ASSET,
  toPointsTransactionResponse,
} from './wallet-points.mapper';

export { POINTS_ASSET, toPointsTransactionResponse };

const partySelect = {
  id: true,
  username: true,
  displayName: true,
} as const;

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
   * The member's BNP movements (transfers in/out, tips sent/received, mining
   * and quest rewards, reward reversals), newest first, in the `GET /wallet/transactions` row shape. One query.
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
