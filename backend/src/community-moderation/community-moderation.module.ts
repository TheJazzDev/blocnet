import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { CommunityModerationController } from './community-moderation.controller';
import { CommunityModerationEnforcementService } from './community-moderation-enforcement.service';
import { CommunityModerationService } from './community-moderation.service';

@Module({
  imports: [AuditLogModule],
  controllers: [CommunityModerationController],
  providers: [CommunityModerationService, CommunityModerationEnforcementService],
  exports: [CommunityModerationEnforcementService, CommunityModerationService],
})
export class CommunityModerationModule {}
