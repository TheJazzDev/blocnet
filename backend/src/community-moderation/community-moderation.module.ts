import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { HunterReliabilityModule } from '../hunter-reliability/hunter-reliability.module';
import { CommunityModerationController } from './community-moderation.controller';
import { CommunityModerationEnforcementService } from './community-moderation-enforcement.service';
import { CommunityModerationService } from './community-moderation.service';
import { InactiveGemsModerationService } from './inactive-gems-moderation.service';
import { MyReportsService } from './my-reports.service';

@Module({
  imports: [AuditLogModule, HunterReliabilityModule],
  controllers: [CommunityModerationController],
  providers: [
    CommunityModerationService,
    CommunityModerationEnforcementService,
    InactiveGemsModerationService,
    MyReportsService,
  ],
  exports: [CommunityModerationEnforcementService, CommunityModerationService],
})
export class CommunityModerationModule {}
