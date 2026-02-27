import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ChainEnvironment,
  Prisma,
  WalletStatus,
  type UserWallet,
} from '@prisma/client';
import { createPublicClient, http } from 'viem';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { PrismaService } from '../prisma/prisma.service';
import { TurnkeyCustodyAdapter } from './custody/turnkey-custody.adapter';
import { normalizePagination } from '../common/utils/pagination.util';
import { ListWalletUsersQuery } from './dto/list-wallet-users.query';
import { ReprocessDepositByTxHashDto } from './dto/reprocess-deposit-by-tx-hash.dto';
import { UpdateWalletRuntimeConfigDto } from './dto/update-wallet-runtime-config.dto';
import { toDecimalString } from './types/decimal';
import { WalletConfigService } from './wallet-config.service';
import { WalletDepositIndexerService } from './wallet-deposit-indexer.service';

@Injectable()
export class WalletAdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletDepositIndexerService: WalletDepositIndexerService,
    private readonly turnkeyCustodyAdapter: TurnkeyCustodyAdapter,
  ) {}

  async getWalletHealth() {
    const [
      turnkey,
      networks,
      walletCounts,
      depositCounts,
      sweepCounts,
      withdrawalCounts,
      ledgerTotalsByCurrency,
      tipBalancesByCurrency,
      tipVolumeByCurrency,
      tipCurrencies,
      creditedDepositsByAsset,
      lifetimeMinedAggregate,
      lifetimeClaimedAggregate,
      lifetimeMinersRows,
    ] = await Promise.all([
      this.turnkeyCustodyAdapter.getHealth(),
      Promise.all([
        this.checkNetworkHealth(
          this.walletConfigService.walletChainEnvironment,
        ),
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
      this.prisma.ledgerAccount.groupBy({
        by: ['currency'],
        where: {
          accountType: 'user',
        },
        _sum: {
          available: true,
          pending: true,
          locked: true,
        },
        _count: {
          _all: true,
        },
      }),
      this.prisma.tipAccount.groupBy({
        by: ['currencyCode'],
        where: {
          accountType: 'user',
        },
        _sum: {
          balanceAtomic: true,
        },
        _count: {
          _all: true,
        },
      }),
      this.prisma.tipTransaction.groupBy({
        by: ['currencyCode'],
        where: {
          type: 'tip',
        },
        _sum: {
          amountAtomic: true,
          feeAtomic: true,
        },
        _count: {
          _all: true,
        },
      }),
      this.prisma.tipCurrency.findMany({
        select: {
          code: true,
          symbol: true,
          decimals: true,
          kind: true,
        },
      }),
      this.prisma.onchainDeposit.groupBy({
        by: ['asset'],
        where: {
          status: 'credited',
        },
        _sum: {
          amount: true,
        },
        _count: {
          _all: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.aggregate({
        where: {
          claimedAt: {
            not: null,
          },
        },
        _sum: {
          points: true,
        },
      }),
      this.prisma.miningHourlyCheckpoint.findMany({
        select: {
          userId: true,
        },
        distinct: ['userId'],
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

    const walletAssetHoldings = ledgerTotalsByCurrency.map((row) => {
      const available = toDecimalString(row._sum.available);
      const pending = toDecimalString(row._sum.pending);
      const locked = toDecimalString(row._sum.locked);
      return {
        asset: row.currency,
        accounts: row._count._all,
        totalAvailable: available,
        totalPending: pending,
        totalLocked: locked,
        totalBalance: new Prisma.Decimal(available)
          .plus(pending)
          .plus(locked)
          .toString(),
      };
    });

    const tipCurrencyMap = new Map(
      tipCurrencies.map((row) => [row.code, row] as const),
    );
    const tipBalanceMap = new Map(
      tipBalancesByCurrency.map((row) => [row.currencyCode, row] as const),
    );
    const tipVolumeMap = new Map(
      tipVolumeByCurrency.map((row) => [row.currencyCode, row] as const),
    );
    const tipCodes = Array.from(
      new Set([
        ...tipBalanceMap.keys(),
        ...tipVolumeMap.keys(),
        ...tipCurrencyMap.keys(),
      ]),
    ).sort();

    const tipCurrencyTotals = tipCodes.map((currencyCode) => {
      const currency = tipCurrencyMap.get(currencyCode);
      const decimals = currency?.decimals ?? 0;
      const balance = tipBalanceMap.get(currencyCode);
      const volume = tipVolumeMap.get(currencyCode);
      const totalBalanceAtomic = balance?._sum.balanceAtomic ?? 0n;
      const totalTippedAtomic = volume?._sum.amountAtomic ?? 0n;
      const totalFeesAtomic = volume?._sum.feeAtomic ?? 0n;
      return {
        currencyCode,
        symbol: currency?.symbol ?? currencyCode,
        decimals,
        kind: currency?.kind ?? 'token',
        holders: balance?._count._all ?? 0,
        transactions: volume?._count._all ?? 0,
        totalUserBalanceAtomic: totalBalanceAtomic.toString(),
        totalUserBalance: this.formatAtomicAmount(totalBalanceAtomic, decimals),
        totalTippedAtomic: totalTippedAtomic.toString(),
        totalTipped: this.formatAtomicAmount(totalTippedAtomic, decimals),
        totalFeesAtomic: totalFeesAtomic.toString(),
        totalFees: this.formatAtomicAmount(totalFeesAtomic, decimals),
      };
    });

    const creditedDepositsTotals = creditedDepositsByAsset.map((row) => ({
      asset: row.asset,
      count: row._count._all,
      totalAmount: toDecimalString(row._sum.amount),
    }));

    const lifetimeMinedMcr = lifetimeMinedAggregate._sum.points ?? 0;
    const lifetimeClaimedMcr = lifetimeClaimedAggregate._sum.points ?? 0;
    const lifetimeUnclaimedMcr = Math.max(
      lifetimeMinedMcr - lifetimeClaimedMcr,
      0,
    );

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
      economy: {
        walletAssetHoldings,
        tipCurrencyTotals,
        creditedDepositsTotals,
        mining: {
          lifetimeMinedMcr,
          lifetimeClaimedMcr,
          lifetimeUnclaimedMcr,
          totalMiners: lifetimeMinersRows.length,
        },
      },
    };
  }

  async reprocessDepositByTxHash(
    actorId: string,
    dto: ReprocessDepositByTxHashDto,
  ) {
    const result =
      await this.walletDepositIndexerService.reprocessTransactionByHash({
        txHash: dto.txHash,
        chainEnvironment: dto.chainEnvironment,
        asset: dto.asset,
      });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.WalletDepositReprocessTriggered,
      resourceType: 'wallet_manual_deposit_reprocess',
      resourceId: result.txHash,
      metadata: {
        txHash: result.txHash,
        chainEnvironment: result.chainEnvironment,
        txBlockNumber: result.txBlockNumber,
        headBlockNumber: result.headBlockNumber,
        summary: result.summary,
      },
    });

    return result;
  }

  async listWalletUsers(query: ListWalletUsersQuery) {
    const { limit, offset } = normalizePagination(query.offset, query.limit);
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

  async updateWalletUserStatus(
    actorId: string,
    userId: string,
    disabled: boolean,
  ) {
    const user = await this.prisma.profile.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        displayName: true,
      },
    });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const existing = await this.prisma.userWallet.findUnique({
      where: { userId },
    });

    let wallet: UserWallet;
    if (!existing) {
      if (!disabled) {
        throw new BadRequestException('Wallet does not exist for this user');
      }

      wallet = await this.prisma.userWallet.create({
        data: {
          userId,
          chainEnvironment: this.walletConfigService.walletChainEnvironment,
          chainId: this.walletConfigService.walletProvisionChainId,
          status: WalletStatus.disabled,
          failureReason: 'Disabled by admin',
        },
      });
    } else {
      const nextStatus = disabled
        ? WalletStatus.disabled
        : this.resolveStatusWhenEnabled(existing);

      wallet =
        existing.status === nextStatus
          ? existing
          : await this.prisma.userWallet.update({
              where: { id: existing.id },
              data: {
                status: nextStatus,
                failureReason: disabled ? 'Disabled by admin' : null,
              },
            });
    }

    await this.auditLogService.create({
      actorId,
      action: disabled
        ? FinancialAuditActions.WalletUserDisabled
        : FinancialAuditActions.WalletUserEnabled,
      resourceType: 'user_wallet',
      resourceId: wallet.id,
      metadata: {
        userId,
        email: user.email,
        walletStatus: wallet.status,
      },
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
      wallet: {
        id: wallet.id,
        status: wallet.status,
        address: wallet.address,
        providerWalletId: wallet.providerWalletId,
        chainId: wallet.chainId,
        chainEnvironment: wallet.chainEnvironment,
        updatedAt: wallet.updatedAt,
      },
    };
  }

  private resolveStatusWhenEnabled(wallet: {
    address: string | null;
    providerWalletId: string | null;
  }): WalletStatus {
    return wallet.address && wallet.providerWalletId
      ? WalletStatus.ready
      : WalletStatus.provisioning;
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

  private formatAtomicAmount(value: bigint, decimals: number): string {
    if (decimals <= 0) {
      return value.toString();
    }

    const isNegative = value < 0n;
    const absolute = isNegative ? -value : value;
    const multiplier = 10n ** BigInt(decimals);
    const whole = absolute / multiplier;
    const fraction = absolute % multiplier;
    const fractionString = fraction
      .toString()
      .padStart(decimals, '0')
      .replace(/0+$/, '');

    if (fractionString.length === 0) {
      return `${isNegative ? '-' : ''}${whole.toString()}`;
    }

    return `${isNegative ? '-' : ''}${whole.toString()}.${fractionString}`;
  }
}
