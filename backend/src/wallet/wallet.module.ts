import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { CUSTODY_ADAPTER } from './custody/custody.adapter';
import { TurnkeyCustodyAdapter } from './custody/turnkey-custody.adapter';
import { WalletAdminController } from './wallet-admin.controller';
import { WalletAdminService } from './wallet-admin.service';
import { WalletController } from './wallet.controller';
import { WalletDepositIndexerService } from './wallet-deposit-indexer.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { WalletSettlementWorkerService } from './wallet-settlement-worker.service';
import { WalletService } from './wallet.service';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletQueryService } from './wallet-query.service';
import { WalletTransactionService } from './wallet-transaction.service';
import { WalletDepositProcessorService } from './wallet-deposit-processor.service';
import { WalletSweepService } from './wallet-sweep.service';
import { WalletWithdrawalSettlementService } from './wallet-withdrawal-settlement.service';
import { WalletAdminKycService } from './wallet-admin-kyc.service';
import { WalletAdminWithdrawalService } from './wallet-admin-withdrawal.service';
import { WalletAdminConfigService } from './wallet-admin-config.service';

@Module({
  imports: [PrismaModule, AuditLogModule],
  controllers: [WalletController, WalletAdminController],
  providers: [
    WalletConfigService,
    WalletDepositIndexerService,
    WalletDepositProcessorService,
    WalletSettlementWorkerService,
    WalletSweepService,
    WalletWithdrawalSettlementService,
    WalletProvisioningService,
    WalletAssetPricingService,
    WalletQueryService,
    WalletTransactionService,
    WalletService,
    WalletAdminService,
    WalletAdminKycService,
    WalletAdminWithdrawalService,
    WalletAdminConfigService,
    TurnkeyCustodyAdapter,
    {
      provide: CUSTODY_ADAPTER,
      useExisting: TurnkeyCustodyAdapter,
    },
  ],
  exports: [
    WalletConfigService,
    WalletProvisioningService,
    WalletAssetPricingService,
    WalletQueryService,
    WalletTransactionService,
    WalletService,
    WalletAdminService,
    WalletAdminKycService,
    WalletAdminWithdrawalService,
    WalletAdminConfigService,
    CUSTODY_ADAPTER,
  ],
})
export class WalletModule {}
