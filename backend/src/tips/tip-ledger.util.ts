/**
 * Account plumbing shared by every writer of the BNP/tip ledger (tips,
 * member-to-member transfers, admin settings). Both helpers are upserts, so
 * they are safe to call inside a transaction before reading a balance.
 */
import { Prisma, TipAccountType, type TipAccount } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { BNP_CURRENCY_CODE, FEE_VAULT_OWNER_REF } from './tip.constants';

export type TipTxClient = Prisma.TransactionClient | PrismaService;

/**
 * A member's ledger account for one currency. A BNP account created for the
 * first time is seeded from `Profile.miningClaimedPoints` so members who
 * mined before the ledger existed keep their points.
 */
export async function ensureUserTipAccount(
  tx: TipTxClient,
  userId: string,
  currencyCode: string,
): Promise<TipAccount> {
  let initialBalance = 0n;
  if (currencyCode === BNP_CURRENCY_CODE) {
    const profile = await tx.profile.findUnique({
      where: { id: userId },
      select: { miningClaimedPoints: true },
    });
    initialBalance = profile ? profile.miningClaimedPoints * 1000n : 0n;
  }

  return tx.tipAccount.upsert({
    where: {
      accountType_ownerRef_currencyCode: {
        accountType: TipAccountType.user,
        ownerRef: userId,
        currencyCode,
      },
    },
    update: { userId },
    create: {
      accountType: TipAccountType.user,
      ownerRef: userId,
      userId,
      currencyCode,
      balanceAtomic: initialBalance,
    },
  });
}

export async function ensureFeeVaultAccount(
  tx: TipTxClient,
  currencyCode: string,
): Promise<TipAccount> {
  return tx.tipAccount.upsert({
    where: {
      accountType_ownerRef_currencyCode: {
        accountType: TipAccountType.fee_vault,
        ownerRef: FEE_VAULT_OWNER_REF,
        currencyCode,
      },
    },
    update: {},
    create: {
      accountType: TipAccountType.fee_vault,
      ownerRef: FEE_VAULT_OWNER_REF,
      currencyCode,
      balanceAtomic: 0n,
    },
  });
}
