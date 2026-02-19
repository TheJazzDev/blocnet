import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';
import { AdminApplicationsModule } from './admin-applications/admin-applications.module';
import { AdminContentModule } from './admin-content/admin-content.module';
import { AuditLogModule } from './audit-log/audit-log.module';
import { AuthModule } from './auth/auth.module';
import { CommentsModule } from './comments/comments.module';
import { CommunityPostsModule } from './community-posts/community-posts.module';
import { DeviceTokensModule } from './device-tokens/device-tokens.module';
import { FollowsModule } from './follows/follows.module';
import { HealthModule } from './health/health.module';
import { NotificationsModule } from './notifications/notifications.module';
import { UpdatesModule } from './updates/updates.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProjectAssignmentsModule } from './project-assignments/project-assignments.module';
import { ProjectProposalsModule } from './project-proposals/project-proposals.module';
import { ProjectsModule } from './projects/projects.module';
import { RolesModule } from './roles/roles.module';
import { TagsModule } from './tags/tags.module';
import { UsersModule } from './users/users.module';
import { WalletModule } from './wallet/wallet.module';
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
    AdminContentModule,
    ProjectsModule,
    ProjectAssignmentsModule,
    ProjectProposalsModule,
    TagsModule,
    UpdatesModule,
    CommentsModule,
    CommunityPostsModule,
    FollowsModule,
    NotificationsModule,
    DeviceTokensModule,
    WalletModule,
    HealthModule,
    AuditLogModule,
  ],
  providers: [AuthGuard, RolesGuard],
})
export class AppModule {}
