import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { SocialCredentialsAdminController } from './social-credentials-admin.controller';
import { SocialCredentialsService } from './social-credentials.service';

@Module({
  imports: [PrismaModule, AuditLogModule],
  controllers: [SocialCredentialsAdminController],
  providers: [SocialCredentialsService],
  exports: [SocialCredentialsService],
})
export class SocialCredentialsModule {}
