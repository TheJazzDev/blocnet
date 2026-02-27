import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  KycStatus,
  LedgerAccountType,
  LedgerReason,
  Prisma,
  WalletAsset,
  WalletStatus,
  WithdrawalStatus,
  type LedgerEntry,
  type UserWallet,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import {
  createDeterministicIdempotencyKey,
  normalizeIdempotencyKey,
} from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import { CreateInternalTransferDto } from './dto/create-internal-transfer.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import {
  DECIMAL_ZERO,
  decimalMax,
  decimalMin,
  parsePositiveDecimal,
  toDecimalString,
} from './types/decimal';
import {
  getWithdrawalFeeKeyForAsset,
  normalizeWalletAsset,
  WALLET_ASSETS,
} from './wallet-asset.util';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';

const EVM_ADDRESS_PATTERN = /^0x[a-fA-F0-9]{40}$/;

@Injectable()
export class WalletTransactionService {
  private readonly logger = new Logger(WalletTransactionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletProvisioningService: WalletProvisioningService,
    private readonly walletAssetPricingService: WalletAssetPricingService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async createInternalTransfer(userId: string, dto: CreateInternalTransferDto) {
    this.assertWalletFeatureEnabled();

    const asset = this.resolveRequestedAsset(dto.asset);
    if (!this.walletConfigService.isTransferEnabledForAsset(asset)) {
      throw new ServiceUnavailableException(
        `${asset} transfers are currently disabled`,
      );
    }

    const amount = parsePositiveDecimal(dto.amount, 'amount');
    const senderWallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);
    this.assertWalletActionAvailable(
      senderWallet,
      'Wallet is disabled for this account',
    );
    const senderAccount =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        userId,
        senderWallet.id,
        LedgerAccountType.user,
        asset,
      );

    if (dto.toUserId && dto.toUserId === userId) {
      throw new BadRequestException('Cannot transfer to yourself');
    }

    const riskLimit = await this.resolveRiskLimitForUser(userId);
    const maxPerDay = new Prisma.Decimal(riskLimit.maxInternalTransferPerDay);
    if (maxPerDay.gt(DECIMAL_ZERO)) {
      const [dailyUsedUsd, requestUsd] = await Promise.all([
        this.getTodayInternalTransferUsdUsed(userId),
        this.toUsdValue(asset, amount),
      ]);
      if (dailyUsedUsd.add(requestUsd).gt(maxPerDay)) {
        throw new BadRequestException(
          'Internal transfer amount exceeds daily tier limit',
        );
      }
    }

    const recipientWallet = await this.resolveRecipientWallet(dto, userId);
    this.assertWalletActionAvailable(
      recipientWallet,
      'Recipient wallet is disabled',
    );
    const recipientAccount =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        recipientWallet.userId,
        recipientWallet.id,
        LedgerAccountType.user,
        asset,
      );

    const idempotencyKey =
      normalizeIdempotencyKey(dto.idempotencyKey) ??
      createDeterministicIdempotencyKey(
        'internal-transfer',
        userId,
        recipientWallet.userId,
        asset,
        amount.toString(),
        randomUUID(),
      );

    const result = await this.prisma.$transaction(
      async (tx) => {
        const existing = await tx.ledgerEntry.findUnique({
          where: { idempotencyKey },
          include: {
            debitAccount: {
              select: {
                userId: true,
                accountType: true,
                currency: true,
                user: {
                  select: {
                    id: true,
                    username: true,
                    displayName: true,
                  },
                },
                wallet: {
                  select: {
                    address: true,
                  },
                },
              },
            },
            creditAccount: {
              select: {
                userId: true,
                accountType: true,
                currency: true,
                user: {
                  select: {
                    id: true,
                    username: true,
                    displayName: true,
                  },
                },
                wallet: {
                  select: {
                    address: true,
                  },
                },
              },
            },
          },
        });

        if (existing) {
          return existing;
        }

        const freshSender = await tx.ledgerAccount.findUnique({
          where: { id: senderAccount.id },
        });
        if (!freshSender) {
          throw new NotFoundException('Sender wallet account not found');
        }

        if (freshSender.available.lt(amount)) {
          throw new BadRequestException('Insufficient available balance');
        }

        await tx.ledgerAccount.update({
          where: { id: senderAccount.id },
          data: {
            available: freshSender.available.sub(amount),
          },
        });

        const freshRecipient = await tx.ledgerAccount.findUnique({
          where: { id: recipientAccount.id },
        });
        if (!freshRecipient) {
          throw new NotFoundException('Recipient wallet account not found');
        }

        await tx.ledgerAccount.update({
          where: { id: recipientAccount.id },
          data: {
            available: freshRecipient.available.add(amount),
          },
        });

        return tx.ledgerEntry.create({
          data: {
            debitAccountId: senderAccount.id,
            creditAccountId: recipientAccount.id,
            amount,
            reason: LedgerReason.internal_transfer,
            idempotencyKey,
            metadata: {
              note: dto.note ?? null,
              senderUserId: userId,
              recipientUserId: recipientWallet.userId,
              senderAddress: senderWallet.address,
              recipientAddress: recipientWallet.address,
              recipientUsername:
                dto.toUsername?.trim().replace(/^@/, '') ?? null,
              asset,
            },
          },
          include: {
            debitAccount: {
              select: {
                userId: true,
                accountType: true,
                currency: true,
                user: {
                  select: {
                    id: true,
                    username: true,
                    displayName: true,
                  },
                },
                wallet: {
                  select: {
                    address: true,
                  },
                },
              },
            },
            creditAccount: {
              select: {
                userId: true,
                accountType: true,
                currency: true,
                user: {
                  select: {
                    id: true,
                    username: true,
                    displayName: true,
                  },
                },
                wallet: {
                  select: {
                    address: true,
                  },
                },
              },
            },
          },
        });
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    await this.auditLogService.create({
      actorId: userId,
      action: FinancialAuditActions.LedgerTransferInternal,
      resourceType: 'ledger_entry',
      resourceId: result.id,
      metadata: {
        toUserId: recipientWallet.userId,
        amount: amount.toString(),
        asset,
        idempotencyKey,
      },
    });

    return this.toTransactionResponse(userId, result);
  }

  async submitKyc(userId: string, dto: SubmitKycDto) {
    const profile = await this.prisma.kycProfile.upsert({
      where: { userId },
      update: {
        status: KycStatus.pending,
        fullName: dto.fullName.trim(),
        country: dto.country.trim(),
        documentType: dto.documentType.trim(),
        documentNumberLast4: dto.documentNumberLast4.trim(),
        documentUrl: dto.documentUrl?.trim() || null,
        submittedAt: new Date(),
        reviewedBy: null,
        reviewedAt: null,
        reviewNote: null,
      },
      create: {
        userId,
        status: KycStatus.pending,
        tier: 'basic',
        fullName: dto.fullName.trim(),
        country: dto.country.trim(),
        documentType: dto.documentType.trim(),
        documentNumberLast4: dto.documentNumberLast4.trim(),
        documentUrl: dto.documentUrl?.trim() || null,
        submittedAt: new Date(),
      },
    });

    await this.auditLogService.create({
      actorId: userId,
      action: FinancialAuditActions.KycSubmitted,
      resourceType: 'kyc_profile',
      resourceId: profile.id,
      metadata: {
        status: profile.status,
        tier: profile.tier,
      },
    });

    return {
      userId,
      status: profile.status,
      tier: profile.tier,
      submittedAt: profile.submittedAt,
      reviewedAt: profile.reviewedAt,
      reviewNote: profile.reviewNote,
    };
  }

  async createWithdrawal(userId: string, dto: CreateWithdrawalDto) {
    this.assertWalletFeatureEnabled();

    const asset = this.resolveRequestedAsset(dto.asset);
    if (!this.walletConfigService.isWithdrawalEnabledForAsset(asset)) {
      throw new ServiceUnavailableException(
        `${asset} withdrawals are currently disabled`,
      );
    }

    if (!EVM_ADDRESS_PATTERN.test(dto.toAddress.trim())) {
      throw new BadRequestException('Invalid withdrawal address');
    }

    const amount = parsePositiveDecimal(dto.amount, 'amount');

    const wallet =
      await this.walletProvisioningService.ensureWalletForUser(userId);
    this.assertWalletActionAvailable(
      wallet,
      'Wallet is disabled for this account',
    );
    const userAccount =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        userId,
        wallet.id,
        LedgerAccountType.user,
        asset,
      );
    const holdAccount =
      await this.walletProvisioningService.ensureUserLedgerAccount(
        userId,
        wallet.id,
        LedgerAccountType.hold,
        asset,
      );

    const [kycProfile, riskLimit, feeConfig] = await Promise.all([
      this.prisma.kycProfile.findUnique({ where: { userId } }),
      this.resolveRiskLimitForUser(userId),
      this.resolveActiveWithdrawalFeeConfig(asset),
    ]);

    if (
      !kycProfile ||
      (riskLimit.requiresKyc && kycProfile.status !== KycStatus.approved)
    ) {
      throw new BadRequestException('KYC approval is required for withdrawals');
    }

    const maxPerTx = new Prisma.Decimal(riskLimit.maxWithdrawalPerTx);
    const amountUsd = await this.toUsdValue(asset, amount);
    if (maxPerTx.gt(DECIMAL_ZERO) && amountUsd.gt(maxPerTx)) {
      throw new BadRequestException(
        'Withdrawal amount exceeds tier per-tx limit',
      );
    }

    const dayStart = this.getUtcDayStart();
    const todays = await this.prisma.withdrawalRequest.findMany({
      where: {
        userId,
        status: {
          in: [
            WithdrawalStatus.requested,
            WithdrawalStatus.pending_review,
            WithdrawalStatus.approved,
            WithdrawalStatus.broadcasting,
            WithdrawalStatus.confirmed,
          ],
        },
        requestedAt: {
          gte: dayStart,
        },
      },
      select: {
        amount: true,
        asset: true,
      },
    });

    const dailyUsed = await this.sumUsdByAssetRows(todays);
    const maxPerDay = new Prisma.Decimal(riskLimit.maxWithdrawalPerDay);
    if (maxPerDay.gt(DECIMAL_ZERO) && dailyUsed.add(amountUsd).gt(maxPerDay)) {
      throw new BadRequestException(
        'Withdrawal amount exceeds daily tier limit',
      );
    }

    const feeAmount = this.calculateWithdrawalFee(amount, feeConfig);
    const netAmount = amount.sub(feeAmount);
    if (netAmount.lte(DECIMAL_ZERO)) {
      throw new BadRequestException('Withdrawal net amount must be positive');
    }

    const idempotencyKey =
      normalizeIdempotencyKey(dto.idempotencyKey) ??
      createDeterministicIdempotencyKey(
        'withdrawal',
        userId,
        asset,
        dto.toAddress.trim().toLowerCase(),
        amount.toString(),
        randomUUID(),
      );

    const created = await this.prisma.$transaction(
      async (tx) => {
        const existing = await tx.withdrawalRequest.findUnique({
          where: { idempotencyKey },
        });
        if (existing) {
          return existing;
        }

        const freshUserAccount = await tx.ledgerAccount.findUnique({
          where: { id: userAccount.id },
        });
        if (!freshUserAccount) {
          throw new NotFoundException('Wallet account not found');
        }

        if (freshUserAccount.available.lt(amount)) {
          throw new BadRequestException('Insufficient available balance');
        }

        const freshHoldAccount = await tx.ledgerAccount.findUnique({
          where: { id: holdAccount.id },
        });
        if (!freshHoldAccount) {
          throw new NotFoundException('Hold account not found');
        }

        await tx.ledgerAccount.update({
          where: { id: userAccount.id },
          data: {
            available: freshUserAccount.available.sub(amount),
            locked: freshUserAccount.locked.add(amount),
          },
        });

        await tx.ledgerAccount.update({
          where: { id: holdAccount.id },
          data: {
            available: freshHoldAccount.available.add(amount),
          },
        });

        const holdEntry = await tx.ledgerEntry.create({
          data: {
            debitAccountId: userAccount.id,
            creditAccountId: holdAccount.id,
            amount,
            reason: LedgerReason.withdrawal_hold,
            idempotencyKey: `${idempotencyKey}:hold`,
            metadata: {
              userId,
              toAddress: dto.toAddress.trim(),
              asset,
            },
          },
        });

        return tx.withdrawalRequest.create({
          data: {
            userId,
            walletId: wallet.id,
            asset,
            toAddress: dto.toAddress.trim(),
            amount,
            feeAmount,
            netAmount,
            status: WithdrawalStatus.pending_review,
            reason: dto.reason.trim(),
            idempotencyKey,
            holdLedgerEntryId: holdEntry.id,
          },
        });
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    await this.auditLogService.create({
      actorId: userId,
      action: FinancialAuditActions.WithdrawalRequested,
      resourceType: 'withdrawal_request',
      resourceId: created.id,
      metadata: {
        asset,
        amount: created.amount.toString(),
        feeAmount: created.feeAmount.toString(),
        netAmount: created.netAmount.toString(),
        status: created.status,
        idempotencyKey,
      },
    });

    return this.toWithdrawalResponse(created);
  }

  private async resolveRecipientWallet(
    dto: CreateInternalTransferDto,
    actorUserId: string,
  ): Promise<UserWallet> {
    if (!dto.toUserId && !dto.toAddress && !dto.toUsername) {
      throw new BadRequestException(
        'Either toUserId, toAddress, or toUsername is required',
      );
    }

    if (dto.toUserId) {
      if (dto.toUserId === actorUserId) {
        throw new BadRequestException('Cannot transfer to yourself');
      }
      return this.walletProvisioningService.ensureWalletForUser(dto.toUserId);
    }

    if (dto.toUsername) {
      const normalized = dto.toUsername.trim().replace(/^@/, '').toLowerCase();
      if (!normalized) {
        throw new BadRequestException('Invalid recipient username');
      }
      const recipientProfile = await this.prisma.profile.findFirst({
        where: {
          username: {
            equals: normalized,
            mode: 'insensitive',
          },
        },
        select: {
          id: true,
        },
      });
      if (!recipientProfile) {
        throw new NotFoundException('Recipient user not found');
      }
      if (recipientProfile.id === actorUserId) {
        throw new BadRequestException('Cannot transfer to yourself');
      }
      return this.walletProvisioningService.ensureWalletForUser(
        recipientProfile.id,
      );
    }

    const address = dto.toAddress?.trim();
    if (!address || !EVM_ADDRESS_PATTERN.test(address)) {
      throw new BadRequestException('Invalid recipient address');
    }

    const wallet = await this.prisma.userWallet.findFirst({
      where: {
        address: {
          equals: address,
          mode: 'insensitive',
        },
      },
    });

    if (!wallet) {
      throw new NotFoundException('Recipient wallet not found');
    }

    if (wallet.userId === actorUserId) {
      throw new BadRequestException('Cannot transfer to yourself');
    }

    return wallet;
  }

  private toTransactionResponse(
    userId: string,
    entry: LedgerEntry & {
      debitAccount: {
        userId: string | null;
        accountType: LedgerAccountType;
        currency: string;
        user: {
          id: string;
          username: string | null;
          displayName: string | null;
        } | null;
        wallet: {
          address: string | null;
        } | null;
      };
      creditAccount: {
        userId: string | null;
        accountType: LedgerAccountType;
        currency: string;
        user: {
          id: string;
          username: string | null;
          displayName: string | null;
        } | null;
        wallet: {
          address: string | null;
        } | null;
      };
    },
  ) {
    const isDebit = entry.debitAccount.userId === userId;
    const isCredit = entry.creditAccount.userId === userId;
    const reason = entry.reason;

    let direction: 'outgoing' | 'incoming' | 'internal';
    if (
      reason === LedgerReason.withdrawal_hold ||
      reason === LedgerReason.withdrawal_finalize ||
      reason === LedgerReason.withdrawal_fee
    ) {
      direction = 'outgoing';
    } else if (reason === LedgerReason.withdrawal_reject_release) {
      direction = 'incoming';
    } else {
      direction =
        isDebit && !isCredit
          ? 'outgoing'
          : !isDebit && isCredit
            ? 'incoming'
            : 'internal';
    }

    const metadata = this.normalizeLedgerMetadata(entry.metadata);

    const asset =
      normalizeWalletAsset(entry.debitAccount.currency) ??
      normalizeWalletAsset(entry.creditAccount.currency) ??
      WalletAsset.BNT;

    const sourceAccount =
      direction === 'incoming'
        ? entry.debitAccount
        : direction === 'outgoing'
          ? entry.creditAccount
          : null;
    const counterparty =
      sourceAccount && sourceAccount.userId && sourceAccount.userId !== userId
        ? {
            userId: sourceAccount.userId,
            username: sourceAccount.user?.username ?? null,
            displayName: sourceAccount.user?.displayName ?? null,
            walletAddress: sourceAccount.wallet?.address ?? null,
          }
        : null;

    return {
      id: entry.id,
      asset,
      direction,
      reason,
      amount: toDecimalString(entry.amount),
      feeAmount: toDecimalString(entry.feeAmount),
      debit: {
        userId: entry.debitAccount.userId,
        accountType: entry.debitAccount.accountType,
      },
      credit: {
        userId: entry.creditAccount.userId,
        accountType: entry.creditAccount.accountType,
      },
      referenceId: entry.referenceId,
      metadata,
      counterparty,
      createdAt: entry.createdAt,
    };
  }

  private normalizeLedgerMetadata(
    input: Prisma.JsonValue | null,
  ): Prisma.JsonObject | null {
    if (!input || typeof input !== 'object' || Array.isArray(input)) {
      return null;
    }
    return input;
  }

  private toWithdrawalResponse(withdrawal: {
    id: string;
    asset: WalletAsset;
    toAddress: string;
    amount: Prisma.Decimal;
    feeAmount: Prisma.Decimal;
    netAmount: Prisma.Decimal;
    status: WithdrawalStatus;
    reason: string;
    rejectReason: string | null;
    broadcastTxHash: string | null;
    requestedAt: Date;
    reviewedAt: Date | null;
    confirmedAt: Date | null;
    failureReason: string | null;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: withdrawal.id,
      asset: withdrawal.asset,
      toAddress: withdrawal.toAddress,
      amount: toDecimalString(withdrawal.amount),
      feeAmount: toDecimalString(withdrawal.feeAmount),
      netAmount: toDecimalString(withdrawal.netAmount),
      status: withdrawal.status,
      reason: withdrawal.reason,
      rejectReason: withdrawal.rejectReason,
      broadcastTxHash: withdrawal.broadcastTxHash,
      failureReason: withdrawal.failureReason,
      requestedAt: withdrawal.requestedAt,
      reviewedAt: withdrawal.reviewedAt,
      confirmedAt: withdrawal.confirmedAt,
      createdAt: withdrawal.createdAt,
      updatedAt: withdrawal.updatedAt,
    };
  }

  private assertWalletFeatureEnabled() {
    if (!this.walletConfigService.walletEnabled) {
      throw new ServiceUnavailableException('Wallet feature is disabled');
    }
  }

  private assertWalletActionAvailable(
    wallet: Pick<UserWallet, 'status'>,
    message: string,
  ) {
    if (wallet.status === WalletStatus.disabled) {
      throw new ServiceUnavailableException(message);
    }
  }

  private async resolveRiskLimitForUser(userId: string) {
    const kycProfile = await this.prisma.kycProfile.findUnique({
      where: { userId },
      select: { tier: true },
    });

    const tier = kycProfile?.tier ?? 'basic';
    const limit = await this.prisma.riskLimit.findUnique({
      where: { tier },
    });

    if (limit) {
      return limit;
    }

    const fallback = await this.prisma.riskLimit.findUnique({
      where: { tier: 'basic' },
    });

    if (!fallback) {
      throw new ServiceUnavailableException('Risk limits are not configured');
    }

    return fallback;
  }

  private async resolveActiveWithdrawalFeeConfig(asset: WalletAsset) {
    const key = getWithdrawalFeeKeyForAsset(asset);
    const feeConfig = await this.prisma.walletFeeConfig.findFirst({
      where: {
        key,
        isActive: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    if (!feeConfig) {
      throw new ServiceUnavailableException(
        `Withdrawal fee config is missing for ${asset}`,
      );
    }

    return feeConfig;
  }

  private calculateWithdrawalFee(
    amount: Prisma.Decimal,
    feeConfig: {
      flatFee: Prisma.Decimal;
      percentFee: Prisma.Decimal;
      minFee: Prisma.Decimal;
      maxFee: Prisma.Decimal | null;
    },
  ): Prisma.Decimal {
    const percent = new Prisma.Decimal(feeConfig.percentFee);
    const percentFee = amount.mul(percent).div(100);
    let fee = new Prisma.Decimal(feeConfig.flatFee).add(percentFee);
    fee = decimalMax(fee, new Prisma.Decimal(feeConfig.minFee));
    if (feeConfig.maxFee) {
      fee = decimalMin(fee, new Prisma.Decimal(feeConfig.maxFee));
    }
    return fee;
  }

  private resolveRequestedAsset(rawAsset: WalletAsset | undefined) {
    if (!rawAsset) {
      return WalletAsset.BNT;
    }
    const parsed = normalizeWalletAsset(String(rawAsset));
    if (!parsed || !WALLET_ASSETS.includes(parsed)) {
      throw new BadRequestException('Unsupported wallet asset');
    }
    if (!this.walletConfigService.isAssetEnabled(parsed)) {
      throw new BadRequestException(`${parsed} is not enabled`);
    }
    return parsed;
  }

  private async toUsdValue(asset: WalletAsset, amount: Prisma.Decimal) {
    const price = await this.walletAssetPricingService.getUsdPrice(asset);
    return amount.mul(new Prisma.Decimal(price.usdPrice));
  }

  private async getTodayInternalTransferUsdUsed(userId: string) {
    const dayStart = this.getUtcDayStart();
    const rows = await this.prisma.ledgerEntry.findMany({
      where: {
        reason: LedgerReason.internal_transfer,
        createdAt: {
          gte: dayStart,
        },
        debitAccount: {
          userId,
        },
      },
      select: {
        amount: true,
        debitAccount: {
          select: {
            currency: true,
          },
        },
      },
    });

    const normalizedRows = rows.map((row) => ({
      amount: row.amount,
      asset: normalizeWalletAsset(row.debitAccount.currency) ?? WalletAsset.BNT,
    }));
    return this.sumUsdByAssetRows(normalizedRows);
  }

  private async sumUsdByAssetRows(
    rows: Array<{ amount: Prisma.Decimal; asset: WalletAsset }>,
  ) {
    if (rows.length === 0) {
      return DECIMAL_ZERO;
    }

    const uniqueAssets = [...new Set(rows.map((row) => row.asset))];
    const prices =
      await this.walletAssetPricingService.getUsdPrices(uniqueAssets);

    return rows.reduce((total, row) => {
      const price = prices[row.asset];
      if (!price) return total;
      return total.add(row.amount.mul(new Prisma.Decimal(price.usdPrice)));
    }, DECIMAL_ZERO);
  }

  private getUtcDayStart(): Date {
    const now = new Date();
    return new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
  }
}
