import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AuditLogService } from '../audit-log/audit-log.service';
import { FinancialAuditActions } from '../common/constants/financial-audit-actions';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateRiskLimitDto } from './dto/update-risk-limit.dto';
import { UpdateWalletAssetPriceDto } from './dto/update-wallet-asset-price.dto';
import { UpdateWalletFeeDto } from './dto/update-wallet-fee.dto';
import { UpdateWalletRuntimeConfigDto } from './dto/update-wallet-runtime-config.dto';
import { DECIMAL_ZERO } from './types/decimal';
import { normalizeWalletAsset } from './wallet-asset.util';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';

@Injectable()
export class WalletAdminConfigService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditLogService: AuditLogService,
    private readonly walletConfigService: WalletConfigService,
    private readonly walletAssetPricingService: WalletAssetPricingService,
  ) {}

  async getRuntimeConfig() {
    return this.walletConfigService.getRuntimeConfig();
  }

  async updateRuntimeConfig(
    actorId: string,
    dto: UpdateWalletRuntimeConfigDto,
  ) {
    const updated = await this.walletConfigService.updateRuntimeConfig({
      walletEnabled: dto.walletEnabled,
      depositsEnabled: dto.depositsEnabled,
      withdrawalsEnabled: dto.withdrawalsEnabled,
      depositRealtimeEnabled: dto.depositRealtimeEnabled,
      bscRpcUrl: dto.bscRpcUrl,
      bscRpcWsUrl: dto.bscRpcWsUrl,
      depositConfirmations: dto.depositConfirmations,
      withdrawalConfirmations: dto.withdrawalConfirmations,
      walletAssetBntEnabled: dto.walletAssetBntEnabled,
      walletAssetBnbEnabled: dto.walletAssetBnbEnabled,
      walletAssetUsdtEnabled: dto.walletAssetUsdtEnabled,
      withdrawalEnabledAssets: dto.withdrawalEnabledAssets,
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.WalletRuntimeConfigUpdated,
      resourceType: 'wallet_runtime_config',
      resourceId: updated.id,
      metadata: updated,
    });

    return updated;
  }

  async listRiskLimits() {
    return this.prisma.riskLimit.findMany({
      orderBy: { tier: 'asc' },
    });
  }

  async updateRiskLimit(
    actorId: string,
    tier: string,
    dto: UpdateRiskLimitDto,
  ) {
    const existing = await this.prisma.riskLimit.findUnique({
      where: { tier },
    });
    if (!existing) {
      throw new NotFoundException('Risk limit tier not found');
    }

    const updated = await this.prisma.riskLimit.update({
      where: { tier },
      data: {
        ...(dto.description !== undefined
          ? { description: dto.description.trim() || null }
          : {}),
        ...(dto.requiresKyc !== undefined
          ? { requiresKyc: dto.requiresKyc }
          : {}),
        ...(dto.maxWithdrawalPerTx !== undefined
          ? {
              maxWithdrawalPerTx: this.parseNonNegativeDecimal(
                dto.maxWithdrawalPerTx,
                'maxWithdrawalPerTx',
              ),
            }
          : {}),
        ...(dto.maxWithdrawalPerDay !== undefined
          ? {
              maxWithdrawalPerDay: this.parseNonNegativeDecimal(
                dto.maxWithdrawalPerDay,
                'maxWithdrawalPerDay',
              ),
            }
          : {}),
        ...(dto.maxInternalTransferPerDay !== undefined
          ? {
              maxInternalTransferPerDay: this.parseNonNegativeDecimal(
                dto.maxInternalTransferPerDay,
                'maxInternalTransferPerDay',
              ),
            }
          : {}),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.RiskLimitUpdated,
      resourceType: 'risk_limit',
      resourceId: updated.id,
      metadata: {
        tier,
      },
    });

    return updated;
  }

  async listFeeConfigs() {
    return this.prisma.walletFeeConfig.findMany({
      orderBy: [{ isActive: 'desc' }, { updatedAt: 'desc' }],
    });
  }

  async updateFeeConfig(actorId: string, key: string, dto: UpdateWalletFeeDto) {
    const existing = await this.prisma.walletFeeConfig.findUnique({
      where: { key },
    });
    if (!existing) {
      throw new NotFoundException('Fee config not found');
    }

    const updated = await this.prisma.walletFeeConfig.update({
      where: { key },
      data: {
        ...(dto.flatFee !== undefined
          ? { flatFee: this.parseNonNegativeDecimal(dto.flatFee, 'flatFee') }
          : {}),
        ...(dto.percentFee !== undefined
          ? {
              percentFee: this.parseNonNegativeDecimal(
                dto.percentFee,
                'percentFee',
              ),
            }
          : {}),
        ...(dto.minFee !== undefined
          ? { minFee: this.parseNonNegativeDecimal(dto.minFee, 'minFee') }
          : {}),
        ...(dto.maxFee !== undefined
          ? {
              maxFee:
                dto.maxFee === null || dto.maxFee === ''
                  ? null
                  : this.parseNonNegativeDecimal(dto.maxFee, 'maxFee'),
            }
          : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.FeeConfigUpdated,
      resourceType: 'wallet_fee_config',
      resourceId: updated.id,
      metadata: {
        key,
      },
    });

    return updated;
  }

  async listAssetPriceConfigs() {
    return this.walletAssetPricingService.listPriceConfigs();
  }

  async updateAssetPriceConfig(
    actorId: string,
    assetRaw: string,
    dto: UpdateWalletAssetPriceDto,
  ) {
    const asset = normalizeWalletAsset(assetRaw);
    if (!asset) {
      throw new BadRequestException('Invalid wallet asset');
    }

    let updated: Awaited<
      ReturnType<WalletAssetPricingService['updatePriceConfig']>
    >;
    try {
      updated = await this.walletAssetPricingService.updatePriceConfig(asset, {
        providerId: dto.providerId,
        fallbackUsdPrice: dto.fallbackUsdPrice,
        isActive: dto.isActive,
      });
    } catch (error) {
      throw new BadRequestException(
        error instanceof Error ? error.message : 'Invalid price config payload',
      );
    }

    await this.auditLogService.create({
      actorId,
      action: FinancialAuditActions.AssetPriceConfigUpdated,
      resourceType: 'wallet_asset_price_config',
      resourceId: updated.id,
      metadata: {
        asset,
      },
    });

    return updated;
  }

  private parseNonNegativeDecimal(
    value: string,
    fieldName: string,
  ): Prisma.Decimal {
    let decimal: Prisma.Decimal;
    try {
      decimal = new Prisma.Decimal(value);
    } catch {
      throw new BadRequestException(
        `${fieldName} must be a valid decimal value`,
      );
    }

    if (decimal.lt(DECIMAL_ZERO)) {
      throw new BadRequestException(`${fieldName} cannot be negative`);
    }
    return decimal;
  }
}
