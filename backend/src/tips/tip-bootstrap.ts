/**
 * Seeds the tip currencies (BNP active, BNT staged for launch), their fee
 * policies and fee vaults. Idempotent; run inside one transaction.
 */
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { ensureFeeVaultAccount } from './tip-ledger.util';
import { BNP_CURRENCY_CODE, BNP_DECIMALS } from './tip.constants';

export async function bootstrapTipDefaults(
  tx: Prisma.TransactionClient,
): Promise<void> {
  await tx.tipCurrency.upsert({
    where: { code: BNP_CURRENCY_CODE },
    update: {
      name: 'Blocnet Points',
      symbol: 'BNP',
      decimals: BNP_DECIMALS,
      kind: 'points',
      isEnabled: true,
    },
    create: {
      code: BNP_CURRENCY_CODE,
      name: 'Blocnet Points',
      symbol: 'BNP',
      decimals: BNP_DECIMALS,
      kind: 'points',
      isEnabled: true,
      isActiveTippingCurrency: true,
    },
  });

  await tx.tipCurrency.upsert({
    where: { code: 'BNT' },
    update: {
      name: 'BlocNet Token',
      symbol: 'BNT',
      decimals: 18,
      kind: 'token',
      isEnabled: true,
    },
    create: {
      code: 'BNT',
      name: 'BlocNet Token',
      symbol: 'BNT',
      decimals: 18,
      kind: 'token',
      isEnabled: true,
      isActiveTippingCurrency: false,
    },
  });

  await tx.tipFeeConfig.upsert({
    where: { currencyCode: BNP_CURRENCY_CODE },
    update: {},
    create: {
      currencyCode: BNP_CURRENCY_CODE,
      feeBps: 500,
      minTipAtomic: 1n,
      minFeeAtomic: 0n,
      senderPaysFee: true,
      isActive: true,
    },
  });

  await tx.tipFeeConfig.upsert({
    where: { currencyCode: 'BNT' },
    update: {},
    create: {
      currencyCode: 'BNT',
      feeBps: 500,
      minTipAtomic: 1000000000000000n,
      minFeeAtomic: 0n,
      senderPaysFee: true,
      isActive: true,
    },
  });

  await ensureFeeVaultAccount(tx, BNP_CURRENCY_CODE);
  await ensureFeeVaultAccount(tx, 'BNT');

  const activeCount = await tx.tipCurrency.count({
    where: {
      isActiveTippingCurrency: true,
      isEnabled: true,
    },
  });

  if (activeCount === 0) {
    await tx.tipCurrency.updateMany({
      where: { isActiveTippingCurrency: true },
      data: { isActiveTippingCurrency: false },
    });
    await tx.tipCurrency.update({
      where: { code: BNP_CURRENCY_CODE },
      data: { isActiveTippingCurrency: true },
    });
  }
}

/**
 * Runs `bootstrapTipDefaults` at most once concurrently per process; every
 * tip-ledger service awaits it before touching currencies or accounts.
 */
@Injectable()
export class TipBootstrapService {
  private pending: Promise<void> | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async ensure(): Promise<void> {
    if (!this.pending) {
      this.pending = this.prisma
        .$transaction((tx) => bootstrapTipDefaults(tx))
        .finally(() => {
          this.pending = null;
        });
    }
    await this.pending;
  }
}
