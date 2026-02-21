export type CreateCustodyWalletInput = {
  userId: string;
  idempotencyKey: string;
};

export type CustodyWalletRecord = {
  providerWalletId: string;
  address: string;
};

export type TransferCustodyTokenInput = {
  idempotencyKey: string;
  chainId: number;
  tokenAddress: `0x${string}`;
  fromProviderWalletId: string;
  toAddress: `0x${string}`;
  amountWei: string;
  metadata?: Record<string, unknown>;
};

export type TransferCustodyNativeInput = {
  idempotencyKey: string;
  chainId: number;
  fromProviderWalletId: string;
  toAddress: `0x${string}`;
  amountWei: string;
  metadata?: Record<string, unknown>;
};

export type CustodyTransferRecord = {
  txHash: string;
  simulated: boolean;
};

export interface CustodyAdapter {
  createWallet(input: CreateCustodyWalletInput): Promise<CustodyWalletRecord>;
  transferToken(input: TransferCustodyTokenInput): Promise<CustodyTransferRecord>;
  transferNative(
    input: TransferCustodyNativeInput,
  ): Promise<CustodyTransferRecord>;
}

export const CUSTODY_ADAPTER = Symbol('CUSTODY_ADAPTER');
