/**
 * Tips module: the off-chain BNP ledger — tipping hunters, member-to-member
 * BNP transfers, and the admin currency/fee settings.
 *
 * Currency vocabulary (F-07):
 * - BNP (Blocnet Point): the off-chain points users mine, tip and transfer
 *   today. It is the active tipping currency and is seeded by
 *   `bootstrapTipDefaults()`.
 * - BNT (Blocnet Token): the on-chain token that launches on BSC. It exists
 *   as a tip currency row (enabled, but not the active tipping currency
 *   until launch) so its fee policy and fee vault can be set up ahead of time.
 * - BNP -> BNT conversion happens at token launch. It is NOT implemented yet;
 *   `TipConversion` is the ledger reserved for it.
 * - MCR ("Mine Credits") was the pre-BNP name. It is retired: never created,
 *   enabled or surfaced (see `RETIRED_TIP_CURRENCY_CODES`).
 *
 * `TipTransaction.type` separates tips from transfers; anything that counts
 * tips must filter on `type: tip`.
 */
import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TipBootstrapService } from './tip-bootstrap';
import { TipTransfersService } from './tip-transfers.service';
import { TipsAdminController } from './tips-admin.controller';
import { TipsAdminService } from './tips-admin.service';
import { TipsController } from './tips.controller';
import { TipsService } from './tips.service';

@Module({
  imports: [AuditLogModule, NotificationsModule],
  controllers: [TipsController, TipsAdminController],
  providers: [
    TipBootstrapService,
    TipsService,
    TipsAdminService,
    TipTransfersService,
  ],
  exports: [TipsService, TipTransfersService],
})
export class TipsModule {}
