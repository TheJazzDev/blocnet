import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BadgesModule } from '../badges/badges.module';
import { LevelsModule } from '../levels/levels.module';
import { QuestsModule } from '../quests/quests.module';
import { MiningAdminController } from './mining-admin.controller';
import { MiningController } from './mining.controller';
import { MiningService } from './mining.service';
import { MiningCalculatorService } from './mining-calculator.service';
import { MiningConfigService } from './mining-config.service';
import { MiningAdminService } from './mining-admin.service';
import { MiningLeaderboardService } from './mining-leaderboard.service';

@Module({
  imports: [AuditLogModule, BadgesModule, LevelsModule, QuestsModule],
  controllers: [MiningController, MiningAdminController],
  providers: [
    MiningService,
    MiningCalculatorService,
    MiningConfigService,
    MiningAdminService,
    MiningLeaderboardService,
  ],
  exports: [
    MiningService,
    MiningCalculatorService,
    MiningConfigService,
    MiningAdminService,
    MiningLeaderboardService,
  ],
})
export class MiningModule {}
