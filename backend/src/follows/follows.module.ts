import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { QuestsModule } from '../quests/quests.module';
import { FollowsController } from './follows.controller';
import { FollowsService } from './follows.service';

@Module({
  imports: [AuditLogModule, QuestsModule],
  controllers: [FollowsController],
  providers: [FollowsService],
})
export class FollowsModule {}
