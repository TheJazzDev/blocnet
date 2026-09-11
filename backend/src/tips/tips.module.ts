/**
 * Tips module: peer-to-peer tipping between users and hunters.
 *
 * Currency vocabulary (F-07):
 * - BNP (Blocnet Point): the off-chain points users mine and tip with today.
 *   It is the active tipping currency and is seeded by `bootstrapDefaults()`.
 * - BNT (Blocnet Token): the on-chain token that launches on BSC. It exists
 *   as a tip currency row (enabled, but not the active tipping currency
 *   until launch) so its fee policy and fee vault can be set up ahead of time.
 * - BNP -> BNT conversion happens at token launch. It is NOT implemented yet;
 *   `TipConversion` is the ledger reserved for it.
 * - MCR ("Mine Credits") was the pre-BNP name. It is retired: never created,
 *   enabled or surfaced (see `RETIRED_TIP_CURRENCY_CODES`).
 */
import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TipsAdminController } from './tips-admin.controller';
import { TipsController } from './tips.controller';
import { TipsService } from './tips.service';

@Module({
  imports: [AuditLogModule, NotificationsModule],
  controllers: [TipsController, TipsAdminController],
  providers: [TipsService],
  exports: [TipsService],
})
export class TipsModule {}
