import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import {
  ChainEnvironment,
  OnchainDepositStatus,
  WalletAsset,
  WalletStatus,
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
import { DatabaseHealthService } from '../prisma/database-health.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  WalletConfigService,
  type WalletDepositNetworkConfig,
} from './wallet-config.service';
import { WalletDepositProcessorService } from './wallet-deposit-processor.service';

const TRANSFER_EVENT = parseAbiItem(
  'event Transfer(address indexed from, address indexed to, uint256 value)',
);
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const TX_HASH_PATTERN = /^0x[a-fA-F0-9]{64}$/;
type WalletAddressRecord = {
  walletId: string;
  userId: string;
  address: string;
};
type WalletAddressMap = Map<string, WalletAddressRecord>;

type ManualReprocessNetworkResult = {
  asset: WalletAsset;
  detectedCount: number;
  creditedCount: number;
  depositIds: string[];
  matched: boolean;
  reason?: string;
};

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
  private readonly walletAddressCacheUpdatedAt = new Map<
    ChainEnvironment,
    number
  >();

  private intervalHandle: NodeJS.Timeout | null = null;
  private isTickRunning = false;
  private lastDbUnavailableLogAt = 0;

  constructor(
    private readonly prisma: PrismaService,
    private readonly walletConfigService: WalletConfigService,
    private readonly databaseHealthService: DatabaseHealthService,
    private readonly auditLogService: AuditLogService,
    private readonly depositProcessor: WalletDepositProcessorService,
  ) {}

  async reprocessTransactionByHash(input: {
    txHash: string;
    chainEnvironment?: ChainEnvironment;
    asset?: WalletAsset;
  }) {
    const txHash = this.normalizeTxHash(input.txHash);
    if (!txHash) {
      throw new BadRequestException(
        'txHash must be a valid EVM transaction hash',
      );
    }

    const configuredEnvironment =
      this.walletConfigService.walletChainEnvironment;
    const requestedEnvironment =
      input.chainEnvironment ?? configuredEnvironment;

    if (requestedEnvironment !== configuredEnvironment) {
      throw new BadRequestException(
        `Requested chainEnvironment ${requestedEnvironment} does not match configured wallet environment ${configuredEnvironment}`,
      );
    }

    const networks = this.walletConfigService
      .getDepositNetworkConfigs()
      .filter((network) => network.chainEnvironment === requestedEnvironment)
      .filter((network) =>
        input.asset ? network.asset === input.asset : true,
      );

    if (networks.length === 0) {
      const assetLabel = input.asset ? ` for asset ${input.asset}` : '';
      throw new BadRequestException(
        `No deposit network configuration found for ${requestedEnvironment}${assetLabel}`,
      );
    }

    const client = this.getHttpClient(networks[0]);
    let receipt: Awaited<ReturnType<PublicClient['getTransactionReceipt']>>;
    try {
      receipt = await client.getTransactionReceipt({ hash: txHash });
    } catch {
      throw new NotFoundException(
        `Transaction ${txHash} was not found on ${requestedEnvironment}`,
      );
    }

    if (receipt.blockNumber === null) {
      throw new BadRequestException(
        `Transaction ${txHash} is not mined yet on ${requestedEnvironment}`,
      );
    }

    const [currentBlock, walletByAddress] = await Promise.all([
      client.getBlockNumber(),
      this.getWalletAddressMap(requestedEnvironment),
    ]);

    const requiresNative = networks.some(
      (network) => network.assetKind === WalletAssetKind.native,
    );
    const tx = requiresNative
      ? await client.getTransaction({ hash: txHash }).catch(() => null)
      : null;

    const networkResults: ManualReprocessNetworkResult[] = [];
    for (const network of networks) {
      if (network.assetKind === WalletAssetKind.native) {
        const result = await this.reprocessNativeForNetwork({
          network,
          txHash,
          tx,
          receipt,
          currentBlock,
          walletByAddress,
        });
        networkResults.push(result);
        continue;
      }

      const result = await this.reprocessTokenForNetwork({
        network,
        txHash,
        receipt,
        currentBlock,
        walletByAddress,
        client,
      });
      networkResults.push(result);
    }

    return {
      txHash,
      chainEnvironment: requestedEnvironment,
      txBlockNumber: receipt.blockNumber.toString(),
      headBlockNumber: currentBlock.toString(),
      networkResults,
      summary: {
        matchedAssets: networkResults.filter((item) => item.matched).length,
        detectedDeposits: networkResults.reduce(
          (sum, item) => sum + item.detectedCount,
          0,
        ),
        creditedDeposits: networkResults.reduce(
          (sum, item) => sum + item.creditedCount,
          0,
        ),
      },
    };
  }

  onModuleInit(): void {
    const intervalMs = this.walletConfigService.depositPollIntervalMs;
    this.intervalHandle = setInterval(() => {
      void this.tick();
    }, intervalMs);

    void this.tick();
    this.logger.log(`Deposit indexer started (interval=${intervalMs}ms)`);
  }

  onModuleDestroy(): void {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
    this.stopRealtimeSubscriptions();
  }

  private async tick(): Promise<void> {
    if (this.isTickRunning) {
      return;
    }

    this.isTickRunning = true;
    try {
      if (!this.walletConfigService.depositIndexerEnabled) {
        this.stopRealtimeSubscriptions();
        return;
      }

      const databaseHealthy = await this.databaseHealthService.isDatabaseHealthy();
      if (!databaseHealthy) {
        this.stopRealtimeSubscriptions();
        this.logDbUnavailableSkip();
        return;
      }

      const networks = this.walletConfigService.getDepositNetworkConfigs();
      if (networks.length === 0) {
        this.stopRealtimeSubscriptions();
        return;
      }

      this.initializeRealtimeSubscriptions(networks);
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
    const walletByAddress = await this.getWalletAddressMap(
      network.chainEnvironment,
    );

    if (
      walletByAddress.size > 0 &&
      !this.isRealtimeStreamingEnabledForNetwork(network)
    ) {
      await this.scanNewTransfers(
        network,
        client,
        walletByAddress,
        currentBlock,
      );
    }

    await this.finalizeDetectedDeposits(network, currentBlock);
  }

  private async reprocessTokenForNetwork(input: {
    network: WalletDepositNetworkConfig;
    txHash: `0x${string}`;
    receipt: Awaited<ReturnType<PublicClient['getTransactionReceipt']>>;
    currentBlock: bigint;
    walletByAddress: WalletAddressMap;
    client: PublicClient;
  }): Promise<ManualReprocessNetworkResult> {
    const { network, txHash, receipt, currentBlock, walletByAddress, client } =
      input;

    if (!network.tokenAddress) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: `Token address is not configured for ${network.asset}`,
      };
    }

    if (walletByAddress.size === 0) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: `No wallet addresses are currently tracked for ${network.chainEnvironment}`,
      };
    }

    if (receipt.status !== 'success') {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Transaction status is not successful',
      };
    }

    const blockNumber = receipt.blockNumber;
    const logs = await client.getLogs({
      address: network.tokenAddress,
      event: TRANSFER_EVENT,
      fromBlock: blockNumber,
      toBlock: blockNumber,
    });

    const txLogs = logs.filter(
      (log) =>
        log.transactionHash &&
        log.transactionHash.toLowerCase() === txHash.toLowerCase(),
    );

    if (txLogs.length === 0) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: `No ${network.asset} transfer logs found for this transaction`,
      };
    }

    let detectedCount = 0;
    let creditedCount = 0;
    const depositIds: string[] = [];

    for (const log of txLogs) {
      const toAddress = this.normalizeAddress(log.args.to);
      if (!toAddress) continue;

      const wallet = walletByAddress.get(toAddress);
      if (!wallet) continue;

      const amountRaw = log.args.value;
      if (typeof amountRaw !== 'bigint' || amountRaw <= 0n) continue;

      const logIndex = this.toLogIndex(log.logIndex);
      if (logIndex === null) continue;

      const fromAddress = this.normalizeAddress(log.args.from) ?? ZERO_ADDRESS;
      const confirmations = this.computeConfirmations(
        currentBlock,
        blockNumber,
      );

      const deposit = await this.depositProcessor.recordDetectedDeposit({
        walletId: wallet.walletId,
        userId: wallet.userId,
        toAddress: wallet.address,
        fromAddress,
        txHash,
        logIndex,
        blockNumber,
        amount: formatUnits(amountRaw, network.decimals),
        confirmations,
        chainEnvironment: network.chainEnvironment,
        asset: network.asset,
        assetKind: network.assetKind,
        tokenAddress: network.tokenAddress,
      });
      detectedCount += 1;
      depositIds.push(deposit.id);

      if (confirmations >= network.confirmationsRequired) {
        await this.depositProcessor.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }

      const persisted = await this.prisma.onchainDeposit.findUnique({
        where: { id: deposit.id },
        select: {
          creditedLedgerEntryId: true,
          status: true,
        },
      });
      if (
        persisted?.creditedLedgerEntryId ||
        persisted?.status === OnchainDepositStatus.credited ||
        persisted?.status === OnchainDepositStatus.swept
      ) {
        creditedCount += 1;
      }
    }

    if (detectedCount === 0) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: `Transaction has ${network.asset} transfer logs but none target a tracked wallet`,
      };
    }

    return {
      asset: network.asset,
      detectedCount,
      creditedCount,
      depositIds,
      matched: true,
    };
  }

  private async reprocessNativeForNetwork(input: {
    network: WalletDepositNetworkConfig;
    txHash: `0x${string}`;
    tx: Awaited<ReturnType<PublicClient['getTransaction']>> | null;
    receipt: Awaited<ReturnType<PublicClient['getTransactionReceipt']>>;
    currentBlock: bigint;
    walletByAddress: WalletAddressMap;
  }): Promise<ManualReprocessNetworkResult> {
    const { network, txHash, tx, receipt, currentBlock, walletByAddress } =
      input;

    if (walletByAddress.size === 0) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: `No wallet addresses are currently tracked for ${network.chainEnvironment}`,
      };
    }

    if (!tx) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Could not load transaction payload from RPC',
      };
    }

    if (receipt.status !== 'success') {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Transaction status is not successful',
      };
    }

    const toAddress = this.normalizeAddress(tx.to);
    if (!toAddress) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Transaction does not contain a valid destination address',
      };
    }

    const wallet = walletByAddress.get(toAddress);
    if (!wallet) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Destination address is not mapped to an app wallet',
      };
    }

    if (typeof tx.value !== 'bigint' || tx.value <= 0n) {
      return {
        asset: network.asset,
        detectedCount: 0,
        creditedCount: 0,
        depositIds: [],
        matched: false,
        reason: 'Native transfer amount is zero',
      };
    }

    const txIndex =
      this.toLogIndex(
        receipt.transactionIndex ?? tx.transactionIndex ?? null,
      ) ?? 0;
    const fromAddress = this.normalizeAddress(tx.from) ?? ZERO_ADDRESS;
    const blockNumber = receipt.blockNumber;
    const confirmations = this.computeConfirmations(currentBlock, blockNumber);

    const deposit = await this.depositProcessor.recordDetectedDeposit({
      walletId: wallet.walletId,
      userId: wallet.userId,
      toAddress: wallet.address,
      fromAddress,
      txHash,
      logIndex: txIndex,
      blockNumber,
      amount: formatUnits(tx.value, network.decimals),
      confirmations,
      chainEnvironment: network.chainEnvironment,
      asset: network.asset,
      assetKind: network.assetKind,
      tokenAddress: null,
    });

    if (confirmations >= network.confirmationsRequired) {
      await this.depositProcessor.creditDetectedDeposit(
        deposit.id,
        network.confirmationsRequired,
        currentBlock,
      );
    }

    const persisted = await this.prisma.onchainDeposit.findUnique({
      where: { id: deposit.id },
      select: {
        creditedLedgerEntryId: true,
        status: true,
      },
    });
    const credited =
      Boolean(persisted?.creditedLedgerEntryId) ||
      persisted?.status === OnchainDepositStatus.credited ||
      persisted?.status === OnchainDepositStatus.swept;

    return {
      asset: network.asset,
      detectedCount: 1,
      creditedCount: credited ? 1 : 0,
      depositIds: [deposit.id],
      matched: true,
    };
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
    const updatedAt =
      this.walletAddressCacheUpdatedAt.get(chainEnvironment) ?? 0;
    if (cached && now - updatedAt < staleAfterMs) {
      return cached;
    }

    const wallets = await this.prisma.userWallet.findMany({
      where: {
        chainEnvironment,
        address: { not: null },
        status: { not: WalletStatus.disabled },
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

  private stopRealtimeSubscriptions() {
    for (const [
      networkKey,
      unwatch,
    ] of this.realtimeUnwatchByNetwork.entries()) {
      try {
        unwatch();
      } catch {
        this.logger.warn(
          `Failed to stop realtime deposit stream for ${networkKey}`,
        );
      }
    }
    this.realtimeUnwatchByNetwork.clear();
    this.realtimeNetworkKeys.clear();
    this.realtimeQueues.clear();
    this.realtimeClients.clear();
  }

  private teardownRealtimeStream(
    networkKey: string,
    chainEnvironment: ChainEnvironment,
  ) {
    const unwatch = this.realtimeUnwatchByNetwork.get(networkKey);
    if (unwatch) {
      try {
        unwatch();
      } catch {
        this.logger.warn(
          `Failed to teardown realtime deposit stream for ${networkKey}`,
        );
      }
      this.realtimeUnwatchByNetwork.delete(networkKey);
    }

    this.realtimeNetworkKeys.delete(networkKey);
    this.realtimeQueues.delete(networkKey);
    this.realtimeClients.delete(chainEnvironment);
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
              this.handleRealtimeNativeBlock(network, block),
            );
          },
          onError: (error) => {
            this.logger.error(
              `Realtime native stream error for ${networkKey}: ${this.errorMessage(
                error,
              )}`,
            );
            this.teardownRealtimeStream(networkKey, network.chainEnvironment);
          },
        });

        this.realtimeUnwatchByNetwork.set(networkKey, unwatch);
        this.logger.log(
          `Realtime native deposit stream enabled for ${networkKey}`,
        );
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
          this.teardownRealtimeStream(networkKey, network.chainEnvironment);
        },
      });
      this.realtimeUnwatchByNetwork.set(networkKey, unwatch);
      this.logger.log(
        `Realtime token deposit stream enabled for ${networkKey}`,
      );
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

    const walletByAddress = await this.getWalletAddressMap(
      network.chainEnvironment,
    );
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

      const confirmations = this.computeConfirmations(
        currentBlock,
        blockNumber,
      );
      const fromAddress = this.normalizeAddress(log.args?.from) ?? ZERO_ADDRESS;

      const deposit = await this.depositProcessor.recordDetectedDeposit({
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
        await this.depositProcessor.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }
    }
  }

  private async handleRealtimeNativeBlock(
    network: WalletDepositNetworkConfig,
    block: unknown,
  ): Promise<void> {
    const parsedBlock = this.parseRealtimeNativeBlock(block);
    if (!parsedBlock) {
      return;
    }

    const walletByAddress = await this.getWalletAddressMap(
      network.chainEnvironment,
    );
    if (walletByAddress.size === 0) {
      return;
    }

    const currentBlock = await this.getHttpClient(network).getBlockNumber();
    for (const rawTx of parsedBlock.transactions) {
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
      const confirmations = this.computeConfirmations(
        currentBlock,
        parsedBlock.number,
      );

      const deposit = await this.depositProcessor.recordDetectedDeposit({
        walletId: wallet.walletId,
        userId: wallet.userId,
        toAddress: wallet.address,
        fromAddress,
        txHash,
        logIndex: txIndex,
        blockNumber: parsedBlock.number,
        amount: formatUnits(value, network.decimals),
        confirmations,
        chainEnvironment: network.chainEnvironment,
        asset: network.asset,
        assetKind: network.assetKind,
        tokenAddress: null,
      });

      if (confirmations >= network.confirmationsRequired) {
        await this.depositProcessor.creditDetectedDeposit(
          deposit.id,
          network.confirmationsRequired,
          currentBlock,
        );
      }
    }
  }

  private parseRealtimeNativeBlock(
    block: unknown,
  ): { number: bigint; transactions: unknown[] } | null {
    if (!block || typeof block !== 'object') {
      return null;
    }

    const candidate = block as {
      number?: bigint | null;
      transactions?: unknown;
    };

    if (typeof candidate.number !== 'bigint') {
      return null;
    }

    if (!Array.isArray(candidate.transactions)) {
      this.logger.warn(
        'Realtime native block payload missing transactions array; skipping block',
      );
      return null;
    }

    return {
      number: candidate.number,
      transactions: candidate.transactions,
    };
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

      const deposit = await this.depositProcessor.recordDetectedDeposit({
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
        await this.depositProcessor.creditDetectedDeposit(
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

        const deposit = await this.depositProcessor.recordDetectedDeposit({
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
          await this.depositProcessor.creditDetectedDeposit(
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
      await this.depositProcessor.creditDetectedDeposit(
        candidate.id,
        network.confirmationsRequired,
        currentBlock,
      );
    }
  }

  private normalizeTxHash(value: string): `0x${string}` | null {
    const normalized = value.trim().toLowerCase();
    if (!TX_HASH_PATTERN.test(normalized)) {
      return null;
    }
    return normalized as `0x${string}`;
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

  private logDbUnavailableSkip() {
    const now = Date.now();
    if (now - this.lastDbUnavailableLogAt < 60_000) {
      return;
    }
    this.lastDbUnavailableLogAt = now;
    this.logger.warn(
      'Skipping deposit indexer tick because database is unavailable.',
    );
  }

  private scanCursorKey(network: WalletDepositNetworkConfig) {
    return `${network.chainEnvironment}:${network.asset}`;
  }
}
