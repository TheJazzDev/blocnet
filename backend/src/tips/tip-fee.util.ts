/**
 * Tip fee arithmetic. Applies to `type: tip` only — member-to-member BNP
 * transfers carry no fee (see `TipTransfersService`).
 */
import { BadRequestException } from '@nestjs/common';
import type { TipCurrency, TipFeeConfig } from '@prisma/client';
import { ceilDivide, formatAtomicAmount } from './tip-amount.util';

export function calculateTipFeeAtomic(
  amountAtomic: bigint,
  feeConfig: TipFeeConfig,
): bigint {
  let feeAtomic = ceilDivide(amountAtomic * BigInt(feeConfig.feeBps), 10000n);
  if (feeAtomic < feeConfig.minFeeAtomic) {
    feeAtomic = feeConfig.minFeeAtomic;
  }
  if (feeConfig.maxFeeAtomic != null && feeAtomic > feeConfig.maxFeeAtomic) {
    feeAtomic = feeConfig.maxFeeAtomic;
  }
  return feeAtomic;
}

export function resolveTipRecipientCreditAtomic(
  amountAtomic: bigint,
  feeAtomic: bigint,
  feeConfig: TipFeeConfig,
): bigint {
  if (feeConfig.senderPaysFee) {
    return amountAtomic;
  }
  const net = amountAtomic - feeAtomic;
  if (net <= 0n) {
    throw new BadRequestException(
      'Tip amount must exceed fee when recipient pays fee',
    );
  }
  return net;
}

export function resolveTipSenderDebitAtomic(
  amountAtomic: bigint,
  feeAtomic: bigint,
  feeConfig: TipFeeConfig,
): bigint {
  return feeConfig.senderPaysFee ? amountAtomic + feeAtomic : amountAtomic;
}

export function assertTipAmountWithinPolicy(
  amountAtomic: bigint,
  currency: TipCurrency,
  feeConfig: TipFeeConfig,
): void {
  if (amountAtomic < feeConfig.minTipAtomic) {
    throw new BadRequestException(
      `Minimum tip is ${formatAtomicAmount(
        feeConfig.minTipAtomic,
        currency.decimals,
      )} ${currency.symbol}`,
    );
  }
  if (feeConfig.maxTipAtomic != null && amountAtomic > feeConfig.maxTipAtomic) {
    throw new BadRequestException(
      `Maximum tip is ${formatAtomicAmount(
        feeConfig.maxTipAtomic,
        currency.decimals,
      )} ${currency.symbol}`,
    );
  }
}
