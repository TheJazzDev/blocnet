/**
 * Admin surface for the tip ledger: currency/fee settings, the active
 * tipping currency, and the full ledger listing.
 *
 * The ledger listing deliberately shows every row type (tips and BNP
 * transfers alike) — it is an audit view and each row carries `type`.
 */
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, TipAccountType, TipTransactionType } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { normalizePagination } from '../common/utils/pagination.util';
import { PrismaService } from '../prisma/prisma.service';
import { ListAdminTipTransactionsQuery } from './dto/list-admin-tip-transactions.query';
import { UpdateTipCurrencyDto } from './dto/update-tip-currency.dto';
import {
  formatAtomicAmount,
  parseAtomicAmount,
  parseAtomicAmountAllowZero,
} from './tip-amount.util';
import { TipBootstrapService } from './tip-bootstrap';
import { ensureFeeVaultAccount } from './tip-ledger.util';
import {
  tipTxInclude,
  toTipCurrencyResponse,
  toTipTransactionResponse,
} from './tip-response.mappers';
import {
  FEE_VAULT_OWNER_REF,
  RETIRED_TIP_CURRENCY_CODES,
  isRetiredTipCurrencyCode,
} from './tip.constants';

const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

@Injectable()
export class TipsAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly bootstrap: TipBootstrapService,
  ) {}

  async listAdminTransactions(query: ListAdminTipTransactionsQuery) {
    await this.bootstrap.ensure();
    const { limit, offset } = normalizePagination(query.offset, query.limit);
    const q = query.q?.trim();
    const direction = query.direction ?? 'all';
    const userId = query.userId?.trim();

    // Minted BNP (mining claims, quest rewards) is not a member-to-member
    // movement and would drown the tips list (F-63).
    const and: Prisma.TipTransactionWhereInput[] = [
      { type: { not: TipTransactionType.reward } },
    ];
    if (query.currencyCode) {
      and.push({ currencyCode: query.currencyCode.trim().toUpperCase() });
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
      and.push({
        OR: [
          { note: { contains: q, mode: 'insensitive' } },
          { sender: { email: { contains: q, mode: 'insensitive' } } },
          { sender: { displayName: { contains: q, mode: 'insensitive' } } },
          { sender: { username: { contains: q, mode: 'insensitive' } } },
          { recipient: { email: { contains: q, mode: 'insensitive' } } },
          { recipient: { displayName: { contains: q, mode: 'insensitive' } } },
          { recipient: { username: { contains: q, mode: 'insensitive' } } },
          ...(UUID_PATTERN.test(q)
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
        include: tipTxInclude(),
      }),
      this.prisma.tipTransaction.count({ where }),
    ]);

    return {
      data: rows.map((row) => toTipTransactionResponse(row)),
      total,
      limit,
      offset,
    };
  }

  async getAdminSettings() {
    await this.bootstrap.ensure();

    const rows = await this.prisma.tipCurrency.findMany({
      where: { code: { notIn: [...RETIRED_TIP_CURRENCY_CODES] } },
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
    // Defensive second pass: a retired code must never reach the console even
    // if a stray row slips past the query filter.
    const currencies = rows.filter(
      (row) => !isRetiredTipCurrencyCode(row.code),
    );

    return {
      activeCurrencyCode:
        currencies.find((row) => row.isActiveTippingCurrency)?.code ?? null,
      currencies: currencies.map((row) => {
        const vaultBalance = row.accounts[0]?.balanceAtomic ?? 0n;
        return {
          ...toTipCurrencyResponse(row, row.feeConfig),
          feeVaultBalanceAtomic: vaultBalance.toString(),
          feeVaultBalance: formatAtomicAmount(vaultBalance, row.decimals),
        };
      }),
    };
  }

  async updateCurrencySettings(
    actorId: string,
    currencyCode: string,
    dto: UpdateTipCurrencyDto,
  ) {
    await this.bootstrap.ensure();
    const code = currencyCode.trim().toUpperCase();
    this.assertNotRetiredCurrency(code);
    if (dto.code !== undefined) {
      this.assertNotRetiredCurrency(dto.code);
    }

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

    this.assertOrderedBounds(
      feeData.minTipAtomic,
      feeData.maxTipAtomic,
      'maxTip must be greater than or equal to minTip',
    );
    this.assertOrderedBounds(
      feeData.minFeeAtomic,
      feeData.maxFeeAtomic,
      'maxFee must be greater than or equal to minFee',
    );

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

      await ensureFeeVaultAccount(tx, code);
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
    await this.bootstrap.ensure();
    const targetCode = currencyCode.trim().toUpperCase();
    this.assertNotRetiredCurrency(targetCode);

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
      await ensureFeeVaultAccount(tx, targetCode);
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.TipActiveCurrencyUpdated,
      resourceType: 'tip_currency',
      resourceId: targetCode,
      metadata: { activeCurrencyCode: targetCode },
    });

    return this.getAdminSettings();
  }

  private assertOrderedBounds(
    min: Prisma.TipFeeConfigUncheckedUpdateInput['minTipAtomic'],
    max: Prisma.TipFeeConfigUncheckedUpdateInput['maxTipAtomic'],
    message: string,
  ) {
    if (
      min !== undefined &&
      max !== undefined &&
      max !== null &&
      BigInt(max as bigint) < BigInt(min as bigint)
    ) {
      throw new BadRequestException(message);
    }
  }

  /**
   * Retired codes (F-07: MCR) can never be created, enabled or activated
   * through the admin surface, regardless of the row's current DB state.
   */
  private assertNotRetiredCurrency(code: string) {
    const normalized = code.trim().toUpperCase();
    if (isRetiredTipCurrencyCode(normalized)) {
      throw new BadRequestException(
        `Tip currency ${normalized} is retired and cannot be created, enabled or activated`,
      );
    }
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
