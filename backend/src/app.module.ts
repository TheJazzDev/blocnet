import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';
import { AdminApplicationsModule } from './admin-applications/admin-applications.module';
import { AuditLogModule } from './audit-log/audit-log.module';
import { AuthModule } from './auth/auth.module';
import { DeviceTokensModule } from './device-tokens/device-tokens.module';
import { FollowsModule } from './follows/follows.module';
import { HealthModule } from './health/health.module';
import { NotificationsModule } from './notifications/notifications.module';
import { PostsModule } from './posts/posts.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProjectAssignmentsModule } from './project-assignments/project-assignments.module';
import { ProjectsModule } from './projects/projects.module';
import { RolesModule } from './roles/roles.module';
import { UsersModule } from './users/users.module';
import { AuthGuard } from './common/guards/auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { envValidationSchema } from './config/env.validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        '.env.local',
        '.env',
        join(process.cwd(), 'backend/.env.local'),
        join(process.cwd(), 'backend/.env'),
      ],
      validationSchema: envValidationSchema,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    RolesModule,
    AdminApplicationsModule,
    ProjectsModule,
    ProjectAssignmentsModule,
    PostsModule,
    FollowsModule,
    NotificationsModule,
    DeviceTokensModule,
    HealthModule,
    AuditLogModule,
  ],
  providers: [AuthGuard, RolesGuard],
})
export class AppModule {}
