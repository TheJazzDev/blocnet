import { Module } from '@nestjs/common';
import { AuditLogModule } from '../audit-log/audit-log.module';
import { ProfilesController } from './profiles.controller';
import { AdminUsersController, PublicUsersController, UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [AuditLogModule],
  controllers: [PublicUsersController, UsersController, AdminUsersController, ProfilesController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
