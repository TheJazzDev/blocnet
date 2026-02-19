import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  KycStatus,
  LedgerAccountType,
  LedgerReason,
  Prisma,
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
import { ListWalletTransactionsQuery } from './dto/list-wallet-transactions.query';
import { ListWithdrawalsQuery } from './dto/list-withdrawals.query';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import {
  DECIMAL_ZERO,
  decimalMax,
  decimalMin,
  parsePositiveDecimal,
  toDecimalString,
} from './types/decimal';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';

const DEFAULT_PAGE_SIZE = 30;
const MAX_PAGE_SIZE = 100;
const EVM_ADDRESS_PATTERN = /^0x[a-fA-F0-9]{40}$/;

@Injectable()
export class WalletService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletProvisioningService: WalletProvisioningService,
    private readonly auditLogService: AuditLogService,
  ) {}

  async getWalletSummary(userId: string) {
    const wallet = await this.walletProvisioningService.ensureWalletForUser(userId);

    const [userAccount, kycProfile] = await Promise.all([
      this.walletProvisioningService.ensureUserLedgerAccount(userId, wallet.id),
      this.prisma.kycProfile.findUnique({
        where: { userId },
        select: {
          status: true,
          tier: true,
          submittedAt: true,
          reviewedAt: true,
        },
      }),
    ]);

    return {
      wallet: this.toWalletSummary(wallet),
      balances: {
        available: toDecimalString(userAccount.available),
        pending: toDecimalString(userAccount.pending),
        locked: toDecimalString(userAccount.locked),
      },
      kyc: {
        status: kycProfile?.status ?? KycStatus.not_submitted,
        tier: kycProfile?.tier ?? 'basic',
        submittedAt: kycProfile?.submittedAt ?? null,
        reviewedAt: kycProfile?.reviewedAt ?? null,
      },
      features: {
        walletEnabled: this.walletConfigService.walletEnabled,
        depositsEnabled: this.walletConfigService.depositsEnabled,
        withdrawalsEnabled: this.walletConfigService.withdrawalsEnabled,
      },
    };
  }

  async listWalletTransactions(
    userId: string,
    query: ListWalletTransactionsQuery,
  ) {
    const wallet = await this.walletProvisioningService.ensureWalletForUser(userId);
    const account = await this.walletProvisioningService.ensureUserLedgerAccount(
      userId,
      wallet.id,
    );
    const holdAccount = await this.walletProvisioningService.ensureUserLedgerAccount(
      userId,
      wallet.id,
      LedgerAccountType.hold,
    );

    const { limit, offset } = this.normalizePagination(query.limit, query.offset);

    const entries = await this.prisma.ledgerEntry.findMany({
      where: {
        OR: [
          { debitAccountId: account.id },
          { creditAccountId: account.id },
          { debitAccountId: holdAccount.id },
          { creditAccountId: holdAccount.id },
        ],
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
      include: {
        debitAccount: {
          select: {
            userId: true,
            accountType: true,
            currency: true,
          },
        },
        creditAccount: {
          select: {
            userId: true,
            accountType: true,
            currency: true,
          },
        },
      },
    });

    return entries.map((entry) => this.toTransactionResponse(userId, entry));
  }

  async createInternalTransfer(userId: string, dto: CreateInternalTransferDto) {
    this.assertWalletFeatureEnabled();

    const amount = parsePositiveDecimal(dto.amount, 'amount');
    const senderWallet = await this.walletProvisioningService.ensureWalletForUser(userId);
    const senderAccount = await this.walletProvisioningService.ensureUserLedgerAccount(
      userId,
      senderWallet.id,
    );

    if (dto.toUserId && dto.toUserId === userId) {
      throw new BadRequestException('Cannot transfer to yourself');
    }

    const recipientWallet = await this.resolveRecipientWallet(dto, userId);
    const recipientAccount = await this.walletProvisioningService.ensureUserLedgerAccount(
      recipientWallet.userId,
      recipientWallet.id,
    );

    const idempotencyKey =
      normalizeIdempotencyKey(dto.idempotencyKey) ??
      createDeterministicIdempotencyKey(
        'internal-transfer',
        userId,
        recipientWallet.userId,
        amount.toString(),
        randomUUID(),
      );

    const result = await this.prisma.$transaction(
      async (tx) => {
        const existing = await tx.ledgerEntry.findUnique({
          where: { idempotencyKey },
          include: {
            debitAccount: true,
            creditAccount: true,
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
            },
          },
          include: {
            debitAccount: true,
            creditAccount: true,
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

  async getKycStatus(userId: string) {
    await this.walletProvisioningService.ensureWalletForUser(userId);

    const profile = await this.prisma.kycProfile.findUnique({
      where: { userId },
      select: {
        status: true,
        tier: true,
        submittedAt: true,
        reviewedAt: true,
        reviewNote: true,
      },
    });

    return {
      status: profile?.status ?? KycStatus.not_submitted,
      tier: profile?.tier ?? 'basic',
      submittedAt: profile?.submittedAt ?? null,
      reviewedAt: profile?.reviewedAt ?? null,
      reviewNote: profile?.reviewNote ?? null,
    };
  }

  async createWithdrawal(userId: string, dto: CreateWithdrawalDto) {
    this.assertWalletFeatureEnabled();

    if (!this.walletConfigService.withdrawalsEnabled) {
      throw new ServiceUnavailableException('Withdrawals are disabled');
    }

    if (!EVM_ADDRESS_PATTERN.test(dto.toAddress.trim())) {
      throw new BadRequestException('Invalid withdrawal address');
    }

    const amount = parsePositiveDecimal(dto.amount, 'amount');

    const wallet = await this.walletProvisioningService.ensureWalletForUser(userId);
    const userAccount = await this.walletProvisioningService.ensureUserLedgerAccount(
      userId,
      wallet.id,
    );
    const holdAccount = await this.walletProvisioningService.ensureUserLedgerAccount(
      userId,
      wallet.id,
      LedgerAccountType.hold,
    );

    const [kycProfile, riskLimit, feeConfig] = await Promise.all([
      this.prisma.kycProfile.findUnique({ where: { userId } }),
      this.resolveRiskLimitForUser(userId),
      this.resolveActiveWithdrawalFeeConfig(),
    ]);

    if (!kycProfile || (riskLimit.requiresKyc && kycProfile.status !== KycStatus.approved)) {
      throw new BadRequestException('KYC approval is required for withdrawals');
    }

    const maxPerTx = new Prisma.Decimal(riskLimit.maxWithdrawalPerTx);
    if (maxPerTx.gt(DECIMAL_ZERO) && amount.gt(maxPerTx)) {
      throw new BadRequestException('Withdrawal amount exceeds tier per-tx limit');
    }

    const dayStart = this.getUtcDayStart();
    const todays = await this.prisma.withdrawalRequest.aggregate({
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
      _sum: {
        amount: true,
      },
    });

    const dailyUsed = todays._sum.amount ?? DECIMAL_ZERO;
    const maxPerDay = new Prisma.Decimal(riskLimit.maxWithdrawalPerDay);
    if (maxPerDay.gt(DECIMAL_ZERO) && dailyUsed.add(amount).gt(maxPerDay)) {
      throw new BadRequestException('Withdrawal amount exceeds daily tier limit');
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
            },
          },
        });

        return tx.withdrawalRequest.create({
          data: {
            userId,
            walletId: wallet.id,
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
        amount: created.amount.toString(),
        feeAmount: created.feeAmount.toString(),
        netAmount: created.netAmount.toString(),
        status: created.status,
        idempotencyKey,
      },
    });

    return this.toWithdrawalResponse(created);
  }

  async listWithdrawals(userId: string, query: ListWithdrawalsQuery) {
    await this.walletProvisioningService.ensureWalletForUser(userId);
    const { limit, offset } = this.normalizePagination(query.limit, query.offset);

    const rows = await this.prisma.withdrawalRequest.findMany({
      where: {
        userId,
        ...(query.status ? { status: query.status } : {}),
      },
      orderBy: { createdAt: 'desc' },
      skip: offset,
      take: limit,
    });

    return rows.map((row) => this.toWithdrawalResponse(row));
  }

  private async resolveRecipientWallet(
    dto: CreateInternalTransferDto,
    actorUserId: string,
  ): Promise<UserWallet> {
    if (!dto.toUserId && !dto.toAddress) {
      throw new BadRequestException('Either toUserId or toAddress is required');
    }

    if (dto.toUserId) {
      return this.walletProvisioningService.ensureWalletForUser(dto.toUserId);
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

  private toWalletSummary(wallet: UserWallet) {
    return {
      id: wallet.id,
      status: wallet.status,
      address: wallet.address,
      chainId: wallet.chainId,
      chainEnvironment: wallet.chainEnvironment,
      provider: wallet.provider,
      providerWalletId: wallet.providerWalletId,
      failureReason: wallet.failureReason,
      provisionedAt: wallet.provisionedAt,
    };
  }

  private toTransactionResponse(
    userId: string,
    entry: LedgerEntry & {
      debitAccount: { userId: string | null; accountType: LedgerAccountType };
      creditAccount: { userId: string | null; accountType: LedgerAccountType };
    },
  ) {
    const isDebit = entry.debitAccount.userId === userId;
    const isCredit = entry.creditAccount.userId === userId;

    const direction = isDebit && !isCredit ? 'outgoing' : !isDebit && isCredit ? 'incoming' : 'internal';

    return {
      id: entry.id,
      direction,
      reason: entry.reason,
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
      metadata: entry.metadata,
      createdAt: entry.createdAt,
    };
  }

  private toWithdrawalResponse(withdrawal: {
    id: string;
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

  private normalizePagination(limit?: number, offset?: number) {
    const safeLimit =
      Number.isFinite(limit) && typeof limit === 'number'
        ? Math.min(Math.max(limit, 1), MAX_PAGE_SIZE)
        : DEFAULT_PAGE_SIZE;
    const safeOffset =
      Number.isFinite(offset) && typeof offset === 'number'
        ? Math.max(offset, 0)
        : 0;

    return {
      limit: safeLimit,
      offset: safeOffset,
    };
  }

  private assertWalletFeatureEnabled() {
    if (!this.walletConfigService.walletEnabled) {
      throw new ServiceUnavailableException('Wallet feature is disabled');
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

  private async resolveActiveWithdrawalFeeConfig() {
    const feeConfig = await this.prisma.walletFeeConfig.findFirst({
      where: {
        key: 'withdrawal_bnt_v1',
        isActive: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    if (!feeConfig) {
      throw new ServiceUnavailableException('Withdrawal fee config is missing');
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

  private getUtcDayStart(): Date {
    const now = new Date();
    return new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
  }
}
