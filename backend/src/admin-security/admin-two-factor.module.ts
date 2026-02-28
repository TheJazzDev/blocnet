import { Global, Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { PrismaModule } from '../prisma/prisma.module';
import { AdminTwoFactorController } from './admin-two-factor.controller';
import { AdminTwoFactorService } from './admin-two-factor.service';

@Global()
@Module({
  imports: [PrismaModule, AuditLogModule],
  controllers: [AdminTwoFactorController],
  providers: [AdminTwoFactorService],
  exports: [AdminTwoFactorService],
})
export class AdminTwoFactorModule {}
