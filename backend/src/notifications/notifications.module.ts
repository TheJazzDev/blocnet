import { Module } from '@nestjs/common';
import { DigestComposerService } from './digest-composer.service';
import { NotificationEmailService } from './email.service';
import { NotificationPreferencesService } from './notification-preferences.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { FcmService } from './fcm.service';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationPreferencesService,
    NotificationEmailService,
    DigestComposerService,
    FcmService,
  ],
  exports: [
    NotificationsService,
    NotificationPreferencesService,
    NotificationEmailService,
    DigestComposerService,
    FcmService,
  ],
})
export class NotificationsModule {}
