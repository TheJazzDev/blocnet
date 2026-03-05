import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { NotificationDigestWorker } from '../notifications/notification-digest.worker';
import { QuestsModule } from '../quests/quests.module';
import { ReferralsModule } from '../referrals/referrals.module';
import { UpdatesModule } from '../updates/updates.module';
import { EdgeEngineModule } from '../edge-engine/edge-engine.module';
import { MeRadarModule } from '../me-radar/me-radar.module';
import { ProfilesController } from './profiles.controller';
import {
  AdminUsersController,
  PublicUsersController,
  UsersController,
} from './users.controller';
import { UsersService } from './users.service';
import { UsersAdminService } from './users-admin.service';
import { UserDigestService } from './user-digest.service';
import { UserAvatarService } from './user-avatar.service';

@Module({
  imports: [
    AuditLogModule,
    NotificationsModule,
    QuestsModule,
    ReferralsModule,
    UpdatesModule,
    EdgeEngineModule,
    MeRadarModule,
  ],
  controllers: [
    PublicUsersController,
    UsersController,
    AdminUsersController,
    ProfilesController,
  ],
  providers: [
    UsersService,
    UsersAdminService,
    UserDigestService,
    UserAvatarService,
    NotificationDigestWorker,
  ],
  exports: [
    UsersService,
    UsersAdminService,
    UserDigestService,
    UserAvatarService,
  ],
})
export class UsersModule {}
