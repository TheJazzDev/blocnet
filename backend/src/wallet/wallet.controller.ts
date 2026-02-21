import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AuthGuard } from '../common/guards/auth.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { CreateInternalTransferDto } from './dto/create-internal-transfer.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
import { ListWalletTransactionsQuery } from './dto/list-wallet-transactions.query';
import { ListWithdrawalsQuery } from './dto/list-withdrawals.query';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { WalletService } from './wallet.service';

@Controller('wallet')
@UseGuards(AuthGuard)
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

  @Get('me')
  async getWalletSummary(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.getWalletSummary(user.id);
  }

  @Get('health')
  async getWalletHealth(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.getWalletHealth(user.id);
  }

  @Get('transactions')
  async listTransactions(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListWalletTransactionsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.listWalletTransactions(user.id, query);
  }

  @Post('transfers/internal')
  async createInternalTransfer(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateInternalTransferDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.createInternalTransfer(user.id, dto);
  }

  @Post('withdrawals')
  async createWithdrawal(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: CreateWithdrawalDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.createWithdrawal(user.id, dto);
  }

  @Get('withdrawals')
  async listWithdrawals(
    @CurrentUser() user: AuthUser | undefined,
    @Query() query: ListWithdrawalsQuery,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.listWithdrawals(user.id, query);
  }

  @Post('kyc/submit')
  async submitKyc(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: SubmitKycDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.submitKyc(user.id, dto);
  }

  @Get('kyc/status')
  async getKycStatus(@CurrentUser() user: AuthUser | undefined) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletService.getKycStatus(user.id);
  }
}
