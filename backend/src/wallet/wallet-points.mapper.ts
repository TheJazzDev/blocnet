/**
 * Maps one BNP ledger row (`TipTransaction`) to the `GET /wallet/transactions`
 * row shape, from the point of view of `userId`.
 *
 * Rows with a counterparty (transfers, tips) take their direction from sender
 * vs recipient. Minted BNP (`reward`) and its reversal (a quest-revoke
 * `adjustment`) are self rows: sender == recipient == the member. Those are
 * classified by type/contextType FIRST, so they never fall into the
 * sender-means-sent branch.
 */
import { TipTransactionType, type TipTransaction } from '@prisma/client';
import { BNP_REWARD_CONTEXT } from '../mining/bnp-tip-account';
import { formatAtomicAmount } from '../tips/tip-amount.util';
import { BNP_CURRENCY_CODE, BNP_DECIMALS } from '../tips/tip.constants';

export const POINTS_ASSET = BNP_CURRENCY_CODE;

/** Wallet transaction `reason` for each ledger row type. */
const POINTS_REASON: Record<TipTransactionType, string> = {
  [TipTransactionType.transfer]: 'bnp_transfer',
  [TipTransactionType.tip]: 'bnp_tip',
  [TipTransactionType.conversion]: 'bnp_conversion',
  [TipTransactionType.adjustment]: 'bnp_adjustment',
  [TipTransactionType.reward]: 'bnp_reward',
};

const POINTS_LABEL: Record<TipTransactionType, string> = {
  [TipTransactionType.transfer]: 'BNP transfer',
  [TipTransactionType.tip]: 'Tip',
  [TipTransactionType.conversion]: 'BNP conversion',
  [TipTransactionType.adjustment]: 'BNP adjustment',
  [TipTransactionType.reward]: 'BNP reward',
};

const REWARD_LABEL_BY_CONTEXT: Record<string, string> = {
  [BNP_REWARD_CONTEXT.miningClaim]: 'Mining reward',
  [BNP_REWARD_CONTEXT.questReward]: 'Quest reward',
};

const QUEST_REWARD_REVERSED_LABEL = 'Quest reward reversed';

export type PointsParty = {
  id: string;
  username: string | null;
  displayName: string | null;
};

export type PointsTxRow = TipTransaction & {
  sender: PointsParty;
  recipient: PointsParty;
};

type Direction = 'incoming' | 'outgoing';

type PointsRowView = {
  direction: Direction;
  label: string;
  amountAtomic: bigint;
  feeAtomic: bigint;
  debit: { userId: string | null; accountType: string };
  credit: { userId: string | null; accountType: string };
  counterparty: PointsParty | null;
};

const SYSTEM_SIDE = { userId: null, accountType: 'system' } as const;

function isQuestRewardReversal(row: PointsTxRow): boolean {
  return (
    row.type === TipTransactionType.adjustment &&
    row.contextType === BNP_REWARD_CONTEXT.questRewardRevoked
  );
}

/** Minted BNP: always received, the credited amount, no fee, no counterparty. */
function viewReward(userId: string, row: PointsTxRow): PointsRowView {
  return {
    direction: 'incoming',
    label:
      (row.contextType && REWARD_LABEL_BY_CONTEXT[row.contextType]) ??
      POINTS_LABEL[row.type],
    amountAtomic: row.amountAtomic,
    feeAtomic: 0n,
    debit: SYSTEM_SIDE,
    credit: { userId, accountType: 'user' },
    counterparty: null,
  };
}

/** A revoked quest reward: always a debit of the amount actually taken. */
function viewRewardReversal(userId: string, row: PointsTxRow): PointsRowView {
  return {
    direction: 'outgoing',
    label: QUEST_REWARD_REVERSED_LABEL,
    amountAtomic: row.amountAtomic,
    feeAtomic: 0n,
    debit: { userId, accountType: 'user' },
    credit: SYSTEM_SIDE,
    counterparty: null,
  };
}

/** Transfers, tips and other two-party rows. */
function viewTwoParty(userId: string, row: PointsTxRow): PointsRowView {
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

  return {
    direction: isOutgoing ? 'outgoing' : 'incoming',
    label: POINTS_LABEL[row.type],
    amountAtomic:
      !isOutgoing && recipientPaidFee
        ? row.amountAtomic - row.feeAtomic
        : row.amountAtomic,
    feeAtomic: isOutgoing !== recipientPaidFee ? row.feeAtomic : 0n,
    debit: { userId: row.senderUserId, accountType: 'user' },
    credit: { userId: row.recipientUserId, accountType: 'user' },
    counterparty: other,
  };
}

function viewRow(userId: string, row: PointsTxRow): PointsRowView {
  if (row.type === TipTransactionType.reward) {
    return viewReward(userId, row);
  }
  if (isQuestRewardReversal(row)) {
    return viewRewardReversal(userId, row);
  }
  return viewTwoParty(userId, row);
}

export function toPointsTransactionResponse(userId: string, row: PointsTxRow) {
  const view = viewRow(userId, row);

  return {
    id: row.id,
    asset: POINTS_ASSET,
    direction: view.direction,
    reason: POINTS_REASON[row.type],
    amount: formatAtomicAmount(view.amountAtomic, BNP_DECIMALS),
    feeAmount: formatAtomicAmount(view.feeAtomic, BNP_DECIMALS),
    debit: view.debit,
    credit: view.credit,
    referenceId: row.id,
    metadata: {
      source: 'bnp_ledger',
      ledgerType: row.type,
      label: view.label,
      note: row.note,
      contextType: row.contextType,
      contextId: row.contextId,
    },
    counterparty: view.counterparty
      ? {
          userId: view.counterparty.id,
          username: view.counterparty.username,
          displayName: view.counterparty.displayName,
          walletAddress: null,
        }
      : null,
    createdAt: row.createdAt,
  };
}
