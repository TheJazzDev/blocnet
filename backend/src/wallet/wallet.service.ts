import { Injectable } from '@nestjs/common';
import { WalletQueryService } from './wallet-query.service';
import { WalletTransactionService } from './wallet-transaction.service';
import { CreateInternalTransferDto } from './dto/create-internal-transfer.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
import { ListWalletTransactionsQuery } from './dto/list-wallet-transactions.query';
import { ListWithdrawalsQuery } from './dto/list-withdrawals.query';
import { SubmitKycDto } from './dto/submit-kyc.dto';

@Injectable()
export class WalletService {
  constructor(
    private readonly walletQueryService: WalletQueryService,
    private readonly walletTransactionService: WalletTransactionService,
  ) {}

  async getWalletSummary(userId: string) {
    return this.walletQueryService.getWalletSummary(userId);
  }

  async getWalletHealth(userId: string) {
    return this.walletQueryService.getWalletHealth(userId);
  }

  async listWalletTransactions(
    userId: string,
    query: ListWalletTransactionsQuery,
  ) {
    return this.walletQueryService.listWalletTransactions(userId, query);
  }

  async createInternalTransfer(userId: string, dto: CreateInternalTransferDto) {
    return this.walletTransactionService.createInternalTransfer(userId, dto);
  }

  async submitKyc(userId: string, dto: SubmitKycDto) {
    return this.walletTransactionService.submitKyc(userId, dto);
  }

  async getKycStatus(userId: string) {
    return this.walletQueryService.getKycStatus(userId);
  }

  async createWithdrawal(userId: string, dto: CreateWithdrawalDto) {
    return this.walletTransactionService.createWithdrawal(userId, dto);
  }

  async listWithdrawals(userId: string, query: ListWithdrawalsQuery) {
    return this.walletQueryService.listWithdrawals(userId, query);
  }
}
