import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import {
  ChainEnvironment,
  LedgerReason,
  OnchainDepositStatus,
  Prisma,
  WalletAssetKind,
  type UserWallet,
} from '@prisma/client';
import {
  createPublicClient,
  formatUnits,
  http,
  parseAbiItem,
  webSocket,
  type Address,
  type PublicClient,
} from 'viem';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { createDeterministicIdempotencyKey } from '../common/utils/idempotency.util';
import { PrismaService } from '../prisma/prisma.service';
import {
  WalletConfigService,
  type WalletDepositNetworkConfig,
} from './wallet-config.service';

const TRANSFER_EVENT = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)',
);
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
type WalletAddressRecord = { walletId: string; userId: string; address: string };
type WalletAddressMap = Map<string, WalletAddressRecord>;

@Injectable()
export class WalletDepositIndexerService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(WalletDepositIndexerService.name);
  private readonly httpClients = new Map<ChainEnvironment, PublicClient>();
  private readonly realtimeClients = new Map<ChainEnvironment, PublicClient>();
  private readonly latestScannedBlock = new Map<string, bigint>();
  private readonly realtimeNetworkKeys = new Set<string>();
  private readonly realtimeUnwatchByNetwork = new Map<string, () => void>();
  private readonly realtimeQueues = new Map<string, Promise<void>>();
  private readonly walletAddressCacheByEnvironment = new Map<
    ChainEnvironment,
    WalletAddressMap
  >();
  private readonly walletAddressCacheUpdatedAt = new Map<ChainEnvironment, number>();

  private intervalHandle: NodeJS.Timeout | null = null;
  private isTickRunning = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly auditLogService: AuditLogService,
  ) {}

  onModuleInit(): void {
    if (!this.walletConfigService.depositIndexerEnabled) {
      this.logger.log(
        'Deposit indexer disabled (WALLET_ENABLED or DEPOSITS_ENABLED is false)',
      );
      return;
    }

    const networks = this.walletConfigService.getDepositNetworkConfigs();
    if (networks.length === 0) {
      this.logger.warn(
        'Deposit indexer enabled but no deposit networks are configured (missing RPC URL or token address)',
      );
      return;
    }

    this.initializeRealtimeSubscriptions(networks);

    const intervalMs = this.walletConfigService.depositPollIntervalMs;
    this.intervalHandle = setInterval(() => {
      void this.tick();
    }, intervalMs);

    void this.tick();
    this.logger.log(
      `Deposit indexer started (interval=${intervalMs}ms networks=${networks
        .map((n) => n.chainEnvironment)
        .join(',')} realtime=${this.realtimeNetworkKeys.size})`,
    );
  }

  onModuleDestroy(): void {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
    for (const [networkKey, unwatch] of this.realtimeUnwatchByNetwork.entries()) {
      try {
        unwatch();
      } catch {
        this.logger.warn(`Failed to stop realtime deposit stream for ${networkKey}`);
      }
    }
    this.realtimeUnwatchByNetwork.clear();
    this.realtimeNetworkKeys.clear();
    this.realtimeQueues.clear();
  }

  private async tick(): Promise<void> {
    if (this.isTickRunning) {
      return;
    }

    this.isTickRunning = true;
    try {
      const networks = this.walletConfigService.getDepositNetworkConfigs();
      for (const network of networks) {
        await this.processNetwork(network);
      }
    } catch (error) {
      this.logger.error(
        `Deposit indexer tick failed: ${this.errorMessage(error)}`,
      );
    } finally {
      this.isTickRunning = false;
    }
  }

  private async processNetwork(
    network: WalletDepositNetworkConfig,
  ): Promise<void> {
    const client = this.getHttpClient(network);
    const currentBlock = await client.getBlockNumber();
    const walletByAddress = await this.getWalletAddressMap(network.chainEnvironment);

    if (
      walletByAddress.size > 0 &&
      !this.isRealtimeStreamingEnabledForNetwork(network)
    ) {
      await this.scanNewTransfers(network, client, walletByAddress, currentBlock);
    }

    await this.finalizeDetectedDeposits(network, currentBlock);
  }

  private getHttpClient(network: WalletDepositNetworkConfig): PublicClient {
    const existing = this.httpClients.get(network.chainEnvironment);
    if (existing) {
      return existing;
    }

    const client = createPublicClient({
      transport: http(network.rpcUrl),
    });

    this.httpClients.set(network.chainEnvironment, client);
    return client;
  }

  private getRealtimeClient(network: WalletDepositNetworkConfig): PublicClient {
    if (!network.wsRpcUrl) {
      throw new Error('Realtime RPC URL is not configured for network');
    }

    const existing = this.realtimeClients.get(network.chainEnvironment);
    if (existing) {
      return existing;
    }

    const client = createPublicClient({
      transport: webSocket(network.wsRpcUrl),
    });

    this.realtimeClients.set(network.chainEnvironment, client);
    return client;
  }

  private createWalletAddressMap(
    wallets: Array<Pick<UserWallet, 'id' | 'userId' | 'address'>>,
  ): WalletAddressMap {
    const map = new Map<string, WalletAddressRecord>();

    for (const wallet of wallets) {
      const normalized = this.normalizeAddress(wallet.address);
      if (!normalized) {
        continue;
      }

      map.set(normalized, {
        walletId: wallet.id,
        userId: wallet.userId,
        address: wallet.address!,
      });
    }

    return map;
  }

  private async getWalletAddressMap(
    chainEnvironment: ChainEnvironment,
  ): Promise<WalletAddressMap> {
    const staleAfterMs = Math.max(
      this.walletConfigService.depositPollIntervalMs,
      5_000,
    );
    const now = Date.now();
    const cached = this.walletAddressCacheByEnvironment.get(chainEnvironment);
    const updatedAt = this.walletAddressCacheUpdatedAt.get(chainEnvironment) ?? 0;
    if (cached && now - updatedAt < staleAfterMs) {
      return cached;
    }

    const wallets = await this.prisma.userWallet.findMany({
      where: {
        chainEnvironment,
        address: { not: null },
      },
      select: {
        id: true,
        userId: true,
        address: true,
      },
    });
    const map = this.createWalletAddressMap(wallets);
    this.walletAddressCacheByEnvironment.set(chainEnvironment, map);
    this.walletAddressCacheUpdatedAt.set(chainEnvironment, now);
    return map;
  }

  private initializeRealtimeSubscriptions(
    networks: WalletDepositNetworkConfig[],
  ): void {
    if (!this.walletConfigService.walletDepositRealtimeEnabled) {
      return;
    }

    for (const network of networks) {
      if (!network.wsRpcUrl) {
        continue;
      }
      this.startRealtimeStream(network);
    }
  }

  private startRealtimeStream(network: WalletDepositNetworkConfig): void {
    const networkKey = this.scanCursorKey(network);
    if (this.realtimeNetworkKeys.has(networkKey)) {
      return;
    }

    try {
      const client = this.getRealtimeClient(network);
      this.realtimeNetworkKeys.add(networkKey);

      void this.getHttpClient(network)
        .getBlockNumber()
        .then((head) => {
          this.latestScannedBlock.set(networkKey, head);
        })
        .catch((error) => {
          this.logger.warn(
            `Failed to initialize realtime cursor for ${networkKey}: ${this.errorMessage(
              error,
            )}`,
          );
        });

      if (network.assetKind === WalletAssetKind.native) {
        const unwatch = client.watchBlocks({
          includeTransactions: true,
          emitOnBegin: false,
          onBlock: (block) => {
            this.enqueueRealtimeTask(network, () =>
              this.handleRealtimeNativeBlock(network, block as { number: bigint; transactions: unknown[] }),
            );
          },
          onError: (error) => {
            this.logger.error(
              `Realtime native stream error for ${networkKey}: ${this.errorMessage(
                error,
              )}`,
            );
          },
        });

        this.realtimeUnwatchByNetwork.set(networkKey, unwatch);
        this.logger.log(`Realtime native deposit stream enabled for ${networkKey}`);
        return;
      }

      if (!network.tokenAddress) {
        this.realtimeNetworkKeys.delete(networkKey);
        return;
      }

      const unwatch = client.watchEvent({
        address: network.tokenAddress,
        event: TRANSFER_EVENT,
        onLogs: (logs) => {
          this.enqueueRealtimeTask(network, () =>
            this.handleRealtimeTokenLogs(network, logs),
          );
        },
        onError: (error) => {
          this.logger.error(
            `Realtime token stream error for ${networkKey}: ${this.errorMessage(
              error,
            )}`,
          );
        },
      });
      this.realtimeUnwatchByNetwork.set(networkKey, unwatch);
      this.logger.log(`Realtime token deposit stream enabled for ${networkKey}`);
    } catch (error) {
      this.realtimeNetworkKeys.delete(networkKey);
      this.logger.warn(
        `Failed to start realtime stream for ${networkKey}: ${this.errorMessage(
          error,
        )}`,
      );
    }
  }

  private isRealtimeStreamingEnabledForNetwork(
    network: WalletDepositNetworkConfig,
  ): boolean {
    if (!this.walletConfigService.walletDepositRealtimeEnabled) {
      return false;
    }
    return this.realtimeNetworkKeys.has(this.scanCursorKey(network));
  }

  private enqueueRealtimeTask(
    network: WalletDepositNetworkConfig,
    task: () => Promise<void>,
  ): void {
    const networkKey = this.scanCursorKey(network);
    const previous = this.realtimeQueues.get(networkKey) ?? Promise.resolve();
    const next = previous
      .catch(() => undefined)
      .then(task)
      .catch((error) => {
        this.logger.error(
          `Realtime deposit processing failed for ${networkKey}: ${this.errorMessage(
            error,
          )}`,
        );
      });
    this.realtimeQueues.set(networkKey, next);
  }

  private async handleRealtimeTokenLogs(
    network: WalletDepositNetworkConfig,
    logs: readonly {
      args?: { from?: Address; to?: Address; value?: bigint };
      transactionHash?: `0x${string}`;
      blockNumber?: bigint | null;
      logIndex?: bigint | number | null;
    }[],
  ): Promise<void> {
    if (logs.length === 0) {
      return;
    }

    const walletByAddress = await this.getWalletAddressMap(network.chainEnvironment);
    if (walletByAddress.size === 0) {
      return;
    }

    const currentBlock = await this.getHttpClient(network).getBlockNumber();
    for (const log of logs) {
      const toAddress = this.normalizeAddress(log.args?.to);
      if (!toAddress) continue;

      const wallet = walletByAddress.get(toAddress);
      if (!wallet) continue;

      const amountRaw = log.args?.value;
      if (typeof amountRaw !== 'bigint' || amountRaw <= 0n) continue;

      const transactionHash = log.transactionHash;
      const blockNumber = log.blockNumber;
      const logIndex = this.toLogIndex(log.logIndex ?? null);
      if (
        !transactionHash ||
        blockNumber === null ||
        blockNumber === undefined ||
        logIndex === null
      ) {
        continue;
      }

      const confirmations = this.computeConfirmations(currentBlock, blockNumber);
      const fromAddress = this.normalizeAddress(log.args?.from) ?? ZERO_ADDRESS;

      const deposit = await this.recordDetectedDeposit({
        walletId: wallet.walletId,
        userId: wallet.userId,
        toAddress: wallet.address,
        fromAddress,
        txHash: transactionHash,
        logIndex,
        blockNumber,
        amount: formatUnits(amountRaw, network.decimals),
        confirmations,
        chainEnvironment: network.chainEnvironment,
        asset: network.asset,
        assetKind: network.assetKind,
        tokenAddress: network.tokenAddress,
      });

      if (confirmations >= network.confirmationsRequired) {
        await this.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }
    }
  }

  private async handleRealtimeNativeBlock(
    network: WalletDepositNetworkConfig,
    block: { number: bigint; transactions: unknown[] },
  ): Promise<void> {
    const walletByAddress = await this.getWalletAddressMap(network.chainEnvironment);
    if (walletByAddress.size === 0) {
      return;
    }

    const currentBlock = await this.getHttpClient(network).getBlockNumber();
    for (const rawTx of block.transactions) {
      if (typeof rawTx === 'string') {
        continue;
      }

      const tx = rawTx as {
        to?: Address | null;
        from?: Address | null;
        hash?: `0x${string}`;
        value?: bigint;
        transactionIndex?: bigint | number | null;
      };

      const toAddress = this.normalizeAddress(tx.to);
      if (!toAddress) continue;

      const wallet = walletByAddress.get(toAddress);
      if (!wallet) continue;

      const value = tx.value;
      if (typeof value !== 'bigint' || value <= 0n) continue;

      const txHash = tx.hash;
      if (!txHash) continue;

      const txIndex = this.toLogIndex(tx.transactionIndex ?? null) ?? 0;
      const fromAddress = this.normalizeAddress(tx.from) ?? ZERO_ADDRESS;
      const confirmations = this.computeConfirmations(currentBlock, block.number);

      const deposit = await this.recordDetectedDeposit({
        walletId: wallet.walletId,
        userId: wallet.userId,
        toAddress: wallet.address,
        fromAddress,
        txHash,
        logIndex: txIndex,
        blockNumber: block.number,
        amount: formatUnits(value, network.decimals),
        confirmations,
        chainEnvironment: network.chainEnvironment,
        asset: network.asset,
        assetKind: network.assetKind,
        tokenAddress: null,
      });

      if (confirmations >= network.confirmationsRequired) {
        await this.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }
    }
  }

  private async scanNewTransfers(
    network: WalletDepositNetworkConfig,
    client: PublicClient,
    walletByAddress: Map<
      string,
      { walletId: string; userId: string; address: string }
    >,
    currentBlock: bigint,
  ): Promise<void> {
    const fromBlock = await this.resolveFromBlock(network, currentBlock);
    if (fromBlock > currentBlock) {
      return;
    }

    const toBlock = this.minBigInt(
      currentBlock,
      fromBlock + this.walletConfigService.depositMaxRangePerTick - 1n,
    );

    const blockChunkSize = this.walletConfigService.depositBlockChunkSize;

    for (
      let startBlock = fromBlock;
      startBlock <= toBlock;
      startBlock += blockChunkSize
    ) {
      const endBlock = this.minBigInt(
        toBlock,
        startBlock + blockChunkSize - 1n,
      );

      if (network.assetKind === WalletAssetKind.native) {
        await this.scanNativeTransfers(
          network,
          client,
          walletByAddress,
          currentBlock,
          startBlock,
          endBlock,
        );
      } else {
        await this.scanTokenTransfers(
          network,
          client,
          walletByAddress,
          currentBlock,
          startBlock,
          endBlock,
        );
      }
    }

    this.latestScannedBlock.set(this.scanCursorKey(network), toBlock);
  }

  private async scanTokenTransfers(
    network: WalletDepositNetworkConfig,
    client: PublicClient,
    walletByAddress: Map<
      string,
      { walletId: string; userId: string; address: string }
    >,
    currentBlock: bigint,
    startBlock: bigint,
    endBlock: bigint,
  ) {
    if (!network.tokenAddress) {
      return;
    }

    const logs = await client.getLogs({
      address: network.tokenAddress,
      event: TRANSFER_EVENT,
      fromBlock: startBlock,
      toBlock: endBlock,
    });

    for (const log of logs) {
      const toAddress = this.normalizeAddress(log.args.to);
      if (!toAddress) continue;

      const wallet = walletByAddress.get(toAddress);
      if (!wallet) continue;

      const amountRaw = log.args.value;
      if (typeof amountRaw !== 'bigint' || amountRaw <= 0n) continue;

      const transactionHash = log.transactionHash;
      const blockNumber = log.blockNumber;
      const logIndex = this.toLogIndex(log.logIndex);
      if (!transactionHash || blockNumber === null || logIndex === null)
        continue;

      const confirmations = this.computeConfirmations(
        currentBlock,
        blockNumber,
      );
      const fromAddress = this.normalizeAddress(log.args.from) ?? ZERO_ADDRESS;

      const deposit = await this.recordDetectedDeposit({
        walletId: wallet.walletId,
        userId: wallet.userId,
        toAddress: wallet.address,
        fromAddress,
        txHash: transactionHash,
        logIndex,
        blockNumber,
        amount: formatUnits(amountRaw, network.decimals),
        confirmations,
        chainEnvironment: network.chainEnvironment,
        asset: network.asset,
        assetKind: network.assetKind,
        tokenAddress: network.tokenAddress,
      });

      if (confirmations >= network.confirmationsRequired) {
        await this.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }
    }
  }

  private async scanNativeTransfers(
    network: WalletDepositNetworkConfig,
    client: PublicClient,
    walletByAddress: Map<
      string,
      { walletId: string; userId: string; address: string }
    >,
    currentBlock: bigint,
    startBlock: bigint,
    endBlock: bigint,
  ) {
    for (
      let blockNumber = startBlock;
      blockNumber <= endBlock;
      blockNumber += 1n
    ) {
      const block = await client.getBlock({
        blockNumber,
        includeTransactions: true,
      });

      for (const tx of block.transactions) {
        const toAddress = this.normalizeAddress(tx.to);
        if (!toAddress) continue;

        const wallet = walletByAddress.get(toAddress);
        if (!wallet) continue;

        if (tx.value <= 0n) continue;

        const txHash = tx.hash;
        const txIndex = this.toLogIndex(tx.transactionIndex ?? null) ?? 0;
        const fromAddress = this.normalizeAddress(tx.from) ?? ZERO_ADDRESS;
        const confirmations = this.computeConfirmations(
          currentBlock,
          block.number,
        );

        const deposit = await this.recordDetectedDeposit({
          walletId: wallet.walletId,
          userId: wallet.userId,
          toAddress: wallet.address,
          fromAddress,
          txHash,
          logIndex: txIndex,
          blockNumber: block.number,
          amount: formatUnits(tx.value, network.decimals),
          confirmations,
          chainEnvironment: network.chainEnvironment,
          asset: network.asset,
          assetKind: network.assetKind,
          tokenAddress: null,
        });

        if (confirmations >= network.confirmationsRequired) {
          await this.creditDetectedDeposit(
            deposit.id,
            network.confirmationsRequired,
            currentBlock,
          );
        }
      }
    }
  }

  private async resolveFromBlock(
    network: WalletDepositNetworkConfig,
    currentBlock: bigint,
  ): Promise<bigint> {
    const latest = this.latestScannedBlock.get(this.scanCursorKey(network));
    if (latest !== undefined) {
      return latest + 1n;
    }

    const aggregate = await this.prisma.onchainDeposit.aggregate({
      where: {
        wallet: {
          chainEnvironment: network.chainEnvironment,
        },
        asset: network.asset,
      },
      _max: {
        blockNumber: true,
      },
    });

    const knownMaxBlock = aggregate._max.blockNumber;
    if (knownMaxBlock !== null) {
      this.latestScannedBlock.set(this.scanCursorKey(network), knownMaxBlock);
      return knownMaxBlock + 1n;
    }

    if (network.startBlock !== null) {
      return network.startBlock;
    }

    const lookback = this.walletConfigService.depositInitialLookbackBlocks;
    if (currentBlock > lookback) {
      return currentBlock - lookback;
    }

    return 0n;
  }

  private async recordDetectedDeposit(input: {
    walletId: string;
    userId: string;
    fromAddress: string;
    toAddress: string;
    txHash: string;
    logIndex: number;
    blockNumber: bigint;
    amount: string;
    confirmations: number;
    chainEnvironment: ChainEnvironment;
    asset: WalletDepositNetworkConfig['asset'];
    assetKind: WalletDepositNetworkConfig['assetKind'];
    tokenAddress: WalletDepositNetworkConfig['tokenAddress'];
  }) {
    const existing = await this.prisma.onchainDeposit.findUnique({
      where: {
        txHash_logIndex_asset: {
          txHash: input.txHash,
          logIndex: input.logIndex,
          asset: input.asset,
        },
      },
    });

    if (existing) {
      if (existing.confirmations !== input.confirmations) {
        return this.prisma.onchainDeposit.update({
          where: { id: existing.id },
          data: {
            confirmations: input.confirmations,
          },
        });
      }

      return existing;
    }

    const created = await this.prisma.onchainDeposit.create({
      data: {
        walletId: input.walletId,
        fromAddress: input.fromAddress,
        toAddress: input.toAddress,
        amount: input.amount,
        asset: input.asset,
        assetKind: input.assetKind,
        tokenAddress: input.tokenAddress,
        txHash: input.txHash,
        logIndex: input.logIndex,
        blockNumber: input.blockNumber,
        confirmations: input.confirmations,
        status: OnchainDepositStatus.detected,
        idempotencyKey: createDeterministicIdempotencyKey(
          'deposit-detect',
          input.chainEnvironment,
          input.asset,
          input.txHash,
          input.logIndex,
        ),
      },
    });

    await this.auditLogService.create({
      actorId: input.userId,
      action: FinancialAuditActions.DepositDetected,
      resourceType: 'onchain_deposit',
      resourceId: created.id,
      metadata: {
        walletId: input.walletId,
        txHash: input.txHash,
        logIndex: input.logIndex,
        amount: input.amount,
        asset: input.asset,
      },
    });

    return created;
  }

  private async finalizeDetectedDeposits(
    network: WalletDepositNetworkConfig,
    currentBlock: bigint,
  ): Promise<void> {
    const confirmationsRequired = BigInt(network.confirmationsRequired);
    const cutoffBlock =
      confirmationsRequired > 1n
        ? currentBlock - (confirmationsRequired - 1n)
        : currentBlock;

    const candidates = await this.prisma.onchainDeposit.findMany({
      where: {
        status: OnchainDepositStatus.detected,
        wallet: {
          chainEnvironment: network.chainEnvironment,
        },
        asset: network.asset,
        blockNumber: {
          lte: cutoffBlock,
        },
      },
      select: {
        id: true,
      },
      orderBy: {
        blockNumber: 'asc',
      },
      take: 200,
    });

    for (const candidate of candidates) {
      await this.creditDetectedDeposit(
        candidate.id,
        network.confirmationsRequired,
        currentBlock,
      );
    }
  }

  private async creditDetectedDeposit(
    depositId: string,
    confirmationsRequired: number,
    currentBlock: bigint,
  ) {
    const result = await this.prisma.$transaction(
      async (tx) => {
        const deposit = await tx.onchainDeposit.findUnique({
          where: { id: depositId },
          include: {
            wallet: {
              select: {
                userId: true,
                id: true,
              },
            },
          },
        });

        if (!deposit) {
          return null;
        }

        const confirmations = this.computeConfirmations(
          currentBlock,
          deposit.blockNumber,
        );

        if (confirmations < confirmationsRequired) {
          if (deposit.confirmations !== confirmations) {
            await tx.onchainDeposit.update({
              where: { id: deposit.id },
              data: {
                confirmations,
              },
            });
          }
          return null;
        }

        if (
          deposit.status !== OnchainDepositStatus.detected ||
          deposit.creditedLedgerEntryId
        ) {
          if (deposit.confirmations !== confirmations) {
            await tx.onchainDeposit.update({
              where: { id: deposit.id },
              data: {
                confirmations,
              },
            });
          }
          return null;
        }

        const creditIdempotencyKey = createDeterministicIdempotencyKey(
          'deposit-credit',
          deposit.asset,
          deposit.txHash,
          deposit.logIndex,
        );

        let ledgerEntry = await tx.ledgerEntry.findUnique({
          where: { idempotencyKey: creditIdempotencyKey },
        });

        const userAccount = await tx.ledgerAccount.upsert({
          where: {
            userId_accountType_currency: {
              userId: deposit.wallet.userId,
              accountType: 'user',
              currency: deposit.asset,
            },
          },
          update: {
            walletId: deposit.wallet.id,
          },
          create: {
            userId: deposit.wallet.userId,
            walletId: deposit.wallet.id,
            accountType: 'user',
            currency: deposit.asset,
          },
        });

        let treasuryAccount = await tx.ledgerAccount.findFirst({
          where: {
            userId: null,
            accountType: 'treasury',
            currency: deposit.asset,
          },
        });

        if (!treasuryAccount) {
          treasuryAccount = await tx.ledgerAccount.create({
            data: {
              userId: null,
              accountType: 'treasury',
              currency: deposit.asset,
            },
          });
        }

        if (!ledgerEntry) {
          await tx.ledgerAccount.update({
            where: { id: userAccount.id },
            data: {
              available: userAccount.available.add(deposit.amount),
            },
          });

          await tx.ledgerAccount.update({
            where: { id: treasuryAccount.id },
            data: {
              available: treasuryAccount.available.sub(deposit.amount),
            },
          });

          ledgerEntry = await tx.ledgerEntry.create({
            data: {
              debitAccountId: treasuryAccount.id,
              creditAccountId: userAccount.id,
              amount: deposit.amount,
              reason: LedgerReason.deposit_credit,
              idempotencyKey: creditIdempotencyKey,
              metadata: {
                depositId: deposit.id,
                txHash: deposit.txHash,
                logIndex: deposit.logIndex,
                fromAddress: deposit.fromAddress,
                toAddress: deposit.toAddress,
                asset: deposit.asset,
                tokenAddress: deposit.tokenAddress,
              },
            },
          });
        }

        const updatedDeposit = await tx.onchainDeposit.update({
          where: { id: deposit.id },
          data: {
            status: OnchainDepositStatus.credited,
            creditedLedgerEntryId: ledgerEntry.id,
            confirmations,
            creditedAt: deposit.creditedAt ?? new Date(),
          },
        });

        return {
          deposit: updatedDeposit,
          ledgerEntry,
          userId: deposit.wallet.userId,
        };
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      },
    );

    if (!result) {
      return;
    }

    await this.auditLogService.create({
      actorId: result.userId,
      action: FinancialAuditActions.DepositCredited,
      resourceType: 'onchain_deposit',
      resourceId: result.deposit.id,
      metadata: {
        userId: result.userId,
        txHash: result.deposit.txHash,
        logIndex: result.deposit.logIndex,
        amount: result.deposit.amount.toString(),
        asset: result.deposit.asset,
        ledgerEntryId: result.ledgerEntry.id,
      },
    });
  }

  private normalizeAddress(value: unknown): string | null {
    if (typeof value !== 'string') {
      return null;
    }

    const trimmed = value.trim();
    if (!/^0x[a-fA-F0-9]{40}$/.test(trimmed)) {
      return null;
    }

    return trimmed.toLowerCase();
  }

  private toLogIndex(value: bigint | number | null): number | null {
    if (value === null) {
      return null;
    }

    if (typeof value === 'number') {
      return Number.isInteger(value) && value >= 0 ? value : null;
    }

    if (typeof value === 'bigint') {
      if (value < 0n || value > BigInt(Number.MAX_SAFE_INTEGER)) {
        return null;
      }
      return Number(value);
    }

    return null;
  }

  private computeConfirmations(
    headBlock: bigint,
    depositBlock: bigint,
  ): number {
    if (headBlock < depositBlock) {
      return 0;
    }

    const confirmations = headBlock - depositBlock + 1n;
    if (confirmations > BigInt(Number.MAX_SAFE_INTEGER)) {
      return Number.MAX_SAFE_INTEGER;
    }

    return Number(confirmations);
  }

  private minBigInt(left: bigint, right: bigint): bigint {
    return left < right ? left : right;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }

  private scanCursorKey(network: WalletDepositNetworkConfig) {
    return `${network.chainEnvironment}:${network.asset}`;
  }
}
