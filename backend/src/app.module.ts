import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { join } from 'path';
import { AdminApplicationsModule } from './admin-applications/admin-applications.module';
import { AdminContentModule } from './admin-content/admin-content.module';
import { AdminTwoFactorModule } from './admin-security/admin-two-factor.module';
import { AuditLogModule } from './audit-log/audit-log.module';
import { AuthModule } from './auth/auth.module';
import { BadgesModule } from './badges/badges.module';
import { BlocksModule } from './blocks/blocks.module';
import { CommentsModule } from './comments/comments.module';
import { LevelsModule } from './levels/levels.module';
import { CommunityPostsModule } from './community-posts/community-posts.module';
import { MentionsModule } from './mentions/mentions.module';
import { QuestsModule } from './quests/quests.module';
import { DeviceTokensModule } from './device-tokens/device-tokens.module';
import { EdgeEngineModule } from './edge-engine/edge-engine.module';
import { FollowsModule } from './follows/follows.module';
import { HealthModule } from './health/health.module';
import { MeRadarModule } from './me-radar/me-radar.module';
import { MiningModule } from './mining/mining.module';
import { NotificationsModule } from './notifications/notifications.module';
import { UpdatesModule } from './updates/updates.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProjectAssignmentsModule } from './project-assignments/project-assignments.module';
import { ProjectProposalsModule } from './project-proposals/project-proposals.module';
import { ProjectsModule } from './projects/projects.module';
import { ReferralsModule } from './referrals/referrals.module';
import { RolesModule } from './roles/roles.module';
import { RuntimeFeatureFlagsModule } from './runtime-flags/runtime-feature-flags.module';
import { SocialCredentialsModule } from './social-credentials/social-credentials.module';
import { SocialModule } from './social/social.module';
import { TagsModule } from './tags/tags.module';
import { TipsModule } from './tips/tips.module';
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
    RuntimeFeatureFlagsModule,
    AdminTwoFactorModule,
    SocialCredentialsModule,
    SocialModule,
    PrismaModule,
    AuthModule,
    UsersModule,
    RolesModule,
    EdgeEngineModule,
    AdminApplicationsModule,
    AdminContentModule,
    BadgesModule,
    BlocksModule,
    LevelsModule,
    QuestsModule,
    ProjectsModule,
    ProjectAssignmentsModule,
    ProjectProposalsModule,
    TagsModule,
    UpdatesModule,
    CommentsModule,
    CommunityPostsModule,
    MentionsModule,
    FollowsModule,
    NotificationsModule,
    MeRadarModule,
    MiningModule,
    ReferralsModule,
    TipsModule,
    DeviceTokensModule,
    WalletModule,
    HealthModule,
    AuditLogModule,
  ],
  providers: [AuthGuard, RolesGuard],
})
export class AppModule {}
