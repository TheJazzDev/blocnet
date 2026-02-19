export type CreateCustodyWalletInput = {
  userId: string;
  idempotencyKey: string;
};

export type CustodyWalletRecord = {
  providerWalletId: string;
  address: string;
};

export interface CustodyAdapter {
  createWallet(input: CreateCustodyWalletInput): Promise<CustodyWalletRecord>;
}

export const CUSTODY_ADAPTER = Symbol('CUSTODY_ADAPTER');
