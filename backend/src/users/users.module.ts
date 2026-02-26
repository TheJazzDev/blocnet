import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { NotificationDigestWorker } from '../notifications/notification-digest.worker';
import { QuestsModule } from '../quests/quests.module';
import { ProfilesController } from './profiles.controller';
import {
  AdminUsersController,
  PublicUsersController,
  UsersController,
} from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [AuditLogModule, NotificationsModule, QuestsModule],
  controllers: [
    PublicUsersController,
    UsersController,
    AdminUsersController,
    ProfilesController,
  ],
  providers: [UsersService, NotificationDigestWorker],
  exports: [UsersService],
})
export class UsersModule {}
