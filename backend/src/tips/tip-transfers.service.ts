/**
 * Member-to-member BNP transfers on the tip ledger.
 *
 * Same mechanics as a tip (serializable transaction, guarded debit, BigInt
 * atomic amounts, idempotency key, audit log) with three differences:
 * - any active member can receive, not only hunters;
 * - no fee: the tip fee policy (min/max tip, fee vault) exists to price
 *   tipping, and a transfer is a plain move of a member's own points;
 * - rows are `type: transfer`, so they never count as tips.
 *
 * Gated on the BNP `TipCurrency.isEnabled` flag, not on the on-chain wallet
 * switch: BNP is off-chain and must move while custody is off.
 */
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { NotificationType, Prisma, TipTransactionType } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { createDeterministicIdempotencyKey } from '../common/utils/idempotency.util';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePointsTransferDto } from './dto/create-points-transfer.dto';
import { formatAtomicAmount } from './tip-amount.util';
import { TipBootstrapService } from './tip-bootstrap';
import { ensureUserTipAccount } from './tip-ledger.util';
import {
  tipTxInclude,
  toTipTransactionResponse,
  type TipTxWithDetails,
} from './tip-response.mappers';
import { BNP_CURRENCY_CODE } from './tip.constants';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const POINTS_TRANSFER_CONTEXT = 'wallet_transfer';

@Injectable()
export class TipTransfersService {
  private readonly logger = new Logger(TipTransfersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly notificationsService: NotificationsService,
    private readonly bootstrap: TipBootstrapService,
  ) {}

  async sendTransfer(senderUserId: string, dto: CreatePointsTransferDto) {
    await this.bootstrap.ensure();

    const currency = await this.prisma.tipCurrency.findUnique({
      where: { code: BNP_CURRENCY_CODE },
    });
    if (!currency || !currency.isEnabled) {
      throw new ServiceUnavailableException(
        'BNP transfers are currently unavailable',
      );
    }

    const amountAtomic = BigInt(dto.amountAtomic);
    if (amountAtomic <= 0n) {
      throw new BadRequestException('Amount must be greater than 0');
    }

    const recipient = await this.resolveRecipient(dto.recipient);
    if (recipient.id === senderUserId) {
      throw new BadRequestException('You cannot send BNP to yourself');
    }
    await this.assertNotBlocked(senderUserId, recipient.id);

    const clientKey = dto.idempotencyKey.trim();
    // Namespaced per sender so one member's key can never collide with (or
    // replay) another member's row in the shared unique column.
    const idempotencyKey = createDeterministicIdempotencyKey(
      'bnp-transfer',
      senderUserId,
      clientKey,
    );
    const note = dto.note?.trim() || null;

    let replayed = false;
    let created: TipTxWithDetails;
    try {
      created = await this.prisma.$transaction(
        async (tx) => {
          const existing = await tx.tipTransaction.findUnique({
            where: { idempotencyKey },
            include: tipTxInclude(),
          });
          if (existing) {
            replayed = true;
            return existing;
          }

          const senderAccount = await ensureUserTipAccount(
            tx,
            senderUserId,
            currency.code,
          );
          const recipientAccount = await ensureUserTipAccount(
            tx,
            recipient.id,
            currency.code,
          );

          // Guarded debit: only succeeds while the balance covers the amount.
          const debited = await tx.tipAccount.updateMany({
            where: {
              id: senderAccount.id,
              balanceAtomic: { gte: amountAtomic },
            },
            data: { balanceAtomic: { decrement: amountAtomic } },
          });
          if (debited.count !== 1) {
            throw new BadRequestException('Insufficient BNP balance');
          }

          await tx.tipAccount.update({
            where: { id: recipientAccount.id },
            data: { balanceAtomic: { increment: amountAtomic } },
          });

          return tx.tipTransaction.create({
            data: {
              type: TipTransactionType.transfer,
              senderAccountId: senderAccount.id,
              recipientAccountId: recipientAccount.id,
              feeAccountId: null,
              senderUserId,
              recipientUserId: recipient.id,
              currencyCode: currency.code,
              amountAtomic,
              feeAtomic: 0n,
              totalDebitAtomic: amountAtomic,
              note,
              contextType: POINTS_TRANSFER_CONTEXT,
              contextId: null,
              idempotencyKey,
              metadata: { clientIdempotencyKey: clientKey },
            },
            include: tipTxInclude(),
          });
        },
        { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
      );
    } catch (error) {
      // A concurrent retry with the same key won the insert race.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existing = await this.prisma.tipTransaction.findUnique({
          where: { idempotencyKey },
          include: tipTxInclude(),
        });
        if (!existing) throw error;
        replayed = true;
        created = existing;
      } else {
        throw error;
      }
    }

    if (replayed) {
      this.assertSameTransfer(created, recipient.id, amountAtomic);
      return toTipTransactionResponse(created, senderUserId);
    }

    await this.auditLogService.create({
      actorId: senderUserId,
      action: FinancialAuditActions.TipTransferSent,
      resourceType: 'tip_transaction',
      resourceId: created.id,
      metadata: {
        senderUserId,
        recipientUserId: recipient.id,
        currencyCode: created.currencyCode,
        amountAtomic: created.amountAtomic.toString(),
        idempotencyKey,
      },
    });

    await this.notifyRecipient(created);

    return toTipTransactionResponse(created, senderUserId);
  }

  private assertSameTransfer(
    row: TipTxWithDetails,
    recipientId: string,
    amountAtomic: bigint,
  ) {
    if (
      row.type !== TipTransactionType.transfer ||
      row.recipientUserId !== recipientId ||
      row.amountAtomic !== amountAtomic
    ) {
      throw new ConflictException(
        'This idempotency key was already used for a different transfer',
      );
    }
  }

  private async resolveRecipient(raw: string) {
    const value = raw.trim();
    const select = { id: true, isDeactivated: true } as const;
    const profile = UUID_PATTERN.test(value)
      ? await this.prisma.profile.findUnique({ where: { id: value }, select })
      : await this.prisma.profile.findFirst({
          where: {
            username: {
              equals: value.replace(/^@/, ''),
              mode: 'insensitive',
            },
          },
          select,
        });

    if (!profile || profile.isDeactivated) {
      throw new NotFoundException('Recipient not found');
    }
    return profile;
  }

  private async assertNotBlocked(senderUserId: string, recipientId: string) {
    const block = await this.prisma.userBlock.findUnique({
      where: {
        blockerId_blockedId: {
          blockerId: recipientId,
          blockedId: senderUserId,
        },
      },
      select: { id: true },
    });
    if (block) {
      throw new ForbiddenException('You cannot send BNP to this member');
    }
  }

  private async notifyRecipient(row: TipTxWithDetails) {
    try {
      const amount = formatAtomicAmount(
        row.amountAtomic,
        row.currency.decimals,
      );
      const senderLabel =
        row.sender.displayName ??
        (row.sender.username ? `@${row.sender.username}` : 'A member');

      await this.notificationsService.notifyMany(
        [
          {
            userId: row.recipientUserId,
            type: NotificationType.wallet_transfer_received,
            actorUserId: row.senderUserId,
            title: 'BNP received',
            body: `${senderLabel} sent you ${amount} BNP.`,
            payload: {
              type: 'bnp_transfer_received',
              transferId: row.id,
              asset: row.currencyCode,
              amount,
              amountAtomic: row.amountAtomic.toString(),
              fromUserId: row.senderUserId,
            } as Prisma.InputJsonValue,
            deeplink: '/wallet',
            dedupeKey: `bnp.transfer.received:${row.id}`,
          },
        ],
        { push: true },
      );
    } catch (error) {
      this.logger.warn(
        `Failed to emit BNP transfer notification for tx ${row.id}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }
}
