import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  NotificationType,
  Prisma,
  RoleName,
  TipAccountType,
  TipTransactionType,
  type TipCurrency,
  type TipFeeConfig,
} from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import {
  createDeterministicIdempotencyKey,
  idempotencyTimeBucket,
  normalizeIdempotencyKey,
} from '../common/utils/idempotency.util';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePagination } from '../common/utils/pagination.util';
import { CreateTipDto } from './dto/create-tip.dto';
import { ListTipHistoryQuery } from './dto/list-tip-history.query';
import { formatAtomicAmount, parseAtomicAmount } from './tip-amount.util';
import { TipBootstrapService } from './tip-bootstrap';
import {
  assertTipAmountWithinPolicy,
  calculateTipFeeAtomic,
  resolveTipRecipientCreditAtomic,
  resolveTipSenderDebitAtomic,
} from './tip-fee.util';
import { ensureFeeVaultAccount, ensureUserTipAccount } from './tip-ledger.util';
import {
  tipTxInclude,
  toTipCurrencyResponse,
  toTipReceivedSummaryResponse,
  toTipSentSummaryResponse,
  toTipTransactionResponse,
} from './tip-response.mappers';

type CurrencyWithFeeConfig = TipCurrency & {
  feeConfig: TipFeeConfig | null;
};

/**
 * Only real tips count as tips. The same ledger also carries member-to-member
 * BNP transfers (`type: transfer`), which must never show up in tip history,
 * tip totals or anything derived from them.
 */
const TIPS_ONLY = { type: TipTransactionType.tip } as const;

@Injectable()
export class TipsService {
  private readonly logger = new Logger(TipsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly notificationsService: NotificationsService,
    private readonly bootstrap: TipBootstrapService,
  ) {}

  async getMyOverview(userId: string) {
    await this.bootstrap.ensure();
    const [activeCurrency, accounts, sentAggregateRows, receivedAggregateRows] =
      await Promise.all([
        this.requireActiveCurrency(),
        this.prisma.tipAccount.findMany({
          where: {
            userId,
            accountType: TipAccountType.user,
          },
          include: {
            currency: {
              include: {
                feeConfig: true,
              },
            },
          },
          orderBy: {
            currencyCode: 'asc',
          },
        }),
        this.prisma.tipTransaction.groupBy({
          by: ['currencyCode'],
          where: { senderUserId: userId, ...TIPS_ONLY },
          _count: { _all: true },
          _sum: {
            amountAtomic: true,
            feeAtomic: true,
            totalDebitAtomic: true,
          },
        }),
        this.prisma.tipTransaction.groupBy({
          by: ['currencyCode'],
          where: { recipientUserId: userId, ...TIPS_ONLY },
          _count: { _all: true },
          _sum: { amountAtomic: true },
        }),
      ]);

    const activeAccount = await ensureUserTipAccount(
      this.prisma,
      userId,
      activeCurrency.code,
    );

    const accountByCurrency = new Map(
      accounts.map((row) => [row.currencyCode, row]),
    );
    if (!accountByCurrency.has(activeCurrency.code)) {
      const refreshed = await this.prisma.tipAccount.findUnique({
        where: { id: activeAccount.id },
        include: { currency: { include: { feeConfig: true } } },
      });
      if (refreshed) {
        accountByCurrency.set(activeCurrency.code, refreshed);
      }
    }

    const balances = [...accountByCurrency.values()].map((row) => ({
      currency: toTipCurrencyResponse(row.currency, row.currency.feeConfig),
      balanceAtomic: row.balanceAtomic.toString(),
      balance: formatAtomicAmount(row.balanceAtomic, row.currency.decimals),
    }));

    const sentSummaryByCurrency = sentAggregateRows
      .map((row) => {
        const account = accountByCurrency.get(row.currencyCode);
        if (!account) return null;
        return toTipSentSummaryResponse({
          currency: account.currency,
          feeConfig: account.currency.feeConfig,
          transactionCount: row._count._all,
          amountAtomic: row._sum.amountAtomic ?? 0n,
          feeAtomic: row._sum.feeAtomic ?? 0n,
          totalDebitAtomic: row._sum.totalDebitAtomic ?? 0n,
        });
      })
      .filter((row): row is NonNullable<typeof row> => row !== null);

    const sentSummary =
      sentSummaryByCurrency.find(
        (row) => row.currency.code === activeCurrency.code,
      ) ??
      toTipSentSummaryResponse({
        currency: activeCurrency,
        feeConfig: activeCurrency.feeConfig,
        transactionCount: 0,
        amountAtomic: 0n,
        feeAtomic: 0n,
        totalDebitAtomic: 0n,
      });

    const receivedSummaryByCurrency = receivedAggregateRows
      .map((row) => {
        const account = accountByCurrency.get(row.currencyCode);
        if (!account) return null;
        return toTipReceivedSummaryResponse({
          currency: account.currency,
          feeConfig: account.currency.feeConfig,
          transactionCount: row._count._all,
          amountAtomic: row._sum.amountAtomic ?? 0n,
        });
      })
      .filter((row): row is NonNullable<typeof row> => row !== null);

    const receivedSummary =
      receivedSummaryByCurrency.find(
        (row) => row.currency.code === activeCurrency.code,
      ) ??
      toTipReceivedSummaryResponse({
        currency: activeCurrency,
        feeConfig: activeCurrency.feeConfig,
        transactionCount: 0,
        amountAtomic: 0n,
      });

    return {
      activeCurrency: toTipCurrencyResponse(
        activeCurrency,
        activeCurrency.feeConfig,
      ),
      balances,
      sentSummary,
      sentSummaryByCurrency,
      receivedSummary,
      receivedSummaryByCurrency,
    };
  }

  async sendTip(senderUserId: string, dto: CreateTipDto) {
    await this.bootstrap.ensure();

    const activeCurrency = await this.requireActiveCurrency();
    const requestedCurrencyCode = dto.currencyCode?.trim().toUpperCase();
    if (
      requestedCurrencyCode &&
      requestedCurrencyCode !== activeCurrency.code
    ) {
      throw new BadRequestException(
        `Tips currently support ${activeCurrency.code} only`,
      );
    }

    const feeConfig = this.requireActiveFeeConfig(activeCurrency);
    const amountAtomic = parseAtomicAmount(
      dto.amount,
      activeCurrency.decimals,
      'amount',
    );

    assertTipAmountWithinPolicy(amountAtomic, activeCurrency, feeConfig);

    const recipient = await this.resolveRecipient(dto, senderUserId);
    if (recipient.id === senderUserId) {
      throw new BadRequestException('You cannot tip yourself');
    }

    const isHunter = recipient.roles.some(
      (row) => row.role === RoleName.hunter,
    );
    if (!isHunter) {
      throw new BadRequestException('Only hunters can receive tips');
    }

    const feeAtomic = calculateTipFeeAtomic(amountAtomic, feeConfig);
    const recipientCreditAtomic = resolveTipRecipientCreditAtomic(
      amountAtomic,
      feeAtomic,
      feeConfig,
    );
    const senderDebitAtomic = resolveTipSenderDebitAtomic(
      amountAtomic,
      feeAtomic,
      feeConfig,
    );

    const idempotencyKey =
      normalizeIdempotencyKey(dto.idempotencyKey) ??
      createDeterministicIdempotencyKey(
        'tip-send',
        senderUserId,
        recipient.id,
        activeCurrency.code,
        amountAtomic.toString(),
        idempotencyTimeBucket(),
      );

    const created = await this.prisma.$transaction(
      async (tx) => {
        const existing = await tx.tipTransaction.findUnique({
          where: { idempotencyKey },
          include: tipTxInclude(),
        });
        if (existing) {
          return existing;
        }

        const senderAccount = await ensureUserTipAccount(
          tx,
          senderUserId,
          activeCurrency.code,
        );
        const recipientAccount = await ensureUserTipAccount(
          tx,
          recipient.id,
          activeCurrency.code,
        );
        const feeVaultAccount = await ensureFeeVaultAccount(
          tx,
          activeCurrency.code,
        );

        const freshSender = await tx.tipAccount.findUnique({
          where: { id: senderAccount.id },
          select: { balanceAtomic: true },
        });
        if (!freshSender) {
          throw new NotFoundException('Sender tip account not found');
        }
        if (freshSender.balanceAtomic < senderDebitAtomic) {
          throw new BadRequestException('Insufficient tip balance');
        }

        await tx.tipAccount.update({
          where: { id: senderAccount.id },
          data: { balanceAtomic: { decrement: senderDebitAtomic } },
        });

        await tx.tipAccount.update({
          where: { id: recipientAccount.id },
          data: { balanceAtomic: { increment: recipientCreditAtomic } },
        });

        if (feeAtomic > 0n) {
          await tx.tipAccount.update({
            where: { id: feeVaultAccount.id },
            data: { balanceAtomic: { increment: feeAtomic } },
          });
        }

        return tx.tipTransaction.create({
          data: {
            type: TipTransactionType.tip,
            senderAccountId: senderAccount.id,
            recipientAccountId: recipientAccount.id,
            feeAccountId: feeAtomic > 0n ? feeVaultAccount.id : null,
            senderUserId,
            recipientUserId: recipient.id,
            currencyCode: activeCurrency.code,
            amountAtomic,
            feeAtomic,
            totalDebitAtomic: senderDebitAtomic,
            note: dto.note?.trim() || null,
            contextType: dto.contextType?.trim() || null,
            contextId: dto.contextId?.trim() || null,
            idempotencyKey,
            metadata: {
              senderPaysFee: feeConfig.senderPaysFee,
              feeBps: feeConfig.feeBps,
            },
          },
          include: tipTxInclude(),
        });
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    await this.auditLogService.create({
      actorId: senderUserId,
      action: FinancialAuditActions.TipSent,
      resourceType: 'tip_transaction',
      resourceId: created.id,
      metadata: {
        senderUserId,
        recipientUserId: recipient.id,
        currencyCode: created.currencyCode,
        amountAtomic: created.amountAtomic.toString(),
        feeAtomic: created.feeAtomic.toString(),
        totalDebitAtomic: created.totalDebitAtomic.toString(),
        idempotencyKey,
      },
    });

    try {
      const normalizedSymbol = created.currency.symbol.trim();
      const symbol =
        normalizedSymbol.length > 0 ? normalizedSymbol : created.currency.code;
      const senderLabel =
        created.sender.displayName ?? created.sender.username ?? 'Someone';
      const tipAmount = formatAtomicAmount(
        created.amountAtomic,
        created.currency.decimals,
      );

      await this.notificationsService.notifyMany(
        [
          {
            userId: recipient.id,
            type: NotificationType.system,
            actorUserId: senderUserId,
            title: 'You received a tip',
            body: `${senderLabel} tipped you ${tipAmount} ${symbol}.`,
            payload: {
              type: 'tip_received',
              tipTransactionId: created.id,
              senderUserId,
              recipientUserId: recipient.id,
              currencyCode: created.currencyCode,
              amountAtomic: created.amountAtomic.toString(),
              amount: tipAmount,
              symbol,
            } as Prisma.InputJsonValue,
            deeplink: '/hunter-hub',
            dedupeKey: `tip.received:${created.id}`,
          },
        ],
        { push: true },
      );
    } catch (error) {
      this.logger.warn(
        `Failed to emit tip notification for tx ${created.id}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }

    return toTipTransactionResponse(created, senderUserId);
  }

  async listTipHistory(userId: string, query: ListTipHistoryQuery) {
    await this.bootstrap.ensure();
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const direction = query.direction ?? 'all';

    const where: Prisma.TipTransactionWhereInput = {
      ...TIPS_ONLY,
      ...(query.currencyCode
        ? { currencyCode: query.currencyCode.trim().toUpperCase() }
        : {}),
      ...(direction === 'sent'
        ? { senderUserId: userId }
        : direction === 'received'
          ? { recipientUserId: userId }
          : {
              OR: [{ senderUserId: userId }, { recipientUserId: userId }],
            }),
    };

    const [rows, total] = await Promise.all([
      this.prisma.tipTransaction.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: tipTxInclude(),
      }),
      this.prisma.tipTransaction.count({ where }),
    ]);

    return {
      data: rows.map((row) => toTipTransactionResponse(row, userId)),
      total,
      limit,
      offset,
    };
  }

  private requireActiveFeeConfig(currency: CurrencyWithFeeConfig) {
    if (!currency.feeConfig || !currency.feeConfig.isActive) {
      throw new ServiceUnavailableException(
        `Tip fee policy for ${currency.code} is not active`,
      );
    }
    return currency.feeConfig;
  }

  private async requireActiveCurrency(): Promise<CurrencyWithFeeConfig> {
    const currency = await this.prisma.tipCurrency.findFirst({
      where: {
        isActiveTippingCurrency: true,
        isEnabled: true,
      },
      include: {
        feeConfig: true,
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    if (!currency) {
      throw new ServiceUnavailableException(
        'No active tipping currency is configured',
      );
    }
    return currency;
  }

  private async resolveRecipient(dto: CreateTipDto, senderUserId: string) {
    if (!dto.toUserId && !dto.toUsername) {
      throw new BadRequestException(
        'Either toUserId or toUsername is required',
      );
    }

    const select = {
      id: true,
      isDeactivated: true,
      roles: { select: { role: true } },
    } satisfies Prisma.ProfileSelect;

    if (dto.toUserId) {
      const profile = await this.prisma.profile.findUnique({
        where: { id: dto.toUserId },
        select,
      });
      if (!profile || profile.isDeactivated) {
        throw new NotFoundException('Recipient user not found');
      }
      return profile;
    }

    const username = dto.toUsername?.trim().replace(/^@/, '').toLowerCase();
    if (!username) {
      throw new BadRequestException('Recipient username is invalid');
    }

    const profile = await this.prisma.profile.findFirst({
      where: { username: { equals: username, mode: 'insensitive' } },
      select,
    });

    if (!profile || profile.isDeactivated) {
      throw new NotFoundException('Recipient user not found');
    }
    if (profile.id === senderUserId) {
      throw new BadRequestException('You cannot tip yourself');
    }
    return profile;
  }
}
