import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/interfaces/auth-user.interface';
import { ListWalletAdminWithdrawalsQuery } from './dto/list-wallet-admin-withdrawals.query';
import { ListWalletKycQuery } from './dto/list-wallet-kyc.query';
import { ListWalletUsersQuery } from './dto/list-wallet-users.query';
import { ReprocessDepositByTxHashDto } from './dto/reprocess-deposit-by-tx-hash.dto';
import { ReviewWithdrawalDto } from './dto/review-withdrawal.dto';
import { ReviewKycDto } from './dto/review-kyc.dto';
import { UpdateRiskLimitDto } from './dto/update-risk-limit.dto';
import { UpdateWalletAssetPriceDto } from './dto/update-wallet-asset-price.dto';
import { UpdateWalletFeeDto } from './dto/update-wallet-fee.dto';
import { UpdateWalletRuntimeConfigDto } from './dto/update-wallet-runtime-config.dto';
import { UpdateWalletUserStatusDto } from './dto/update-wallet-user-status.dto';
import { WalletAdminService } from './wallet-admin.service';
import { WalletAdminKycService } from './wallet-admin-kyc.service';
import { WalletAdminWithdrawalService } from './wallet-admin-withdrawal.service';
import { WalletAdminConfigService } from './wallet-admin-config.service';

@Controller('admin/wallet')
@UseGuards(AuthGuard, RolesGuard)
@Roles(AppRole.OWNER, AppRole.ADMIN, AppRole.MODERATOR)
export class WalletAdminController {
  constructor(
    private readonly walletAdminService: WalletAdminService,
    private readonly walletAdminKycService: WalletAdminKycService,
    private readonly walletAdminWithdrawalService: WalletAdminWithdrawalService,
    private readonly walletAdminConfigService: WalletAdminConfigService,
  ) {}

  @Get('health')
  async getWalletHealth() {
    return this.walletAdminService.getWalletHealth();
  }

  @Get('users')
  async listWalletUsers(@Query() query: ListWalletUsersQuery) {
    return this.walletAdminService.listWalletUsers(query);
  }

  @Patch('users/:userId/status')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateWalletUserStatus(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: UpdateWalletUserStatusDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminService.updateWalletUserStatus(
      user.id,
      userId,
      dto.disabled,
    );
  }

  @Post('deposits/reprocess')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async reprocessDepositByTxHash(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: ReprocessDepositByTxHashDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminService.reprocessDepositByTxHash(user.id, dto);
  }

  @Get('withdrawals')
  async listWithdrawals(@Query() query: ListWalletAdminWithdrawalsQuery) {
    return this.walletAdminWithdrawalService.listWithdrawals(query);
  }

  @Patch('withdrawals/:id/review')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async reviewWithdrawal(
    @CurrentUser() user: AuthUser | undefined,
    @Param('id') id: string,
    @Body() dto: ReviewWithdrawalDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminWithdrawalService.reviewWithdrawal(user.id, id, dto);
  }

  @Get('kyc')
  async listKyc(@Query() query: ListWalletKycQuery) {
    return this.walletAdminKycService.listKyc(query);
  }

  @Patch('kyc/:userId/review')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async reviewKyc(
    @CurrentUser() user: AuthUser | undefined,
    @Param('userId') userId: string,
    @Body() dto: ReviewKycDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminKycService.reviewKyc(user.id, userId, dto);
  }

  @Get('settings/risk-limits')
  async listRiskLimits() {
    return this.walletAdminConfigService.listRiskLimits();
  }

  @Patch('settings/risk-limits/:tier')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateRiskLimit(
    @CurrentUser() user: AuthUser | undefined,
    @Param('tier') tier: string,
    @Body() dto: UpdateRiskLimitDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminConfigService.updateRiskLimit(user.id, tier, dto);
  }

  @Get('settings/fees')
  async listFeeConfigs() {
    return this.walletAdminConfigService.listFeeConfigs();
  }

  @Patch('settings/fees/:key')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateFeeConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Param('key') key: string,
    @Body() dto: UpdateWalletFeeDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminConfigService.updateFeeConfig(user.id, key, dto);
  }

  @Get('settings/prices')
  async listAssetPriceConfigs() {
    return this.walletAdminConfigService.listAssetPriceConfigs();
  }

  @Get('settings/runtime')
  async getRuntimeConfig() {
    return this.walletAdminConfigService.getRuntimeConfig();
  }

  @Patch('settings/runtime')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateRuntimeConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Body() dto: UpdateWalletRuntimeConfigDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminConfigService.updateRuntimeConfig(user.id, dto);
  }

  @Patch('settings/prices/:asset')
  @Roles(AppRole.OWNER, AppRole.ADMIN)
  async updateAssetPriceConfig(
    @CurrentUser() user: AuthUser | undefined,
    @Param('asset') asset: string,
    @Body() dto: UpdateWalletAssetPriceDto,
  ) {
    if (!user) {
      throw new UnauthorizedException('User context missing');
    }
    return this.walletAdminConfigService.updateAssetPriceConfig(
      user.id,
      asset,
      dto,
    );
  }
}
