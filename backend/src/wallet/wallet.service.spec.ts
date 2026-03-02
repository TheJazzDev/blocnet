import { WalletService } from './wallet.service';
import { WalletQueryService } from './wallet-query.service';
import { WalletTransactionService } from './wallet-transaction.service';

describe('WalletService', () => {
  const walletQueryService = {
    getWalletSummary: jest.fn(),
    getWalletHealth: jest.fn(),
    listWalletTransactions: jest.fn(),
    getKycStatus: jest.fn(),
    listWithdrawals: jest.fn(),
  } as unknown as WalletQueryService;

  const walletTransactionService = {
    createInternalTransfer: jest.fn(),
    submitKyc: jest.fn(),
    createWithdrawal: jest.fn(),
  } as unknown as WalletTransactionService;

  let service: WalletService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new WalletService(walletQueryService, walletTransactionService);
  });

  it('delegates wallet summary query', async () => {
    const getWalletSummaryMock =
      walletQueryService.getWalletSummary as jest.Mock;
    getWalletSummaryMock.mockResolvedValue({
      walletId: 'wallet-1',
    });

    const result = await service.getWalletSummary('user-1');

    expect(getWalletSummaryMock).toHaveBeenCalledWith('user-1');
    expect(result).toEqual({ walletId: 'wallet-1' });
  });

  it('delegates internal transfer creation', async () => {
    const payload = {
      id: 'entry-1',
      amount: '2',
      reason: 'internal_transfer',
    };
    const createInternalTransferMock =
      walletTransactionService.createInternalTransfer as jest.Mock;
    createInternalTransferMock.mockResolvedValue(payload);

    const result = await service.createInternalTransfer('user-1', {
      amount: '2',
      toUserId: 'user-2',
    });

    expect(createInternalTransferMock).toHaveBeenCalledWith('user-1', {
      amount: '2',
      toUserId: 'user-2',
    });
    expect(result).toEqual(payload);
  });
});
