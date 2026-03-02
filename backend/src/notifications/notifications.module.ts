import { Module } from '@nestjs/common';
import { DigestComposerService } from './digest-composer.service';
import { NotificationEmailService } from './email.service';
import { EmailTemplateService } from './email-template.service';
import { NotificationPreferencesService } from './notification-preferences.service';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';
import { NotificationEventsService } from './notification-events.service';
import { FcmService } from './fcm.service';

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationEventsService,
    NotificationPreferencesService,
    NotificationEmailService,
    EmailTemplateService,
    DigestComposerService,
    FcmService,
  ],
  exports: [
    NotificationsService,
    NotificationEventsService,
    NotificationPreferencesService,
    NotificationEmailService,
    EmailTemplateService,
    DigestComposerService,
    FcmService,
  ],
})
export class NotificationsModule {}
