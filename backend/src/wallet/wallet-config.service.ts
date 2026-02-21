import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  ChainEnvironment,
  WalletAsset,
  WalletAssetKind,
} from '@prisma/client';

export type WalletDepositNetworkConfig = {
  asset: WalletAsset;
  assetKind: WalletAssetKind;
  chainEnvironment: ChainEnvironment;
  chainId: number;
  rpcUrl: string;
  wsRpcUrl: string | null;
  tokenAddress: `0x${string}` | null;
  confirmationsRequired: number;
  startBlock: bigint | null;
  decimals: number;
};

export type TurnkeyMode = 'auto' | 'mock' | 'real';

type WalletArtifactAddresses = {
  bscTestnet?: string | null;
  bscMainnet?: string | null;
};

@Injectable()
export class WalletConfigService {
  private readonly artifactAddresses: WalletArtifactAddresses;

  constructor(private readonly configService: ConfigService) {
    this.artifactAddresses = this.loadArtifactAddresses();
  }

  get walletEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_ENABLED') ?? false;
  }

  get walletDepositRealtimeEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_DEPOSIT_REALTIME_ENABLED') ?? true;
  }

  get turnkeyMode(): TurnkeyMode {
    const mode = this.configService.get<string>('TURNKEY_MODE');
    if (mode === 'auto' || mode === 'mock' || mode === 'real') {
      return mode;
    }
    return 'auto';
  }

  get turnkeyExecutionMode(): 'mock' | 'real' {
    if (this.turnkeyMode === 'mock') {
      return 'mock';
    }
    if (this.turnkeyMode === 'real') {
      return 'real';
    }

    const legacyMock = this.configService.get<string | boolean>('TURNKEY_DEV_MOCK');
    if (legacyMock === true || legacyMock === 'true') {
      return 'mock';
    }

    const nodeEnv = this.configService.get<string>('NODE_ENV') ?? 'development';
    return nodeEnv === 'production' ? 'real' : 'mock';
  }

  get depositsEnabled(): boolean {
    return this.configService.get<boolean>('DEPOSITS_ENABLED') ?? false;
  }

  get withdrawalsEnabled(): boolean {
    return this.configService.get<boolean>('WITHDRAWALS_ENABLED') ?? false;
  }

  get walletAssetBntEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_ASSET_BNT_ENABLED') ?? true;
  }

  get walletAssetBnbEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_ASSET_BNB_ENABLED') ?? true;
  }

  get walletAssetUsdtEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_ASSET_USDT_ENABLED') ?? true;
  }

  get walletWithdrawalAssetsRaw(): string {
    return this.configService.get<string>('WALLET_WITHDRAWAL_ASSETS') ?? 'BNT';
  }

  get supportedAssets(): WalletAsset[] {
    const assets: WalletAsset[] = [];
    if (this.walletAssetBntEnabled) assets.push(WalletAsset.BNT);
    if (this.walletAssetBnbEnabled) assets.push(WalletAsset.BNB);
    if (this.walletAssetUsdtEnabled) assets.push(WalletAsset.USDT);
    return assets;
  }

  get withdrawalEnabledAssets(): WalletAsset[] {
    const normalized = this.walletWithdrawalAssetsRaw
      .split(',')
      .map((value) => value.trim().toUpperCase())
      .filter(Boolean);
    const configured = normalized.filter((value): value is WalletAsset =>
      this.isWalletAsset(value),
    );
    if (configured.length === 0) {
      return [WalletAsset.BNT];
    }
    return configured.filter((asset) => this.isAssetEnabled(asset));
  }

  isAssetEnabled(asset: WalletAsset): boolean {
    switch (asset) {
      case WalletAsset.BNT:
        return this.walletAssetBntEnabled;
      case WalletAsset.BNB:
        return this.walletAssetBnbEnabled;
      case WalletAsset.USDT:
        return this.walletAssetUsdtEnabled;
      default:
        return false;
    }
  }

  isWithdrawalEnabledForAsset(asset: WalletAsset): boolean {
    return (
      this.withdrawalsEnabled &&
      this.isAssetEnabled(asset) &&
      this.withdrawalEnabledAssets.includes(asset)
    );
  }

  isTransferEnabledForAsset(asset: WalletAsset): boolean {
    return (
      this.isAssetEnabled(asset) &&
      this.withdrawalEnabledAssets.includes(asset)
    );
  }

  getAssetKind(asset: WalletAsset): WalletAssetKind {
    return asset === WalletAsset.BNB ? WalletAssetKind.native : WalletAssetKind.erc20;
  }

  getAssetDecimals(asset: WalletAsset): number {
    // BNT/BEP20-USDT/BNB are all 18 decimals on BSC in our implementation.
    if (asset === WalletAsset.USDT) return 18;
    if (asset === WalletAsset.BNB) return 18;
    return 18;
  }

  get bscTestnetChainId(): number {
    return this.getChainIdForEnvironment(ChainEnvironment.testnet);
  }

  get bscMainnetChainId(): number {
    return this.getChainIdForEnvironment(ChainEnvironment.mainnet);
  }

  get walletChainEnvironment(): ChainEnvironment {
    const configured = this.getTrimmedString('WALLET_CHAIN_ENVIRONMENT')?.toLowerCase();
    if (configured === ChainEnvironment.mainnet) {
      return ChainEnvironment.mainnet;
    }
    if (configured === ChainEnvironment.testnet) {
      return ChainEnvironment.testnet;
    }

    const nodeEnv = this.configService.get<string>('NODE_ENV') ?? 'development';
    return nodeEnv === 'production'
      ? ChainEnvironment.mainnet
      : ChainEnvironment.testnet;
  }

  get walletProvisionChainId(): number {
    return this.walletChainEnvironment === ChainEnvironment.mainnet
      ? this.bscMainnetChainId
      : this.bscTestnetChainId;
  }

  get bscRpcTestnet(): string | null {
    return this.getRpcUrlForEnvironment(ChainEnvironment.testnet);
  }

  get bscRpcMainnet(): string | null {
    return this.getRpcUrlForEnvironment(ChainEnvironment.mainnet);
  }

  get bscWsRpcTestnet(): string | null {
    return this.getWsRpcUrlForEnvironment(ChainEnvironment.testnet);
  }

  get bscWsRpcMainnet(): string | null {
    return this.getWsRpcUrlForEnvironment(ChainEnvironment.mainnet);
  }

  get bntTokenAddressTestnet(): `0x${string}` | null {
    return this.getBntTokenAddressForEnvironment(ChainEnvironment.testnet);
  }

  get bntTokenAddressMainnet(): `0x${string}` | null {
    return this.getBntTokenAddressForEnvironment(ChainEnvironment.mainnet);
  }

  get usdtTokenAddressTestnet(): `0x${string}` | null {
    return this.getUsdtTokenAddressForEnvironment(ChainEnvironment.testnet);
  }

  get usdtTokenAddressMainnet(): `0x${string}` | null {
    return this.getUsdtTokenAddressForEnvironment(ChainEnvironment.mainnet);
  }

  get treasuryWalletIdTestnet(): string | null {
    return this.getTreasuryWalletIdForConfiguredEnvironment(
      ChainEnvironment.testnet,
    );
  }

  get treasuryWalletIdMainnet(): string | null {
    return this.getTreasuryWalletIdForConfiguredEnvironment(
      ChainEnvironment.mainnet,
    );
  }

  get treasurySweepAddress(): `0x${string}` | null {
    return this.getAddress('TREASURY_ADDRESS');
  }

  get treasurySweepAddressTestnet(): `0x${string}` | null {
    return this.walletChainEnvironment === ChainEnvironment.testnet
      ? this.treasurySweepAddress
      : null;
  }

  get treasurySweepAddressMainnet(): `0x${string}` | null {
    return this.walletChainEnvironment === ChainEnvironment.mainnet
      ? this.treasurySweepAddress
      : null;
  }

  get depositIndexerEnabled(): boolean {
    return this.walletEnabled && this.depositsEnabled;
  }

  get depositPollIntervalMs(): number {
    return this.getNumber('WALLET_DEPOSIT_POLL_INTERVAL_MS', 15000, {
      min: 1000,
      max: 300000,
    });
  }

  get depositBlockChunkSize(): bigint {
    const value = this.getNumber('WALLET_DEPOSIT_BLOCK_CHUNK_SIZE', 1000, {
      min: 50,
      max: 5000,
    });
    return BigInt(value);
  }

  get depositAddressChunkSize(): number {
    return this.getNumber('WALLET_DEPOSIT_ADDRESS_CHUNK_SIZE', 100, {
      min: 10,
      max: 500,
    });
  }

  get depositMaxRangePerTick(): bigint {
    const value = this.getNumber('WALLET_DEPOSIT_MAX_RANGE_PER_TICK', 5000, {
      min: 100,
      max: 100000,
    });
    return BigInt(value);
  }

  get depositInitialLookbackBlocks(): bigint {
    const value = this.getNumber('WALLET_DEPOSIT_INITIAL_LOOKBACK_BLOCKS', 2000, {
      min: 100,
      max: 250000,
    });
    return BigInt(value);
  }

  get depositConfirmationsTestnet(): number {
    return this.getDepositConfirmationsForEnvironment(ChainEnvironment.testnet);
  }

  get depositConfirmationsMainnet(): number {
    return this.getDepositConfirmationsForEnvironment(ChainEnvironment.mainnet);
  }

  get withdrawalProcessorEnabled(): boolean {
    return this.walletEnabled && this.withdrawalsEnabled;
  }

  get withdrawalPollIntervalMs(): number {
    return this.getNumber('WALLET_WITHDRAWAL_POLL_INTERVAL_MS', 15000, {
      min: 1000,
      max: 300000,
    });
  }

  get withdrawalConfirmationsTestnet(): number {
    return this.getWithdrawalConfirmationsForConfiguredEnvironment(
      ChainEnvironment.testnet,
    );
  }

  get withdrawalConfirmationsMainnet(): number {
    return this.getWithdrawalConfirmationsForConfiguredEnvironment(
      ChainEnvironment.mainnet,
    );
  }

  get depositStartBlockTestnet(): bigint | null {
    return this.getDepositStartBlockForEnvironment(ChainEnvironment.testnet);
  }

  get depositStartBlockMainnet(): bigint | null {
    return this.getDepositStartBlockForEnvironment(ChainEnvironment.mainnet);
  }

  getDepositNetworkConfigs(): WalletDepositNetworkConfig[] {
    const networks: WalletDepositNetworkConfig[] = [];

    this.addNetworkConfigsForEnvironment(networks, this.walletChainEnvironment);

    return networks;
  }

  getDepositNetworkConfig(
    chainEnvironment: ChainEnvironment,
    asset: WalletAsset = WalletAsset.BNT,
  ): WalletDepositNetworkConfig | null {
    const config = this.getDepositNetworkConfigs().find(
      (network) =>
        network.chainEnvironment === chainEnvironment && network.asset === asset,
    );
    return config ?? null;
  }

  getTreasuryWalletIdForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): string | null {
    if (chainEnvironment === ChainEnvironment.mainnet) {
      return this.treasuryWalletIdMainnet;
    }
    return this.treasuryWalletIdTestnet;
  }

  getTreasurySweepAddressForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): `0x${string}` | null {
    if (chainEnvironment === ChainEnvironment.mainnet) {
      return this.treasurySweepAddressMainnet;
    }
    return this.treasurySweepAddressTestnet;
  }

  getWithdrawalConfirmationsForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): number {
    return chainEnvironment === ChainEnvironment.mainnet
      ? this.withdrawalConfirmationsMainnet
      : this.withdrawalConfirmationsTestnet;
  }

  private getChainIdForEnvironment(chainEnvironment: ChainEnvironment): number {
    const defaultForEnvironment =
      chainEnvironment === ChainEnvironment.mainnet ? 56 : 97;
    const single = this.getOptionalNumber('BSC_CHAIN_ID', { min: 1 });
    if (single === null) {
      return defaultForEnvironment;
    }
    return this.walletChainEnvironment === chainEnvironment
      ? single
      : defaultForEnvironment;
  }

  private getRpcUrlForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): string | null {
    const single = this.getTrimmedString('BSC_RPC_URL');
    if (!single) {
      return null;
    }
    return this.walletChainEnvironment === chainEnvironment ? single : null;
  }

  private getWsRpcUrlForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): string | null {
    const single = this.getTrimmedString('BSC_RPC_WS_URL');
    if (!single) {
      return null;
    }
    return this.walletChainEnvironment === chainEnvironment ? single : null;
  }

  private getBntTokenAddressForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): `0x${string}` | null {
    if (this.walletChainEnvironment !== chainEnvironment) {
      return null;
    }

    const single = this.getAddress('BNT_TOKEN_ADDRESS');
    if (single) {
      return single;
    }

    return chainEnvironment === ChainEnvironment.mainnet
      ? this.normalizeAddress(this.artifactAddresses.bscMainnet)
      : this.normalizeAddress(this.artifactAddresses.bscTestnet);
  }

  private getUsdtTokenAddressForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): `0x${string}` | null {
    if (this.walletChainEnvironment !== chainEnvironment) {
      return null;
    }
    return this.getAddress('USDT_TOKEN_ADDRESS');
  }

  private getTreasuryWalletIdForConfiguredEnvironment(
    chainEnvironment: ChainEnvironment,
  ): string | null {
    if (this.walletChainEnvironment !== chainEnvironment) {
      return null;
    }
    return this.getTrimmedString('TREASURY_WALLET_ID');
  }

  private getDepositConfirmationsForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): number {
    const defaultForEnvironment =
      chainEnvironment === ChainEnvironment.mainnet ? 20 : 12;
    const single = this.getOptionalNumber('WALLET_DEPOSIT_CONFIRMATIONS', {
      min: 1,
      max: 400,
    });
    if (single === null) {
      return defaultForEnvironment;
    }
    return this.walletChainEnvironment === chainEnvironment
      ? single
      : defaultForEnvironment;
  }

  private getWithdrawalConfirmationsForConfiguredEnvironment(
    chainEnvironment: ChainEnvironment,
  ): number {
    const defaultForEnvironment =
      chainEnvironment === ChainEnvironment.mainnet ? 20 : 12;
    const single = this.getOptionalNumber('WALLET_WITHDRAWAL_CONFIRMATIONS', {
      min: 1,
      max: 400,
    });
    if (single === null) {
      return defaultForEnvironment;
    }
    return this.walletChainEnvironment === chainEnvironment
      ? single
      : defaultForEnvironment;
  }

  private getDepositStartBlockForEnvironment(
    chainEnvironment: ChainEnvironment,
  ): bigint | null {
    if (this.walletChainEnvironment !== chainEnvironment) {
      return null;
    }
    return this.getOptionalBigInt('WALLET_DEPOSIT_START_BLOCK');
  }

  private getAddress(key: string): `0x${string}` | null {
    return this.normalizeAddress(this.getTrimmedString(key));
  }

  private addNetworkConfigsForEnvironment(
    target: WalletDepositNetworkConfig[],
    chainEnvironment: ChainEnvironment,
  ) {
    const isMainnet = chainEnvironment === ChainEnvironment.mainnet;
    const chainId = isMainnet ? this.bscMainnetChainId : this.bscTestnetChainId;
    const rpcUrl = isMainnet ? this.bscRpcMainnet : this.bscRpcTestnet;
    const wsRpcUrl = isMainnet ? this.bscWsRpcMainnet : this.bscWsRpcTestnet;
    const confirmationsRequired = isMainnet
      ? this.depositConfirmationsMainnet
      : this.depositConfirmationsTestnet;
    const startBlock = isMainnet
      ? this.depositStartBlockMainnet
      : this.depositStartBlockTestnet;

    if (!rpcUrl) return;

    if (this.walletAssetBntEnabled) {
      const tokenAddress = isMainnet
        ? this.bntTokenAddressMainnet
        : this.bntTokenAddressTestnet;
      if (tokenAddress) {
        target.push({
          asset: WalletAsset.BNT,
          assetKind: WalletAssetKind.erc20,
          chainEnvironment,
          chainId,
          rpcUrl,
          wsRpcUrl,
          tokenAddress,
          confirmationsRequired,
          startBlock,
          decimals: this.getAssetDecimals(WalletAsset.BNT),
        });
      }
    }

    if (this.walletAssetUsdtEnabled) {
      const tokenAddress = isMainnet
        ? this.usdtTokenAddressMainnet
        : this.usdtTokenAddressTestnet;
      if (tokenAddress) {
        target.push({
          asset: WalletAsset.USDT,
          assetKind: WalletAssetKind.erc20,
          chainEnvironment,
          chainId,
          rpcUrl,
          wsRpcUrl,
          tokenAddress,
          confirmationsRequired,
          startBlock,
          decimals: this.getAssetDecimals(WalletAsset.USDT),
        });
      }
    }

    if (this.walletAssetBnbEnabled) {
      target.push({
        asset: WalletAsset.BNB,
        assetKind: WalletAssetKind.native,
        chainEnvironment,
        chainId,
        rpcUrl,
        wsRpcUrl,
        tokenAddress: null,
        confirmationsRequired,
        startBlock,
        decimals: this.getAssetDecimals(WalletAsset.BNB),
      });
    }
  }

  private isWalletAsset(value: string): value is WalletAsset {
    return (
      value === WalletAsset.BNT ||
      value === WalletAsset.BNB ||
      value === WalletAsset.USDT
    );
  }

  private getTrimmedString(key: string): string | null {
    const value = this.configService.get<string>(key);
    if (!value) {
      return null;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : null;
  }

  private getNumber(
    key: string,
    fallback: number,
    bounds?: { min?: number; max?: number },
  ): number {
    const raw = this.configService.get<string | number>(key);
    const parsed =
      typeof raw === 'number'
        ? raw
        : raw === undefined
          ? Number.NaN
          : Number(raw);

    if (!Number.isFinite(parsed)) {
      return fallback;
    }

    let value = Math.floor(parsed);
    if (bounds?.min !== undefined && value < bounds.min) {
      value = bounds.min;
    }
    if (bounds?.max !== undefined && value > bounds.max) {
      value = bounds.max;
    }
    return value;
  }

  private getOptionalBigInt(key: string): bigint | null {
    const value = this.getTrimmedString(key);
    if (!value) {
      return null;
    }

    if (!/^\d+$/.test(value)) {
      return null;
    }

    return BigInt(value);
  }

  private getOptionalNumber(
    key: string,
    bounds?: { min?: number; max?: number },
  ): number | null {
    const raw = this.configService.get<string | number>(key);
    if (raw === undefined || raw === null) {
      return null;
    }

    const parsed =
      typeof raw === 'number'
        ? raw
        : raw.trim().length > 0
          ? Number(raw)
          : Number.NaN;

    if (!Number.isFinite(parsed)) {
      return null;
    }

    let value = Math.floor(parsed);
    if (bounds?.min !== undefined && value < bounds.min) {
      value = bounds.min;
    }
    if (bounds?.max !== undefined && value > bounds.max) {
      value = bounds.max;
    }
    return value;
  }

  private normalizeAddress(value: string | null | undefined): `0x${string}` | null {
    if (!value) {
      return null;
    }

    const trimmed = value.trim();
    if (!/^0x[a-fA-F0-9]{40}$/.test(trimmed)) {
      return null;
    }

    return trimmed as `0x${string}`;
  }

  private loadArtifactAddresses(): WalletArtifactAddresses {
    const possiblePaths = [
      join(process.cwd(), 'src/wallet/artifacts/bnt.addresses.json'),
      join(process.cwd(), 'backend/src/wallet/artifacts/bnt.addresses.json'),
    ];

    for (const filePath of possiblePaths) {
      if (!existsSync(filePath)) {
        continue;
      }

      try {
        const parsed = JSON.parse(readFileSync(filePath, 'utf8')) as WalletArtifactAddresses;
        return parsed ?? {};
      } catch {
        return {};
      }
    }

    return {};
  }
}
