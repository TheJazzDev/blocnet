import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ChainEnvironment,
  KycStatus,
  LedgerReason,
  Prisma,
  WalletAsset,
  WithdrawalStatus,
} from '@prisma/client';
import { createPublicClient, http } from 'viem';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { normalizeIdempotencyKey } from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import { TurnkeyCustodyAdapter } from './custody/turnkey-custody.adapter';
import { ListWalletAdminWithdrawalsQuery } from './dto/list-wallet-admin-withdrawals.query';
import { ListWalletKycQuery } from './dto/list-wallet-kyc.query';
import { ListWalletUsersQuery } from './dto/list-wallet-users.query';
import {
  ReviewWithdrawalDto,
  WithdrawalReviewDecision,
} from './dto/review-withdrawal.dto';
import { ReviewKycDto } from './dto/review-kyc.dto';
import { UpdateRiskLimitDto } from './dto/update-risk-limit.dto';
import { UpdateWalletAssetPriceDto } from './dto/update-wallet-asset-price.dto';
import { UpdateWalletFeeDto } from './dto/update-wallet-fee.dto';
import { DECIMAL_ZERO, toDecimalString } from './types/decimal';
import { normalizeWalletAsset } from './wallet-asset.util';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';

const DEFAULT_PAGE_SIZE = 30;
const MAX_PAGE_SIZE = 100;

@Injectable()
export class WalletAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly walletConfigService: WalletConfigService,
    private readonly turnkeyCustodyAdapter: TurnkeyCustodyAdapter,
    private readonly walletAssetPricingService: WalletAssetPricingService,
  ) {}

  async getWalletHealth() {
    const [
      turnkey,
      networks,
      walletCounts,
      depositCounts,
      sweepCounts,
      withdrawalCounts,
    ] = await Promise.all([
      this.turnkeyCustodyAdapter.getHealth(),
      Promise.all([
        this.checkNetworkHealth(this.walletConfigService.walletChainEnvironment),
      ]),
      this.prisma.userWallet.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
      this.prisma.onchainDeposit.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
      this.prisma.sweepJob.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
      this.prisma.withdrawalRequest.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
    ]);

    const walletsByStatus = {
      provisioning: 0,
      ready: 0,
      error: 0,
      disabled: 0,
    };
    for (const row of walletCounts) {
      walletsByStatus[row.status] = row._count._all;
    }

    const depositsByStatus = {
      detected: 0,
      credited: 0,
      swept: 0,
      ignored: 0,
      failed: 0,
    };
    for (const row of depositCounts) {
      depositsByStatus[row.status] = row._count._all;
    }

    const sweepJobsByStatus = {
      queued: 0,
      processing: 0,
      completed: 0,
      failed: 0,
    };
    for (const row of sweepCounts) {
      sweepJobsByStatus[row.status] = row._count._all;
    }

    const withdrawalsByStatus = {
      requested: 0,
      pending_review: 0,
      approved: 0,
      rejected: 0,
      broadcasting: 0,
      confirmed: 0,
      failed: 0,
      reverted: 0,
    };
    for (const row of withdrawalCounts) {
      withdrawalsByStatus[row.status] = row._count._all;
    }

    return {
      timestamp: new Date().toISOString(),
      flags: {
        walletEnabled: this.walletConfigService.walletEnabled,
        depositsEnabled: this.walletConfigService.depositsEnabled,
        withdrawalsEnabled: this.walletConfigService.withdrawalsEnabled,
        turnkeyMode: this.walletConfigService.turnkeyMode,
        turnkeyExecutionMode: this.walletConfigService.turnkeyExecutionMode,
      },
      turnkey,
      networks,
      counts: {
        walletsByStatus,
        depositsByStatus,
        sweepJobsByStatus,
        withdrawalsByStatus,
      },
    };
  }

  async listWalletUsers(query: ListWalletUsersQuery) {
    const { limit, offset } = this.normalizePagination(
      query.limit,
      query.offset,
    );
    const q = query.q?.trim();

    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q) : false;

    const where = {
      ...(q
        ? {
            OR: [
              { email: { contains: q, mode: 'insensitive' as const } },
              { displayName: { contains: q, mode: 'insensitive' as const } },
              { username: { contains: q, mode: 'insensitive' as const } },
              ...(isUuid ? [{ id: { equals: q } }] : []),
            ],
          }
        : {}),
      ...(query.walletStatus
        ? { wallet: { is: { status: query.walletStatus } } }
        : {}),
      ...(query.kycStatus
        ? { kycProfile: { is: { status: query.kycStatus } } }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.profile.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          roles: { select: { role: true } },
          wallet: true,
          kycProfile: true,
          ledgerAccounts: {
            where: { accountType: 'user', currency: 'BNT' },
            take: 1,
          },
        },
      }),
      this.prisma.profile.count({ where }),
    ]);

    return {
      data: rows.map((row) => {
        const account = row.ledgerAccounts[0];
        return {
          id: row.id,
          email: row.email,
          displayName: row.displayName,
          username: row.username,
          roles: row.roles.map((r) => r.role),
          createdAt: row.createdAt,
          wallet: row.wallet
            ? {
                id: row.wallet.id,
                status: row.wallet.status,
                address: row.wallet.address,
                providerWalletId: row.wallet.providerWalletId,
                chainId: row.wallet.chainId,
              }
            : null,
          balances: account
            ? {
                available: toDecimalString(account.available),
                pending: toDecimalString(account.pending),
                locked: toDecimalString(account.locked),
              }
            : null,
          kyc: row.kycProfile
            ? {
                status: row.kycProfile.status,
                tier: row.kycProfile.tier,
                submittedAt: row.kycProfile.submittedAt,
                reviewedAt: row.kycProfile.reviewedAt,
              }
            : null,
        };
      }),
      total,
      limit,
      offset,
    };
  }

  async listWithdrawals(query: ListWalletAdminWithdrawalsQuery) {
    const { limit, offset } = this.normalizePagination(
      query.limit,
      query.offset,
    );
    const q = query.q?.trim();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q) : false;

    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(q
        ? {
            OR: [
              { toAddress: { contains: q, mode: 'insensitive' as const } },
              {
                broadcastTxHash: { contains: q, mode: 'insensitive' as const },
              },
              ...(isUuid
                ? [{ id: { equals: q } }, { userId: { equals: q } }]
                : []),
              {
                requester: {
                  email: { contains: q, mode: 'insensitive' as const },
                },
              },
              {
                requester: {
                  displayName: { contains: q, mode: 'insensitive' as const },
                },
              },
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.withdrawalRequest.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          requester: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          reviewer: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
        },
      }),
      this.prisma.withdrawalRequest.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        status: row.status,
        toAddress: row.toAddress,
        amount: toDecimalString(row.amount),
        feeAmount: toDecimalString(row.feeAmount),
        netAmount: toDecimalString(row.netAmount),
        reason: row.reason,
        rejectReason: row.rejectReason,
        failureReason: row.failureReason,
        broadcastTxHash: row.broadcastTxHash,
        confirmations: row.confirmations,
        requester: row.requester,
        reviewer: row.reviewer,
        requestedAt: row.requestedAt,
        reviewedAt: row.reviewedAt,
        confirmedAt: row.confirmedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async reviewWithdrawal(
    actorId: string,
    withdrawalId: string,
    dto: ReviewWithdrawalDto,
  ) {
    const withdrawal = await this.prisma.withdrawalRequest.findUnique({
      where: { id: withdrawalId },
      include: {
        requester: true,
      },
    });

    if (!withdrawal) {
      throw new NotFoundException('Withdrawal request not found');
    }

    if (
      withdrawal.status !== WithdrawalStatus.requested &&
      withdrawal.status !== WithdrawalStatus.pending_review
    ) {
      throw new BadRequestException('Withdrawal request is not pending review');
    }

    if (dto.status === WithdrawalReviewDecision.approved) {
      const updated = await this.prisma.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          status: WithdrawalStatus.approved,
          reviewedBy: actorId,
          reviewedAt: new Date(),
          rejectReason: null,
        },
      });

      await this.auditLogService.create({
        actorId,
        action: FinancialAuditActions.WithdrawalApproved,
        resourceType: 'withdrawal_request',
        resourceId: withdrawalId,
        metadata: {
          reason: dto.reason,
        },
      });

      return updated;
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const fresh = await tx.withdrawalRequest.findUnique({
        where: { id: withdrawalId },
      });

      if (!fresh) {
        throw new NotFoundException('Withdrawal request not found');
      }

      const [freshUserAccount, freshHoldAccount] = await Promise.all([
        tx.ledgerAccount.findUnique({
          where: {
            userId_accountType_currency: {
              userId: fresh.userId,
              accountType: 'user',
              currency: 'BNT',
            },
          },
        }),
        tx.ledgerAccount.findUnique({
          where: {
            userId_accountType_currency: {
              userId: fresh.userId,
              accountType: 'hold',
              currency: 'BNT',
            },
          },
        }),
      ]);

      if (!freshUserAccount || !freshHoldAccount) {
        throw new NotFoundException('Ledger accounts not found');
      }

      if (freshHoldAccount.available.lt(fresh.amount)) {
        throw new BadRequestException('Hold balance is lower than withdrawal');
      }

      await tx.ledgerAccount.update({
        where: { id: freshUserAccount.id },
        data: {
          available: freshUserAccount.available.add(fresh.amount),
          locked: freshUserAccount.locked.sub(fresh.amount),
        },
      });

      await tx.ledgerAccount.update({
        where: { id: freshHoldAccount.id },
        data: {
          available: freshHoldAccount.available.sub(fresh.amount),
        },
      });

      const releaseEntry = await tx.ledgerEntry.create({
        data: {
          debitAccountId: freshHoldAccount.id,
          creditAccountId: freshUserAccount.id,
          amount: fresh.amount,
          reason: LedgerReason.withdrawal_reject_release,
          idempotencyKey:
            normalizeIdempotencyKey(`${fresh.idempotencyKey}:reject`) ??
            `${fresh.idempotencyKey}:reject`,
          metadata: {
            withdrawalId: fresh.id,
            reason: dto.reason,
          },
        },
      });

      return tx.withdrawalRequest.update({
        where: { id: withdrawalId },
        data: {
          status: WithdrawalStatus.rejected,
          reviewedBy: actorId,
          reviewedAt: new Date(),
          rejectReason: dto.reason,
          finalizeLedgerEntryId: releaseEntry.id,
        },
      });
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.WithdrawalRejected,
      resourceType: 'withdrawal_request',
      resourceId: withdrawalId,
      metadata: {
        reason: dto.reason,
      },
    });

    return updated;
  }

  async listKyc(query: ListWalletKycQuery) {
    const { limit, offset } = this.normalizePagination(
      query.limit,
      query.offset,
    );
    const q = query.q?.trim();
    const uuidRegex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isUuid = q ? uuidRegex.test(q) : false;

    const where = {
      ...(query.status ? { status: query.status } : {}),
      ...(q
        ? {
            OR: [
              {
                user: {
                  email: { contains: q, mode: 'insensitive' as const },
                },
              },
              {
                user: {
                  displayName: { contains: q, mode: 'insensitive' as const },
                },
              },
              ...(isUuid ? [{ userId: { equals: q } }] : []),
            ],
          }
        : {}),
    };

    const [rows, total] = await Promise.all([
      this.prisma.kycProfile.findMany({
        where,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: offset,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
          reviewer: {
            select: {
              id: true,
              email: true,
              displayName: true,
            },
          },
        },
      }),
      this.prisma.kycProfile.count({ where }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        userId: row.userId,
        user: row.user,
        status: row.status,
        tier: row.tier,
        country: row.country,
        fullName: row.fullName,
        documentType: row.documentType,
        documentNumberLast4: row.documentNumberLast4,
        documentUrl: row.documentUrl,
        submittedAt: row.submittedAt,
        reviewedAt: row.reviewedAt,
        reviewNote: row.reviewNote,
        reviewer: row.reviewer,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      })),
      total,
      limit,
      offset,
    };
  }

  async reviewKyc(actorId: string, userId: string, dto: ReviewKycDto) {
    if (
      dto.status !== KycStatus.approved &&
      dto.status !== KycStatus.rejected
    ) {
      throw new BadRequestException(
        'KYC review status must be approved or rejected',
      );
    }

    const existing = await this.prisma.kycProfile.findUnique({
      where: { userId },
    });

    if (!existing) {
      throw new NotFoundException('KYC profile not found');
    }

    const nextTier = dto.tier?.trim() || existing.tier;
    if (dto.status === KycStatus.approved) {
      const tierExists = await this.prisma.riskLimit.findUnique({
        where: { tier: nextTier },
        select: { id: true },
      });
      if (!tierExists) {
        throw new BadRequestException(`Unknown risk tier: ${nextTier}`);
      }
    }

    const updated = await this.prisma.kycProfile.update({
      where: { userId },
      data: {
        status: dto.status,
        tier: nextTier,
        reviewedBy: actorId,
        reviewedAt: new Date(),
        reviewNote: dto.note.trim(),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.KycReviewed,
      resourceType: 'kyc_profile',
      resourceId: updated.id,
      metadata: {
        userId,
        status: updated.status,
        tier: updated.tier,
        note: dto.note,
      },
    });

    return updated;
  }

  async listRiskLimits() {
    return this.prisma.riskLimit.findMany({
      orderBy: { tier: 'asc' },
    });
  }

  async updateRiskLimit(
    actorId: string,
    tier: string,
    dto: UpdateRiskLimitDto,
  ) {
    const existing = await this.prisma.riskLimit.findUnique({
      where: { tier },
    });
    if (!existing) {
      throw new NotFoundException('Risk limit tier not found');
    }

    const updated = await this.prisma.riskLimit.update({
      where: { tier },
      data: {
        ...(dto.description !== undefined
          ? { description: dto.description.trim() || null }
          : {}),
        ...(dto.requiresKyc !== undefined
          ? { requiresKyc: dto.requiresKyc }
          : {}),
        ...(dto.maxWithdrawalPerTx !== undefined
          ? {
              maxWithdrawalPerTx: this.parseNonNegativeDecimal(
                dto.maxWithdrawalPerTx,
                'maxWithdrawalPerTx',
              ),
            }
          : {}),
        ...(dto.maxWithdrawalPerDay !== undefined
          ? {
              maxWithdrawalPerDay: this.parseNonNegativeDecimal(
                dto.maxWithdrawalPerDay,
                'maxWithdrawalPerDay',
              ),
            }
          : {}),
        ...(dto.maxInternalTransferPerDay !== undefined
          ? {
              maxInternalTransferPerDay: this.parseNonNegativeDecimal(
                dto.maxInternalTransferPerDay,
                'maxInternalTransferPerDay',
              ),
            }
          : {}),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.RiskLimitUpdated,
      resourceType: 'risk_limit',
      resourceId: updated.id,
      metadata: {
        tier,
      },
    });

    return updated;
  }

  async listFeeConfigs() {
    return this.prisma.walletFeeConfig.findMany({
      orderBy: [{ isActive: 'desc' }, { updatedAt: 'desc' }],
    });
  }

  async updateFeeConfig(actorId: string, key: string, dto: UpdateWalletFeeDto) {
    const existing = await this.prisma.walletFeeConfig.findUnique({
      where: { key },
    });
    if (!existing) {
      throw new NotFoundException('Fee config not found');
    }

    const updated = await this.prisma.walletFeeConfig.update({
      where: { key },
      data: {
        ...(dto.flatFee !== undefined
          ? { flatFee: this.parseNonNegativeDecimal(dto.flatFee, 'flatFee') }
          : {}),
        ...(dto.percentFee !== undefined
          ? {
              percentFee: this.parseNonNegativeDecimal(
                dto.percentFee,
                'percentFee',
              ),
            }
          : {}),
        ...(dto.minFee !== undefined
          ? { minFee: this.parseNonNegativeDecimal(dto.minFee, 'minFee') }
          : {}),
        ...(dto.maxFee !== undefined
          ? {
              maxFee:
                dto.maxFee === null || dto.maxFee === ''
                  ? null
                  : this.parseNonNegativeDecimal(dto.maxFee, 'maxFee'),
            }
          : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.FeeConfigUpdated,
      resourceType: 'wallet_fee_config',
      resourceId: updated.id,
      metadata: {
        key,
      },
    });

    return updated;
  }

  async listAssetPriceConfigs() {
    return this.walletAssetPricingService.listPriceConfigs();
  }

  async updateAssetPriceConfig(
    actorId: string,
    assetRaw: string,
    dto: UpdateWalletAssetPriceDto,
  ) {
    const asset = normalizeWalletAsset(assetRaw);
    if (!asset) {
      throw new BadRequestException('Invalid wallet asset');
    }

    let updated;
    try {
      updated = await this.walletAssetPricingService.updatePriceConfig(asset, {
        providerId: dto.providerId,
        fallbackUsdPrice: dto.fallbackUsdPrice,
        isActive: dto.isActive,
      });
    } catch (error) {
      throw new BadRequestException(
        error instanceof Error ? error.message : 'Invalid price config payload',
      );
    }

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.AssetPriceConfigUpdated,
      resourceType: 'wallet_asset_price_config',
      resourceId: updated.id,
      metadata: {
        asset,
      },
    });

    return updated;
  }

  private async checkNetworkHealth(chainEnvironment: ChainEnvironment) {
    const isTestnet = chainEnvironment === ChainEnvironment.testnet;
    const chainId = isTestnet
      ? this.walletConfigService.bscTestnetChainId
      : this.walletConfigService.bscMainnetChainId;
    const rpcUrl = isTestnet
      ? this.walletConfigService.bscRpcTestnet
      : this.walletConfigService.bscRpcMainnet;
    const tokenAddress = isTestnet
      ? this.walletConfigService.bntTokenAddressTestnet
      : this.walletConfigService.bntTokenAddressMainnet;
    const treasuryWalletId = isTestnet
      ? this.walletConfigService.treasuryWalletIdTestnet
      : this.walletConfigService.treasuryWalletIdMainnet;
    const treasurySweepAddress = isTestnet
      ? this.walletConfigService.treasurySweepAddressTestnet
      : this.walletConfigService.treasurySweepAddressMainnet;
    const depositStartBlock = isTestnet
      ? this.walletConfigService.depositStartBlockTestnet
      : this.walletConfigService.depositStartBlockMainnet;

    if (!rpcUrl) {
      return {
        chainEnvironment,
        chainId,
        rpcConfigured: false,
        rpcReachable: false,
        latestBlock: null,
        rpcError: 'RPC URL is not configured',
        tokenAddressConfigured: Boolean(tokenAddress),
        tokenAddress: tokenAddress ?? null,
        treasuryWalletIdConfigured: Boolean(treasuryWalletId),
        treasurySweepAddressConfigured: Boolean(treasurySweepAddress),
        confirmationsRequired:
          this.walletConfigService.getWithdrawalConfirmationsForEnvironment(
            chainEnvironment,
          ),
        depositStartBlock: depositStartBlock?.toString() ?? null,
      };
    }

    try {
      const client = createPublicClient({ transport: http(rpcUrl) });
      const latestBlock = await client.getBlockNumber();
      return {
        chainEnvironment,
        chainId,
        rpcConfigured: true,
        rpcReachable: true,
        latestBlock: latestBlock.toString(),
        rpcError: null,
        tokenAddressConfigured: Boolean(tokenAddress),
        tokenAddress: tokenAddress ?? null,
        treasuryWalletIdConfigured: Boolean(treasuryWalletId),
        treasurySweepAddressConfigured: Boolean(treasurySweepAddress),
        confirmationsRequired:
          this.walletConfigService.getWithdrawalConfirmationsForEnvironment(
            chainEnvironment,
          ),
        depositStartBlock: depositStartBlock?.toString() ?? null,
      };
    } catch (error) {
      return {
        chainEnvironment,
        chainId,
        rpcConfigured: true,
        rpcReachable: false,
        latestBlock: null,
        rpcError: error instanceof Error ? error.message : 'RPC call failed',
        tokenAddressConfigured: Boolean(tokenAddress),
        tokenAddress: tokenAddress ?? null,
        treasuryWalletIdConfigured: Boolean(treasuryWalletId),
        treasurySweepAddressConfigured: Boolean(treasurySweepAddress),
        confirmationsRequired:
          this.walletConfigService.getWithdrawalConfirmationsForEnvironment(
            chainEnvironment,
          ),
        depositStartBlock: depositStartBlock?.toString() ?? null,
      };
    }
  }

  private normalizePagination(limit?: number, offset?: number) {
    const safeLimit =
      Number.isFinite(limit) && typeof limit === 'number'
        ? Math.min(Math.max(limit, 1), MAX_PAGE_SIZE)
        : DEFAULT_PAGE_SIZE;
    const safeOffset =
      Number.isFinite(offset) && typeof offset === 'number'
        ? Math.max(offset, 0)
        : 0;

    return { limit: safeLimit, offset: safeOffset };
  }

  private parseNonNegativeDecimal(
    value: string,
    fieldName: string,
  ): Prisma.Decimal {
    let decimal: Prisma.Decimal;
    try {
      decimal = new Prisma.Decimal(value);
    } catch {
      throw new BadRequestException(
        `${fieldName} must be a valid decimal value`,
      );
    }

    if (decimal.lt(DECIMAL_ZERO)) {
      throw new BadRequestException(`${fieldName} cannot be negative`);
    }
    return decimal;
  }
}
