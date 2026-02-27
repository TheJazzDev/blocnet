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
  type TipAccount,
  type TipCurrency,
  type TipFeeConfig,
  type TipTransaction,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import {
  createDeterministicIdempotencyKey,
  normalizeIdempotencyKey,
} from '../common/utils/idempotency.util';
import { NotificationsService } from '../notifications/notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { normalizePagination } from '../common/utils/pagination.util';
import { CreateTipDto } from './dto/create-tip.dto';
import { ListAdminTipTransactionsQuery } from './dto/list-admin-tip-transactions.query';
import { ListTipHistoryQuery } from './dto/list-tip-history.query';
import { UpdateTipCurrencyDto } from './dto/update-tip-currency.dto';
import {
  ceilDivide,
  formatAtomicAmount,
  parseAtomicAmount,
  parseAtomicAmountAllowZero,
} from './tip-amount.util';
import {
  BNP_CURRENCY_CODE,
  BNP_DECIMALS,
  FEE_VAULT_OWNER_REF,
} from './tip.constants';

const DEFAULT_PAGE_SIZE = 30;
const MAX_PAGE_SIZE = 100;

type CurrencyWithFeeConfig = TipCurrency & {
  feeConfig: TipFeeConfig | null;
};

type TipTxWithDetails = TipTransaction & {
  currency: TipCurrency;
  sender: {
    id: string;
    username: string | null;
    displayName: string | null;
    avatarUrl: string | null;
  };
  recipient: {
    id: string;
    username: string | null;
    displayName: string | null;
    avatarUrl: string | null;
  };
};

type TxClient = Prisma.TransactionClient | PrismaService;

@Injectable()
export class TipsService {
  private readonly logger = new Logger(TipsService.name);
  private bootstrapPromise: Promise<void> | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async getMyOverview(userId: string) {
    await this.ensureBootstrap();
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
          where: {
            senderUserId: userId,
          },
          _count: {
            _all: true,
          },
          _sum: {
            amountAtomic: true,
            feeAtomic: true,
            totalDebitAtomic: true,
          },
        }),
        this.prisma.tipTransaction.groupBy({
          by: ['currencyCode'],
          where: {
            recipientUserId: userId,
          },
          _count: {
            _all: true,
          },
          _sum: {
            amountAtomic: true,
          },
        }),
      ]);

    const activeAccount = await this.ensureUserAccount(
      userId,
      activeCurrency.code,
      this.prisma,
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
      currency: this.toCurrencyResponse(row.currency, row.currency.feeConfig),
      balanceAtomic: row.balanceAtomic.toString(),
      balance: formatAtomicAmount(row.balanceAtomic, row.currency.decimals),
    }));

    const sentSummaryByCurrency = sentAggregateRows
      .map((row) => {
        const account = accountByCurrency.get(row.currencyCode);
        if (!account) return null;
        return this.toSentSummaryResponse({
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
      this.toSentSummaryResponse({
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
        return this.toReceivedSummaryResponse({
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
      this.toReceivedSummaryResponse({
        currency: activeCurrency,
        feeConfig: activeCurrency.feeConfig,
        transactionCount: 0,
        amountAtomic: 0n,
      });

    return {
      activeCurrency: this.toCurrencyResponse(
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
    await this.ensureBootstrap();

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

    this.assertTipAmountWithinPolicy(amountAtomic, activeCurrency, feeConfig);

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

    const feeAtomic = this.calculateFeeAtomic(amountAtomic, feeConfig);
    const recipientCreditAtomic = this.resolveRecipientCreditAtomic(
      amountAtomic,
      feeAtomic,
      feeConfig,
    );
    const senderDebitAtomic = this.resolveSenderDebitAtomic(
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
        randomUUID(),
      );

    const created = await this.prisma.$transaction(
      async (tx) => {
        const existing = await tx.tipTransaction.findUnique({
          where: { idempotencyKey },
          include: this.tipTxInclude(),
        });
        if (existing) {
          return existing;
        }

        const senderAccount = await this.ensureUserAccount(
          senderUserId,
          activeCurrency.code,
          tx,
        );
        const recipientAccount = await this.ensureUserAccount(
          recipient.id,
          activeCurrency.code,
          tx,
        );
        const feeVaultAccount = await this.ensureFeeVaultAccount(
          activeCurrency.code,
          tx,
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
          data: {
            balanceAtomic: {
              decrement: senderDebitAtomic,
            },
          },
        });

        await tx.tipAccount.update({
          where: { id: recipientAccount.id },
          data: {
            balanceAtomic: {
              increment: recipientCreditAtomic,
            },
          },
        });

        if (feeAtomic > 0n) {
          await tx.tipAccount.update({
            where: { id: feeVaultAccount.id },
            data: {
              balanceAtomic: {
                increment: feeAtomic,
              },
            },
          });
        }

        return tx.tipTransaction.create({
          data: {
            type: 'tip',
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
          include: this.tipTxInclude(),
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

    return this.toTipTransactionResponse(created, senderUserId);
  }

  async listTipHistory(userId: string, query: ListTipHistoryQuery) {
    await this.ensureBootstrap();
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const direction = query.direction ?? 'all';

    const where: Prisma.TipTransactionWhereInput = {
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
        include: this.tipTxInclude(),
      }),
      this.prisma.tipTransaction.count({ where }),
    ]);

    return {
      data: rows.map((row) => this.toTipTransactionResponse(row, userId)),
      total,
      limit,
      offset,
    };
  }

  async listAdminTransactions(query: ListAdminTipTransactionsQuery) {
    await this.ensureBootstrap();
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const q = query.q?.trim();
    const direction = query.direction ?? 'all';
    const userId = query.userId?.trim();

    const and: Prisma.TipTransactionWhereInput[] = [];
    if (query.currencyCode) {
      and.push({
        currencyCode: query.currencyCode.trim().toUpperCase(),
      });
    }

    if (userId) {
      if (direction === 'sent') {
        and.push({ senderUserId: userId });
      } else if (direction === 'received') {
        and.push({ recipientUserId: userId });
      } else {
        and.push({
          OR: [{ senderUserId: userId }, { recipientUserId: userId }],
        });
      }
    }

    if (q) {
      const uuidRegex =
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      and.push({
        OR: [
          { note: { contains: q, mode: 'insensitive' } },
          { sender: { email: { contains: q, mode: 'insensitive' } } },
          { sender: { displayName: { contains: q, mode: 'insensitive' } } },
          { sender: { username: { contains: q, mode: 'insensitive' } } },
          { recipient: { email: { contains: q, mode: 'insensitive' } } },
          { recipient: { displayName: { contains: q, mode: 'insensitive' } } },
          { recipient: { username: { contains: q, mode: 'insensitive' } } },
          ...(uuidRegex.test(q)
            ? [{ id: q }, { senderUserId: q }, { recipientUserId: q }]
            : []),
        ],
      });
    }

    const where: Prisma.TipTransactionWhereInput = and.length
      ? { AND: and }
      : {};

    const [rows, total] = await Promise.all([
      this.prisma.tipTransaction.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: this.tipTxInclude(),
      }),
      this.prisma.tipTransaction.count({ where }),
    ]);

    return {
      data: rows.map((row) => this.toTipTransactionResponse(row)),
      total,
      limit,
      offset,
    };
  }

  async getAdminSettings() {
    await this.ensureBootstrap();

    const currencies = await this.prisma.tipCurrency.findMany({
      include: {
        feeConfig: true,
        accounts: {
          where: {
            accountType: TipAccountType.fee_vault,
            ownerRef: FEE_VAULT_OWNER_REF,
          },
          take: 1,
        },
      },
      orderBy: [{ isActiveTippingCurrency: 'desc' }, { code: 'asc' }],
    });

    return {
      activeCurrencyCode:
        currencies.find((row) => row.isActiveTippingCurrency)?.code ?? null,
      currencies: currencies.map((row) => ({
        ...this.toCurrencyResponse(row, row.feeConfig),
        feeVaultBalanceAtomic: (
          row.accounts[0]?.balanceAtomic ?? 0n
        ).toString(),
        feeVaultBalance: formatAtomicAmount(
          row.accounts[0]?.balanceAtomic ?? 0n,
          row.decimals,
        ),
      })),
    };
  }

  async updateCurrencySettings(
    actorId: string,
    currencyCode: string,
    dto: UpdateTipCurrencyDto,
  ) {
    await this.ensureBootstrap();
    const code = currencyCode.trim().toUpperCase();

    const currency = await this.prisma.tipCurrency.findUnique({
      where: { code },
      include: { feeConfig: true },
    });
    if (!currency) {
      throw new NotFoundException('Tip currency not found');
    }

    const decimals = currency.decimals;
    const maxTipAtomic = this.parseOptionalAtomic(
      dto.maxTip,
      decimals,
      'maxTip',
    );
    const maxFeeAtomic = this.parseOptionalAtomic(
      dto.maxFee,
      decimals,
      'maxFee',
    );

    const feeData: Prisma.TipFeeConfigUncheckedUpdateInput = {};
    if (dto.feeBps !== undefined) feeData.feeBps = dto.feeBps;
    if (dto.minTip !== undefined) {
      feeData.minTipAtomic = parseAtomicAmount(dto.minTip, decimals, 'minTip');
    }
    if (dto.maxTip !== undefined) feeData.maxTipAtomic = maxTipAtomic;
    if (dto.minFee !== undefined) {
      feeData.minFeeAtomic = parseAtomicAmountAllowZero(
        dto.minFee,
        decimals,
        'minFee',
      );
    }
    if (dto.maxFee !== undefined) feeData.maxFeeAtomic = maxFeeAtomic;
    if (dto.senderPaysFee !== undefined) {
      feeData.senderPaysFee = dto.senderPaysFee;
    }
    if (dto.policyActive !== undefined) {
      feeData.isActive = dto.policyActive;
    }

    if (
      feeData.minTipAtomic !== undefined &&
      feeData.maxTipAtomic !== undefined &&
      feeData.maxTipAtomic !== null &&
      BigInt(feeData.maxTipAtomic as bigint) <
        BigInt(feeData.minTipAtomic as bigint)
    ) {
      throw new BadRequestException(
        'maxTip must be greater than or equal to minTip',
      );
    }

    if (
      feeData.minFeeAtomic !== undefined &&
      feeData.maxFeeAtomic !== undefined &&
      feeData.maxFeeAtomic !== null &&
      BigInt(feeData.maxFeeAtomic as bigint) <
        BigInt(feeData.minFeeAtomic as bigint)
    ) {
      throw new BadRequestException(
        'maxFee must be greater than or equal to minFee',
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const currencyRow = await tx.tipCurrency.update({
        where: { code },
        data: {
          ...(dto.name !== undefined ? { name: dto.name.trim() } : {}),
          ...(dto.symbol !== undefined ? { symbol: dto.symbol.trim() } : {}),
          ...(dto.isEnabled !== undefined ? { isEnabled: dto.isEnabled } : {}),
        },
        include: { feeConfig: true },
      });

      const feeConfig = await tx.tipFeeConfig.upsert({
        where: { currencyCode: code },
        update: feeData,
        create: {
          currencyCode: code,
          feeBps: dto.feeBps ?? 0,
          minTipAtomic:
            dto.minTip !== undefined
              ? parseAtomicAmount(dto.minTip, decimals, 'minTip')
              : 1n,
          maxTipAtomic,
          minFeeAtomic:
            dto.minFee !== undefined
              ? parseAtomicAmountAllowZero(dto.minFee, decimals, 'minFee')
              : 0n,
          maxFeeAtomic,
          senderPaysFee: dto.senderPaysFee ?? true,
          isActive: dto.policyActive ?? true,
        },
      });

      await this.ensureFeeVaultAccount(code, tx);
      return { currencyRow, feeConfig };
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.TipCurrencySettingsUpdated,
      resourceType: 'tip_currency',
      resourceId: code,
      metadata: {
        currencyCode: code,
        feeBps: updated.feeConfig.feeBps,
        minTipAtomic: updated.feeConfig.minTipAtomic.toString(),
        maxTipAtomic: updated.feeConfig.maxTipAtomic?.toString() ?? null,
        minFeeAtomic: updated.feeConfig.minFeeAtomic.toString(),
        maxFeeAtomic: updated.feeConfig.maxFeeAtomic?.toString() ?? null,
        senderPaysFee: updated.feeConfig.senderPaysFee,
      },
    });

    return this.getAdminSettings();
  }

  async setActiveCurrency(actorId: string, currencyCode: string) {
    await this.ensureBootstrap();
    const targetCode = currencyCode.trim().toUpperCase();

    const target = await this.prisma.tipCurrency.findUnique({
      where: { code: targetCode },
      include: { feeConfig: true },
    });
    if (!target) {
      throw new NotFoundException('Tip currency not found');
    }
    if (!target.isEnabled) {
      throw new BadRequestException('Tip currency is disabled');
    }
    if (!target.feeConfig?.isActive) {
      throw new BadRequestException(
        'Tip fee policy for this currency must be active first',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.tipCurrency.updateMany({
        where: { isActiveTippingCurrency: true },
        data: { isActiveTippingCurrency: false },
      });
      await tx.tipCurrency.update({
        where: { code: targetCode },
        data: { isActiveTippingCurrency: true },
      });
      await this.ensureFeeVaultAccount(targetCode, tx);
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.TipActiveCurrencyUpdated,
      resourceType: 'tip_currency',
      resourceId: targetCode,
      metadata: {
        activeCurrencyCode: targetCode,
      },
    });

    return this.getAdminSettings();
  }

  private tipTxInclude() {
    return {
      currency: true,
      sender: {
        select: {
          id: true,
          username: true,
          displayName: true,
          avatarUrl: true,
        },
      },
      recipient: {
        select: {
          id: true,
          username: true,
          displayName: true,
          avatarUrl: true,
        },
      },
    } satisfies Prisma.TipTransactionInclude;
  }

  private toTipTransactionResponse(
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
      totalDebit: formatAtomicAmount(
        row.totalDebitAtomic,
        row.currency.decimals,
      ),
      sender: row.sender,
      recipient: row.recipient,
      note: row.note,
      contextType: row.contextType,
      contextId: row.contextId,
      metadata: row.metadata ?? null,
      createdAt: row.createdAt,
    };
  }

  private toCurrencyResponse(
    currency: TipCurrency,
    feeConfig: TipFeeConfig | null,
  ) {
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
            minTip: formatAtomicAmount(
              feeConfig.minTipAtomic,
              currency.decimals,
            ),
            maxTipAtomic: feeConfig.maxTipAtomic?.toString() ?? null,
            maxTip:
              feeConfig.maxTipAtomic == null
                ? null
                : formatAtomicAmount(feeConfig.maxTipAtomic, currency.decimals),
            minFeeAtomic: feeConfig.minFeeAtomic.toString(),
            minFee: formatAtomicAmount(
              feeConfig.minFeeAtomic,
              currency.decimals,
            ),
            maxFeeAtomic: feeConfig.maxFeeAtomic?.toString() ?? null,
            maxFee:
              feeConfig.maxFeeAtomic == null
                ? null
                : formatAtomicAmount(feeConfig.maxFeeAtomic, currency.decimals),
            senderPaysFee: feeConfig.senderPaysFee,
            isActive: feeConfig.isActive,
          }
        : null,
    };
  }

  private toSentSummaryResponse({
    currency,
    feeConfig,
    transactionCount,
    amountAtomic,
    feeAtomic,
    totalDebitAtomic,
  }: {
    currency: TipCurrency;
    feeConfig: TipFeeConfig | null;
    transactionCount: number;
    amountAtomic: bigint;
    feeAtomic: bigint;
    totalDebitAtomic: bigint;
  }) {
    return {
      currency: this.toCurrencyResponse(currency, feeConfig),
      transactionCount,
      amountAtomic: amountAtomic.toString(),
      amount: formatAtomicAmount(amountAtomic, currency.decimals),
      feeAtomic: feeAtomic.toString(),
      fee: formatAtomicAmount(feeAtomic, currency.decimals),
      totalDebitAtomic: totalDebitAtomic.toString(),
      totalDebit: formatAtomicAmount(totalDebitAtomic, currency.decimals),
    };
  }

  private toReceivedSummaryResponse({
    currency,
    feeConfig,
    transactionCount,
    amountAtomic,
  }: {
    currency: TipCurrency;
    feeConfig: TipFeeConfig | null;
    transactionCount: number;
    amountAtomic: bigint;
  }) {
    return {
      currency: this.toCurrencyResponse(currency, feeConfig),
      transactionCount,
      amountAtomic: amountAtomic.toString(),
      amount: formatAtomicAmount(amountAtomic, currency.decimals),
    };
  }

  private resolveRecipientCreditAtomic(
    amountAtomic: bigint,
    feeAtomic: bigint,
    feeConfig: TipFeeConfig,
  ) {
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

  private resolveSenderDebitAtomic(
    amountAtomic: bigint,
    feeAtomic: bigint,
    feeConfig: TipFeeConfig,
  ) {
    return feeConfig.senderPaysFee ? amountAtomic + feeAtomic : amountAtomic;
  }

  private calculateFeeAtomic(
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

  private assertTipAmountWithinPolicy(
    amountAtomic: bigint,
    currency: TipCurrency,
    feeConfig: TipFeeConfig,
  ) {
    if (amountAtomic < feeConfig.minTipAtomic) {
      throw new BadRequestException(
        `Minimum tip is ${formatAtomicAmount(
          feeConfig.minTipAtomic,
          currency.decimals,
        )} ${currency.symbol}`,
      );
    }
    if (
      feeConfig.maxTipAtomic != null &&
      amountAtomic > feeConfig.maxTipAtomic
    ) {
      throw new BadRequestException(
        `Maximum tip is ${formatAtomicAmount(
          feeConfig.maxTipAtomic,
          currency.decimals,
        )} ${currency.symbol}`,
      );
    }
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

    if (dto.toUserId) {
      const profile = await this.prisma.profile.findUnique({
        where: { id: dto.toUserId },
        select: {
          id: true,
          isDeactivated: true,
          roles: {
            select: { role: true },
          },
        },
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
      where: {
        username: {
          equals: username,
          mode: 'insensitive',
        },
      },
      select: {
        id: true,
        isDeactivated: true,
        roles: {
          select: { role: true },
        },
      },
    });

    if (!profile || profile.isDeactivated) {
      throw new NotFoundException('Recipient user not found');
    }
    if (profile.id === senderUserId) {
      throw new BadRequestException('You cannot tip yourself');
    }
    return profile;
  }

  private async ensureUserAccount(
    userId: string,
    currencyCode: string,
    tx: TxClient,
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
      update: {
        userId,
      },
      create: {
        accountType: TipAccountType.user,
        ownerRef: userId,
        userId,
        currencyCode,
        balanceAtomic: initialBalance,
      },
    });
  }

  private async ensureFeeVaultAccount(
    currencyCode: string,
    tx: TxClient,
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

  private async ensureBootstrap() {
    if (!this.bootstrapPromise) {
      this.bootstrapPromise = this.bootstrapDefaults().finally(() => {
        this.bootstrapPromise = null;
      });
    }
    await this.bootstrapPromise;
  }

  private async bootstrapDefaults() {
    await this.prisma.$transaction(async (tx) => {
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

      await this.ensureFeeVaultAccount(BNP_CURRENCY_CODE, tx);
      await this.ensureFeeVaultAccount('BNT', tx);

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
    });
  }

  private parseOptionalAtomic(
    value: string | null | undefined,
    decimals: number,
    field: string,
  ) {
    if (value === undefined) return undefined;
    if (value === null) return null;
    const normalized = value.trim();
    if (!normalized) return null;
    return parseAtomicAmountAllowZero(normalized, decimals, field);
  }
}
