import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { SocialWebhooksController } from './social-webhooks.controller';
import { SocialWebhooksService } from './social-webhooks.service';

@Module({
  imports: [PrismaModule, AuditLogModule],
  controllers: [SocialWebhooksController],
  providers: [SocialWebhooksService],
})
export class SocialModule {}
