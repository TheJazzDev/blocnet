import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BlocksModule } from '../blocks/blocks.module';
import { MentionsModule } from '../mentions/mentions.module';
import { CommunityPostsController } from './community-posts.controller';
import { CommunityPostsService } from './community-posts.service';

@Module({
  imports: [AuditLogModule, BlocksModule, MentionsModule],
  controllers: [CommunityPostsController],
  providers: [CommunityPostsService],
  exports: [CommunityPostsService],
})
export class CommunityPostsModule {}
