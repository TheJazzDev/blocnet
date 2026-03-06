import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BlocksModule } from '../blocks/blocks.module';
import { CommunityModerationModule } from '../community-moderation/community-moderation.module';
import { MentionsModule } from '../mentions/mentions.module';
import { CommunityPostsController } from './community-posts.controller';
import { CommunityPostsService } from './community-posts.service';

@Module({
  imports: [
    AuditLogModule,
    BlocksModule,
    CommunityModerationModule,
    MentionsModule,
  ],
  controllers: [CommunityPostsController],
  providers: [CommunityPostsService],
  exports: [CommunityPostsService],
})
export class CommunityPostsModule {}
