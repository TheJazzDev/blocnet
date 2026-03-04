import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'crypto';
import { ApiKeyStamper } from '@turnkey/api-key-stamper';
import {
  TurnkeyActivityError,
  TurnkeyClient,
  TurnkeyRequestError,
  createActivityPoller,
} from '@turnkey/http';
import {
  createPublicClient,
  encodeFunctionData,
  http,
  serializeTransaction,
  type PublicClient,
} from 'viem';
import {
  CreateCustodyWalletInput,
  CustodyTransferRecord,
  CustodyAdapter,
  CustodyWalletRecord,
  TransferCustodyNativeInput,
  TransferCustodyTokenInput,
} from './custody.adapter';
import { WalletConfigService } from '../wallet-config.service';

const DEFAULT_ETH_WALLET_PATH = "m/44'/60'/0'/0/0";
const WALLET_ADDRESS_CACHE_TTL_MS = 5 * 60 * 1000;
const DEFAULT_ERC20_TRANSFER_GAS_LIMIT = 120_000n;

const ERC20_TRANSFER_ABI = [
  {
    type: 'function',
    name: 'transfer',
    stateMutability: 'nonpayable',
    inputs: [
      {
        name: 'to',
        type: 'address',
      },
      {
        name: 'amount',
        type: 'uint256',
      },
    ],
    outputs: [
      {
        name: '',
        type: 'bool',
      },
    ],
  },
] as const;

@Injectable()
export class TurnkeyCustodyAdapter implements CustodyAdapter {
  private turnkeyClient: TurnkeyClient | null = null;
  private readonly chainClientById = new Map<number, PublicClient>();
  private readonly walletAddressCache = new Map<
    string,
    { address: `0x${string}`; expiresAt: number }
  >();

  constructor(
    private readonly configService: ConfigService,
    private readonly walletConfigService: WalletConfigService,
  ) {}

  private createMockWallet(
    input: CreateCustodyWalletInput,
  ): CustodyWalletRecord {
    const hash = createHash('sha256')
      .update(`${input.userId}:${input.idempotencyKey}`)
      .digest('hex');

    return {
      providerWalletId: `mock_${hash.slice(0, 24)}`,
      address: `0x${hash.slice(0, 40)}`,
    };
  }

  async createWallet(
    input: CreateCustodyWalletInput,
  ): Promise<CustodyWalletRecord> {
    if (this.walletConfigService.turnkeyExecutionMode === 'mock') {
      return this.createMockWallet(input);
    }

    const walletName = this.createWalletName(input.userId);

    try {
      const organizationId = this.requireTurnkeyOrganizationId();
      const client = this.getTurnkeyClient();

      const existingWallet = await this.findExistingWalletByName(walletName);
      if (existingWallet) {
        return existingWallet;
      }

      const pollCreateWallet = createActivityPoller({
        client,
        requestFn: client.createWallet,
      });

      const activity = await pollCreateWallet({
        type: 'ACTIVITY_TYPE_CREATE_WALLET',
        timestampMs: Date.now().toString(),
        organizationId,
        parameters: {
          walletName,
          accounts: [
            {
              curve: 'CURVE_SECP256K1',
              pathFormat: 'PATH_FORMAT_BIP32',
              path: DEFAULT_ETH_WALLET_PATH,
              addressFormat: 'ADDRESS_FORMAT_ETHEREUM',
            },
          ],
        },
      });

      const providerWalletId = activity.result.createWalletResult?.walletId;
      if (!providerWalletId) {
        throw new Error('Turnkey wallet activity completed without wallet ID');
      }

      const activityAddress =
        activity.result.createWalletResult?.addresses?.[0];
      const address =
        this.normalizeEvmAddress(activityAddress) ??
        (await this.resolveWalletAddress(providerWalletId));

      this.walletAddressCache.set(providerWalletId, {
        address,
        expiresAt: Date.now() + WALLET_ADDRESS_CACHE_TTL_MS,
      });

      return {
        providerWalletId,
        address,
      };
    } catch (error) {
      if (this.isWalletLabelAlreadyExistsError(error)) {
        const recovered = await this.retryFindExistingWalletByName(walletName);
        if (recovered) {
          return recovered;
        }
      }

      throw this.wrapTurnkeyError(
        error,
        `Turnkey wallet provisioning failed for userId=${input.userId}`,
      );
    }
  }

  async transferToken(
    input: TransferCustodyTokenInput,
  ): Promise<CustodyTransferRecord> {
    if (this.walletConfigService.turnkeyExecutionMode === 'mock') {
      const hash = createHash('sha256')
        .update(
          [
            input.idempotencyKey,
            input.chainId,
            input.tokenAddress,
            input.fromProviderWalletId,
            input.toAddress,
            input.amountWei,
          ].join('|'),
        )
        .digest('hex');

      return {
        txHash: `0x${hash}`,
        simulated: true,
      };
    }

    try {
      const organizationId = this.requireTurnkeyOrganizationId();
      const client = this.getTurnkeyClient();
      const chainClient = this.getChainClient(input.chainId);

      const fromAddress = await this.resolveWalletAddress(
        input.fromProviderWalletId,
      );
      const amountWei = BigInt(input.amountWei);
      const transferCallData = encodeFunctionData({
        abi: ERC20_TRANSFER_ABI,
        functionName: 'transfer',
        args: [input.toAddress, amountWei],
      });

      const [nonce, gasPrice] = await Promise.all([
        chainClient.getTransactionCount({
          address: fromAddress,
          blockTag: 'pending',
        }),
        chainClient.getGasPrice(),
      ]);

      let gasLimit: bigint;
      try {
        const estimatedGas = await chainClient.estimateGas({
          account: fromAddress,
          to: input.tokenAddress,
          data: transferCallData,
          value: 0n,
        });
        gasLimit = (estimatedGas * 120n) / 100n;
      } catch {
        gasLimit = DEFAULT_ERC20_TRANSFER_GAS_LIMIT;
      }

      const unsignedTransaction = serializeTransaction({
        chainId: input.chainId,
        nonce,
        gasPrice,
        gas: gasLimit,
        to: input.tokenAddress,
        value: 0n,
        data: transferCallData,
      });

      const pollSignTransaction = createActivityPoller({
        client,
        requestFn: client.signTransaction,
      });

      const activity = await pollSignTransaction({
        type: 'ACTIVITY_TYPE_SIGN_TRANSACTION_V2',
        timestampMs: Date.now().toString(),
        organizationId,
        parameters: {
          signWith: fromAddress,
          unsignedTransaction,
          type: 'TRANSACTION_TYPE_ETHEREUM',
        },
      });

      const signedTransaction =
        activity.result.signTransactionResult?.signedTransaction;
      if (!signedTransaction) {
        throw new Error('Turnkey signing activity completed without signed tx');
      }

      const txHash = await chainClient.sendRawTransaction({
        serializedTransaction: signedTransaction as `0x${string}`,
      });

      return {
        txHash,
        simulated: false,
      };
    } catch (error) {
      throw this.wrapTurnkeyError(
        error,
        `Turnkey token transfer failed fromWalletId=${input.fromProviderWalletId}`,
      );
    }
  }

  async transferNative(
    input: TransferCustodyNativeInput,
  ): Promise<CustodyTransferRecord> {
    if (this.walletConfigService.turnkeyExecutionMode === 'mock') {
      const hash = createHash('sha256')
        .update(
          [
            input.idempotencyKey,
            input.chainId,
            input.fromProviderWalletId,
            input.toAddress,
            input.amountWei,
          ].join('|'),
        )
        .digest('hex');

      return {
        txHash: `0x${hash}`,
        simulated: true,
      };
    }

    try {
      const organizationId = this.requireTurnkeyOrganizationId();
      const client = this.getTurnkeyClient();
      const chainClient = this.getChainClient(input.chainId);

      const fromAddress = await this.resolveWalletAddress(
        input.fromProviderWalletId,
      );
      const amountWei = BigInt(input.amountWei);

      const [nonce, gasPrice] = await Promise.all([
        chainClient.getTransactionCount({
          address: fromAddress,
          blockTag: 'pending',
        }),
        chainClient.getGasPrice(),
      ]);

      let gasLimit: bigint;
      try {
        const estimatedGas = await chainClient.estimateGas({
          account: fromAddress,
          to: input.toAddress,
          value: amountWei,
        });
        gasLimit = (estimatedGas * 120n) / 100n;
      } catch {
        gasLimit = 21_000n;
      }

      const unsignedTransaction = serializeTransaction({
        chainId: input.chainId,
        nonce,
        gasPrice,
        gas: gasLimit,
        to: input.toAddress,
        value: amountWei,
      });

      const pollSignTransaction = createActivityPoller({
        client,
        requestFn: client.signTransaction,
      });

      const activity = await pollSignTransaction({
        type: 'ACTIVITY_TYPE_SIGN_TRANSACTION_V2',
        timestampMs: Date.now().toString(),
        organizationId,
        parameters: {
          signWith: fromAddress,
          unsignedTransaction,
          type: 'TRANSACTION_TYPE_ETHEREUM',
        },
      });

      const signedTransaction =
        activity.result.signTransactionResult?.signedTransaction;
      if (!signedTransaction) {
        throw new Error('Turnkey signing activity completed without signed tx');
      }

      const txHash = await chainClient.sendRawTransaction({
        serializedTransaction: signedTransaction as `0x${string}`,
      });

      return {
        txHash,
        simulated: false,
      };
    } catch (error) {
      throw this.wrapTurnkeyError(
        error,
        `Turnkey native transfer failed fromWalletId=${input.fromProviderWalletId}`,
      );
    }
  }

  async getHealth() {
    const mode = this.walletConfigService.turnkeyExecutionMode;
    const configured = {
      organizationId: Boolean(
        this.getOptionalConfigValue('TURNKEY_ORGANIZATION_ID'),
      ),
      apiPublicKey: Boolean(
        this.getOptionalConfigValue('TURNKEY_API_PUBLIC_KEY'),
      ),
      apiPrivateKey: Boolean(
        this.getOptionalConfigValue('TURNKEY_API_PRIVATE_KEY'),
      ),
      apiKeyId: Boolean(this.getOptionalConfigValue('TURNKEY_API_KEY_ID')),
    };

    if (mode === 'mock') {
      return {
        provider: 'turnkey',
        mode,
        configured,
        connectivity: {
          ok: true,
          simulated: true,
          error: null,
        },
      };
    }

    if (
      !configured.organizationId ||
      !configured.apiPublicKey ||
      !configured.apiPrivateKey ||
      !configured.apiKeyId
    ) {
      return {
        provider: 'turnkey',
        mode,
        configured,
        connectivity: {
          ok: false,
          simulated: false,
          error: 'Required Turnkey credentials are missing',
        },
      };
    }

    try {
      const organizationId = this.requireTurnkeyOrganizationId();
      const client = this.getTurnkeyClient();
      const whoami = await client.getWhoami({
        organizationId,
      });

      return {
        provider: 'turnkey',
        mode,
        configured,
        connectivity: {
          ok: true,
          simulated: false,
          organizationId: whoami.organizationId,
          organizationName: whoami.organizationName,
          userId: whoami.userId,
          username: whoami.username,
          error: null,
        },
      };
    } catch (error) {
      return {
        provider: 'turnkey',
        mode,
        configured,
        connectivity: {
          ok: false,
          simulated: false,
          error: this.wrapTurnkeyError(error, 'Turnkey health check failed')
            .message,
        },
      };
    }
  }

  private requireTurnkeyOrganizationId(): string {
    return this.requireConfigValue('TURNKEY_ORGANIZATION_ID');
  }

  private getTurnkeyClient(): TurnkeyClient {
    if (this.turnkeyClient) {
      return this.turnkeyClient;
    }

    const baseUrl =
      this.getOptionalConfigValue('TURNKEY_BASE_URL') ??
      'https://api.turnkey.com';
    const apiPublicKey = this.requireConfigValue('TURNKEY_API_PUBLIC_KEY');
    const apiPrivateKey = this.requireConfigValue('TURNKEY_API_PRIVATE_KEY');
    this.requireConfigValue('TURNKEY_API_KEY_ID');

    this.turnkeyClient = new TurnkeyClient(
      {
        baseUrl,
      },
      new ApiKeyStamper({
        apiPublicKey,
        apiPrivateKey,
      }),
    );
    return this.turnkeyClient;
  }

  private getChainClient(chainId: number): PublicClient {
    const cached = this.chainClientById.get(chainId);
    if (cached) {
      return cached;
    }

    const rpcUrl = this.getRpcUrlForChainId(chainId);
    if (!rpcUrl) {
      throw new ServiceUnavailableException(
        `No RPC URL configured for chainId=${chainId}`,
      );
    }

    const client = createPublicClient({
      transport: http(rpcUrl),
    });

    this.chainClientById.set(chainId, client);
    return client;
  }

  private getRpcUrlForChainId(chainId: number): string | null {
    if (chainId === this.walletConfigService.bscTestnetChainId) {
      return this.walletConfigService.bscRpcTestnet;
    }
    if (chainId === this.walletConfigService.bscMainnetChainId) {
      return this.walletConfigService.bscRpcMainnet;
    }
    return null;
  }

  private async findExistingWalletByName(
    walletName: string,
  ): Promise<CustodyWalletRecord | null> {
    const organizationId = this.requireTurnkeyOrganizationId();
    const client = this.getTurnkeyClient();
    const walletsResponse = await client.getWallets({
      organizationId,
    });

    const existing = walletsResponse.wallets.find(
      (wallet) => wallet.walletName === walletName,
    );
    if (!existing) {
      return null;
    }

    const address = await this.resolveWalletAddress(existing.walletId);
    return {
      providerWalletId: existing.walletId,
      address,
    };
  }

  private async retryFindExistingWalletByName(
    walletName: string,
    attempts = 3,
    delayMs = 300,
  ): Promise<CustodyWalletRecord | null> {
    for (let attempt = 0; attempt < attempts; attempt += 1) {
      const existing = await this.findExistingWalletByName(walletName);
      if (existing) {
        return existing;
      }

      if (attempt < attempts - 1) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    }

    return null;
  }

  private isWalletLabelAlreadyExistsError(error: unknown): boolean {
    if (!(error instanceof TurnkeyRequestError)) {
      return false;
    }

    const message = error.message.toLowerCase();
    return (
      String(error.code) === '3' ||
      message.includes('wallet label must be unique')
    );
  }

  private createWalletName(userId: string): string {
    const compact = userId
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9_-]/g, '');
    const trimmed = compact.length > 48 ? compact.slice(0, 48) : compact;
    return `blocnet-${trimmed || createHash('sha256').update(userId).digest('hex').slice(0, 16)}`;
  }

  private async resolveWalletAddress(walletId: string): Promise<`0x${string}`> {
    const now = Date.now();
    const cached = this.walletAddressCache.get(walletId);
    if (cached && cached.expiresAt > now) {
      return cached.address;
    }

    const organizationId = this.requireTurnkeyOrganizationId();
    const client = this.getTurnkeyClient();

    let address: string | undefined;
    try {
      const accountResponse = await client.getWalletAccount({
        organizationId,
        walletId,
        path: DEFAULT_ETH_WALLET_PATH,
      });
      address = accountResponse.account.address;
    } catch {
      address = undefined;
    }

    if (!address) {
      const accountsResponse = await client.getWalletAccounts({
        organizationId,
        walletId,
      });
      const ethereumAccount = accountsResponse.accounts.find(
        (account) => account.addressFormat === 'ADDRESS_FORMAT_ETHEREUM',
      );
      address =
        ethereumAccount?.address ?? accountsResponse.accounts[0]?.address;
    }

    const normalized = this.normalizeEvmAddress(address);
    if (!normalized) {
      throw new Error(
        `Unable to resolve wallet address for walletId=${walletId}`,
      );
    }

    this.walletAddressCache.set(walletId, {
      address: normalized,
      expiresAt: now + WALLET_ADDRESS_CACHE_TTL_MS,
    });
    return normalized;
  }

  private normalizeEvmAddress(
    value: string | null | undefined,
  ): `0x${string}` | null {
    if (!value) {
      return null;
    }
    const trimmed = value.trim();
    if (!/^0x[a-fA-F0-9]{40}$/.test(trimmed)) {
      return null;
    }
    return trimmed as `0x${string}`;
  }

  private wrapTurnkeyError(
    error: unknown,
    contextMessage: string,
  ): ServiceUnavailableException {
    if (error instanceof ServiceUnavailableException) {
      return error;
    }

    if (error instanceof TurnkeyRequestError) {
      return new ServiceUnavailableException(
        `${contextMessage}: ${error.message} (code=${error.code})`,
      );
    }

    if (error instanceof TurnkeyActivityError) {
      return new ServiceUnavailableException(
        `${contextMessage}: ${error.message} (activityId=${error.activityId ?? 'unknown'})`,
      );
    }

    if (error instanceof Error) {
      return new ServiceUnavailableException(
        `${contextMessage}: ${error.message}`,
      );
    }

    return new ServiceUnavailableException(contextMessage);
  }

  private requireConfigValue(key: string): string {
    const value = this.getOptionalConfigValue(key);
    if (value) {
      return value;
    }
    throw new ServiceUnavailableException(`${key} is not configured`);
  }

  private getOptionalConfigValue(key: string): string | null {
    const value = this.configService.get<string>(key);
    if (!value) {
      return null;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : null;
  }
}
