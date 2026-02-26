import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { BadgesModule } from '../badges/badges.module';
import { BlocksModule } from '../blocks/blocks.module';
import { QuestsModule } from '../quests/quests.module';
import { MentionsModule } from '../mentions/mentions.module';
import { CommentsController } from './comments.controller';
import { CommentsService } from './comments.service';

@Module({
  imports: [
    AuditLogModule,
    BadgesModule,
    BlocksModule,
    QuestsModule,
    MentionsModule,
  ],
  controllers: [CommentsController],
  providers: [CommentsService],
  exports: [CommentsService],
})
export class CommentsModule {}
