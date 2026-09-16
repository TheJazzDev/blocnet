/**
 * Response shapes for the tip ledger. Pure functions; atomic BigInt amounts
 * are always serialised as strings alongside a formatted decimal.
 */
import {
  Prisma,
  type TipCurrency,
  type TipFeeConfig,
  type TipTransaction,
} from '@prisma/client';
import {
  currentLevelSelect,
  toCurrentLevelDto,
  type CurrentLevelRecord,
} from '../levels/level-summary';
import { formatAtomicAmount } from './tip-amount.util';

export type TipParticipantRecord = {
  id: string;
  username: string | null;
  displayName: string | null;
  avatarUrl: string | null;
  currentLevel: CurrentLevelRecord | null;
};

export type TipTxWithDetails = TipTransaction & {
  currency: TipCurrency;
  sender: TipParticipantRecord;
  recipient: TipParticipantRecord;
};

const participantSelect = {
  id: true,
  username: true,
  displayName: true,
  avatarUrl: true,
  currentLevel: {
    select: currentLevelSelect,
  },
} satisfies Prisma.ProfileSelect;

export function tipTxInclude() {
  return {
    currency: true,
    sender: { select: participantSelect },
    recipient: { select: participantSelect },
  } satisfies Prisma.TipTransactionInclude;
}

export function toTipParticipantResponse(participant: TipParticipantRecord) {
  return {
    id: participant.id,
    username: participant.username,
    displayName: participant.displayName,
    avatarUrl: participant.avatarUrl,
    currentLevel: toCurrentLevelDto(participant.currentLevel),
  };
}

export function toTipTransactionResponse(
  row: TipTxWithDetails,
  viewerUserId?: string,
) {
  const direction =
    viewerUserId && row.senderUserId === viewerUserId
      ? 'sent'
      : viewerUserId && row.recipientUserId === viewerUserId
        ? 'received'
        : 'neutral';

  return {
    id: row.id,
    type: row.type,
    direction,
    currency: {
      code: row.currency.code,
      name: row.currency.name,
      symbol: row.currency.symbol,
      decimals: row.currency.decimals,
    },
    amountAtomic: row.amountAtomic.toString(),
    amount: formatAtomicAmount(row.amountAtomic, row.currency.decimals),
    feeAtomic: row.feeAtomic.toString(),
    fee: formatAtomicAmount(row.feeAtomic, row.currency.decimals),
    totalDebitAtomic: row.totalDebitAtomic.toString(),
    totalDebit: formatAtomicAmount(row.totalDebitAtomic, row.currency.decimals),
    sender: toTipParticipantResponse(row.sender),
    recipient: toTipParticipantResponse(row.recipient),
    note: row.note,
    contextType: row.contextType,
    contextId: row.contextId,
    metadata: row.metadata ?? null,
    createdAt: row.createdAt,
  };
}

export function toTipCurrencyResponse(
  currency: TipCurrency,
  feeConfig: TipFeeConfig | null,
) {
  const format = (value: bigint) =>
    formatAtomicAmount(value, currency.decimals);
  return {
    code: currency.code,
    name: currency.name,
    symbol: currency.symbol,
    decimals: currency.decimals,
    kind: currency.kind,
    isEnabled: currency.isEnabled,
    isActiveTippingCurrency: currency.isActiveTippingCurrency,
    feePolicy: feeConfig
      ? {
          feeBps: feeConfig.feeBps,
          minTipAtomic: feeConfig.minTipAtomic.toString(),
          minTip: format(feeConfig.minTipAtomic),
          maxTipAtomic: feeConfig.maxTipAtomic?.toString() ?? null,
          maxTip:
            feeConfig.maxTipAtomic == null
              ? null
              : format(feeConfig.maxTipAtomic),
          minFeeAtomic: feeConfig.minFeeAtomic.toString(),
          minFee: format(feeConfig.minFeeAtomic),
          maxFeeAtomic: feeConfig.maxFeeAtomic?.toString() ?? null,
          maxFee:
            feeConfig.maxFeeAtomic == null
              ? null
              : format(feeConfig.maxFeeAtomic),
          senderPaysFee: feeConfig.senderPaysFee,
          isActive: feeConfig.isActive,
        }
      : null,
  };
}

export function toTipSentSummaryResponse(input: {
  currency: TipCurrency;
  feeConfig: TipFeeConfig | null;
  transactionCount: number;
  amountAtomic: bigint;
  feeAtomic: bigint;
  totalDebitAtomic: bigint;
}) {
  const { currency } = input;
  return {
    currency: toTipCurrencyResponse(currency, input.feeConfig),
    transactionCount: input.transactionCount,
    amountAtomic: input.amountAtomic.toString(),
    amount: formatAtomicAmount(input.amountAtomic, currency.decimals),
    feeAtomic: input.feeAtomic.toString(),
    fee: formatAtomicAmount(input.feeAtomic, currency.decimals),
    totalDebitAtomic: input.totalDebitAtomic.toString(),
    totalDebit: formatAtomicAmount(input.totalDebitAtomic, currency.decimals),
  };
}

export function toTipReceivedSummaryResponse(input: {
  currency: TipCurrency;
  feeConfig: TipFeeConfig | null;
  transactionCount: number;
  amountAtomic: bigint;
}) {
  return {
    currency: toTipCurrencyResponse(input.currency, input.feeConfig),
    transactionCount: input.transactionCount,
    amountAtomic: input.amountAtomic.toString(),
    amount: formatAtomicAmount(input.amountAtomic, input.currency.decimals),
  };
}
