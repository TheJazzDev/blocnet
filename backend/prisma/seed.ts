import { PrismaPg } from '@prisma/adapter-pg';
import {
  NotificationType,
  PostStatus,
  PostUrgency,
  PrismaClient,
  ProjectStatus,
  RoleName,
} from '@prisma/client';
import { Pool } from 'pg';
import { config as loadEnv } from 'dotenv';

loadEnv({ path: '.env.local', override: true, quiet: true });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required for prisma seed.');
}

const pool = new Pool({ connectionString });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

type SeedUserKey =
  | 'owner'
  | 'adminAlpha'
  | 'adminDelta'
  | 'posterNexa'
  | 'posterSage'
  | 'memberRae'
  | 'memberKai'
  | 'memberMila';

type SeedUser = {
  key: SeedUserKey;
  id: string;
  email: string;
  displayName: string;
  roles: RoleName[];
};

type SeedProjectKey =
  | 'solanaRadar'
  | 'ethWatch'
  | 'coreMines'
  | 'tonDropDesk'
  | 'bscLaunchFlow';

const fallbackOwnerId = '8c244a0e-71f4-4a39-8d30-3d32f2ee9012';
const fallbackOwnerEmail = 'owner@blocknet.local';

async function main() {
  const ownerUserId = process.env.OWNER_USER_ID?.trim() || fallbackOwnerId;
  const ownerEmail = process.env.OWNER_EMAIL?.trim() || fallbackOwnerEmail;

  const users: SeedUser[] = [
    {
      key: 'owner',
      id: ownerUserId,
      email: ownerEmail,
      displayName: 'Blocknet Owner',
      roles: [RoleName.owner, RoleName.user],
    },
    {
      key: 'adminAlpha',
      id: '2ebbe14f-8ab4-4bd4-a705-524192fca2e1',
      email: 'admin.alpha@blocknet.local',
      displayName: 'Admin Alpha',
      roles: [RoleName.admin, RoleName.user],
    },
    {
      key: 'adminDelta',
      id: 'cb3f28af-b140-4e67-a495-378bc6f5f84f',
      email: 'admin.delta@blocknet.local',
      displayName: 'Admin Delta',
      roles: [RoleName.admin, RoleName.user],
    },
    {
      key: 'posterNexa',
      id: '6d4ec119-bbb0-4d5a-b72e-569c5fb73916',
      email: 'poster.nexa@blocknet.local',
      displayName: 'Poster Nexa',
      roles: [RoleName.poster, RoleName.user],
    },
    {
      key: 'posterSage',
      id: '006a2a8f-f88c-4fc1-a895-0f8d6ceb35f4',
      email: 'poster.sage@blocknet.local',
      displayName: 'Poster Sage',
      roles: [RoleName.poster, RoleName.user],
    },
    {
      key: 'memberRae',
      id: 'af4976a2-93e8-4d6f-810d-b9171d8c2ea9',
      email: 'member.rae@blocknet.local',
      displayName: 'Member Rae',
      roles: [RoleName.user],
    },
    {
      key: 'memberKai',
      id: '870f8a2f-4f5d-46de-abf3-f8ad58f99f8a',
      email: 'member.kai@blocknet.local',
      displayName: 'Member Kai',
      roles: [RoleName.user],
    },
    {
      key: 'memberMila',
      id: '47efea2e-fb8c-487f-9683-fd4cb0e9df8d',
      email: 'member.mila@blocknet.local',
      displayName: 'Member Mila',
      roles: [RoleName.user],
    },
  ];

  const profileByKey = new Map<SeedUserKey, { id: string; email: string }>();

  for (const user of users) {
    const profile = await prisma.profile.upsert({
      where: { email: user.email },
      update: {
        displayName: user.displayName,
      },
      create: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
      },
      select: { id: true, email: true },
    });

    profileByKey.set(user.key, profile);
  }

  const ownerProfileId = profileByKey.get('owner')!.id;

  for (const user of users) {
    const profile = profileByKey.get(user.key)!;

    for (const role of user.roles) {
      await prisma.userRole.upsert({
        where: {
          userId_role: {
            userId: profile.id,
            role,
          },
        },
        update: {
          grantedBy: ownerProfileId,
        },
        create: {
          userId: profile.id,
          role,
          grantedBy: ownerProfileId,
        },
      });
    }
  }

  const projects = [
    {
      key: 'solanaRadar' as const,
      id: '1bcc36e7-d00f-41a8-a783-0dbb308cd412',
      slug: 'solana-radar',
      name: 'Solana Radar',
      description:
        'Curated Solana ecosystem updates: validator changes, ecosystem grants, and high-quality airdrop opportunities with verified timelines.',
      primaryTag: 'Solana',
      status: ProjectStatus.active,
      ownerAdminId: profileByKey.get('adminAlpha')!.id,
    },
    {
      key: 'ethWatch' as const,
      id: '9308a0f6-b7f9-4960-a2f0-c8f0f54f0551',
      slug: 'ethereum-watch',
      name: 'Ethereum Watch',
      description:
        'Ethereum project watchlist focused on staking, governance, and protocol upgrades with concise action items for members.',
      primaryTag: 'Ethereum',
      status: ProjectStatus.active,
      ownerAdminId: profileByKey.get('adminDelta')!.id,
    },
    {
      key: 'coreMines' as const,
      id: '19ce7389-b72a-4683-afd5-f2ca3fd6cd1f',
      slug: 'core-mines',
      name: 'Core Mines',
      description:
        'Mining and node operation opportunities on Core with profitability checkpoints, setup notes, and risk flags.',
      primaryTag: 'Core',
      status: ProjectStatus.active,
      ownerAdminId: ownerProfileId,
    },
    {
      key: 'tonDropDesk' as const,
      id: '8eff3f7e-4106-4279-9232-032c1a7a8d48',
      slug: 'ton-drop-desk',
      name: 'TON Drop Desk',
      description:
        'Telegram/TON ecosystem updates for mini-app launches, eligibility windows, and reward claim schedules.',
      primaryTag: 'Telegram Network',
      status: ProjectStatus.active,
      ownerAdminId: profileByKey.get('adminAlpha')!.id,
    },
    {
      key: 'bscLaunchFlow' as const,
      id: '49ea2cf5-b0ca-4a5f-bd98-d96433f281ea',
      slug: 'bsc-launch-flow',
      name: 'BSC Launch Flow',
      description:
        'Binance Smart Chain launch tracking with KYC requirements, token claim windows, and urgent listing alerts.',
      primaryTag: 'Binance Smart Chain',
      status: ProjectStatus.active,
      ownerAdminId: profileByKey.get('adminDelta')!.id,
    },
  ];

  const projectByKey = new Map<SeedProjectKey, { id: string; slug: string }>();

  for (const project of projects) {
    const row = await prisma.project.upsert({
      where: { slug: project.slug },
      update: {
        name: project.name,
        description: project.description,
        primaryTag: project.primaryTag,
        status: project.status,
        ownerAdminId: project.ownerAdminId,
      },
      create: {
        id: project.id,
        slug: project.slug,
        name: project.name,
        description: project.description,
        primaryTag: project.primaryTag,
        status: project.status,
        ownerAdminId: project.ownerAdminId,
      },
      select: { id: true, slug: true },
    });

    projectByKey.set(project.key, row);
  }

  const posterAssignments = [
    {
      projectKey: 'solanaRadar' as const,
      posterKey: 'posterNexa' as const,
      assignedBy: profileByKey.get('adminAlpha')!.id,
    },
    {
      projectKey: 'ethWatch' as const,
      posterKey: 'posterSage' as const,
      assignedBy: profileByKey.get('adminDelta')!.id,
    },
    {
      projectKey: 'coreMines' as const,
      posterKey: 'posterNexa' as const,
      assignedBy: ownerProfileId,
    },
    {
      projectKey: 'tonDropDesk' as const,
      posterKey: 'posterSage' as const,
      assignedBy: profileByKey.get('adminAlpha')!.id,
    },
    {
      projectKey: 'bscLaunchFlow' as const,
      posterKey: 'posterNexa' as const,
      assignedBy: profileByKey.get('adminDelta')!.id,
    },
  ];

  for (const assignment of posterAssignments) {
    const projectId = projectByKey.get(assignment.projectKey)!.id;
    const posterId = profileByKey.get(assignment.posterKey)!.id;

    await prisma.projectPoster.upsert({
      where: {
        projectId_posterId: {
          projectId,
          posterId,
        },
      },
      update: {
        assignedBy: assignment.assignedBy,
      },
      create: {
        projectId,
        posterId,
        assignedBy: assignment.assignedBy,
      },
    });
  }

  const posts = [
    {
      id: '68a39068-c3c2-47f1-8689-90864d183c31',
      projectKey: 'solanaRadar' as const,
      authorKey: 'adminAlpha' as const,
      urgency: PostUrgency.high,
      title: 'Solana Epoch Upgrade Window',
      contentMd:
        'Validator upgrade opens in **48 hours**.\n\n- Snapshot starts: tomorrow 14:00 UTC\n- Eligible wallets: active before snapshot\n- Action: complete wallet signing before deadline.',
    },
    {
      id: '2588f558-f380-46fe-99bb-3026f6417c26',
      projectKey: 'solanaRadar' as const,
      authorKey: 'posterNexa' as const,
      urgency: PostUrgency.medium,
      title: 'Solana Staking Reward Checklist',
      contentMd:
        'Quick checklist for this week:\n\n1. Verify staking pool fees.\n2. Confirm validator uptime.\n3. Rebalance rewards every Friday.',
    },
    {
      id: '453bc9cb-40d4-4bbe-b379-5ef3c4e9bd4e',
      projectKey: 'ethWatch' as const,
      authorKey: 'adminDelta' as const,
      urgency: PostUrgency.high,
      title: 'Ethereum L2 Governance Vote Live',
      contentMd:
        'Governance proposal is now live.\n\n- Vote closes in 36 hours\n- Minimum token threshold applies\n- Focus: treasury allocation and validator incentives.',
    },
    {
      id: '264491cf-f4e1-40a2-b8de-203860241205',
      projectKey: 'ethWatch' as const,
      authorKey: 'posterSage' as const,
      urgency: PostUrgency.low,
      title: 'Ethereum Ecosystem Weekly Recap',
      contentMd:
        'No urgent action today.\n\nHighlights include updated docs, new partnerships, and security advisory follow-ups.',
    },
    {
      id: 'f53093e9-da89-4f7d-aadf-c8f4477e4ffa',
      projectKey: 'coreMines' as const,
      authorKey: 'owner' as const,
      urgency: PostUrgency.medium,
      title: 'Core Mining Pool Difficulty Update',
      contentMd:
        'Mining difficulty adjusted upward.\n\n- Estimated yield reduced by ~8%\n- Recompute electricity break-even\n- Consider auto-switch pools.',
    },
    {
      id: '2cedde8c-c577-46e5-b753-c1f101ef181f',
      projectKey: 'coreMines' as const,
      authorKey: 'posterNexa' as const,
      urgency: PostUrgency.high,
      title: 'Core Node Snapshot Required',
      contentMd:
        'Node snapshot deadline moved earlier.\n\nRequired:\n- Backup keys\n- Sync latest snapshot\n- Confirm node health check before 22:00 UTC.',
    },
    {
      id: '3f2d7796-6fbc-4ebc-be77-bfb746f9e9cc',
      projectKey: 'tonDropDesk' as const,
      authorKey: 'adminAlpha' as const,
      urgency: PostUrgency.medium,
      title: 'TON Mini App Airdrop Eligibility',
      contentMd:
        'Eligibility criteria published.\n\n- Account age > 14 days\n- Activity score minimum required\n- Claim window opens next Monday.',
    },
    {
      id: '4baf1ea7-cd09-43d8-bf43-fd9eb6af90f2',
      projectKey: 'tonDropDesk' as const,
      authorKey: 'posterSage' as const,
      urgency: PostUrgency.low,
      title: 'TON Ecosystem New Partnership',
      contentMd:
        'Partnership announced with payments provider.\n\nNo immediate action needed. Monitoring integration milestones.',
    },
    {
      id: 'd3e85f87-eb7f-4f9d-ab7d-88f8460288c0',
      projectKey: 'bscLaunchFlow' as const,
      authorKey: 'adminDelta' as const,
      urgency: PostUrgency.high,
      title: 'BSC Launchpad KYC Deadline',
      contentMd:
        'KYC deadline is in 24 hours.\n\n- Complete verification in-app\n- Document mismatch leads to rejection\n- Re-submit early to avoid queue delays.',
    },
    {
      id: '44172153-90bc-47c8-bb2a-454c5ca63b6c',
      projectKey: 'bscLaunchFlow' as const,
      authorKey: 'posterNexa' as const,
      urgency: PostUrgency.medium,
      title: 'BSC Token Claim Process',
      contentMd:
        'Claim process checklist:\n\n1. Confirm wallet network is BSC.\n2. Approve claim transaction.\n3. Verify receipt hash in tracker.',
    },
  ];

  for (const post of posts) {
    await prisma.post.upsert({
      where: { id: post.id },
      update: {
        title: post.title,
        contentMd: post.contentMd,
        urgency: post.urgency,
        status: PostStatus.published,
        projectId: projectByKey.get(post.projectKey)!.id,
        authorId: profileByKey.get(post.authorKey)!.id,
      },
      create: {
        id: post.id,
        title: post.title,
        contentMd: post.contentMd,
        urgency: post.urgency,
        status: PostStatus.published,
        projectId: projectByKey.get(post.projectKey)!.id,
        authorId: profileByKey.get(post.authorKey)!.id,
      },
    });
  }

  const follows = [
    { projectKey: 'solanaRadar' as const, userKey: 'memberRae' as const },
    { projectKey: 'solanaRadar' as const, userKey: 'memberKai' as const },
    { projectKey: 'ethWatch' as const, userKey: 'memberMila' as const },
    { projectKey: 'ethWatch' as const, userKey: 'memberRae' as const },
    { projectKey: 'coreMines' as const, userKey: 'memberKai' as const },
    { projectKey: 'coreMines' as const, userKey: 'memberMila' as const },
    { projectKey: 'tonDropDesk' as const, userKey: 'memberRae' as const },
    { projectKey: 'bscLaunchFlow' as const, userKey: 'memberMila' as const },
    { projectKey: 'bscLaunchFlow' as const, userKey: 'memberKai' as const },
  ];

  for (const follow of follows) {
    await prisma.projectFollow.upsert({
      where: {
        projectId_userId: {
          projectId: projectByKey.get(follow.projectKey)!.id,
          userId: profileByKey.get(follow.userKey)!.id,
        },
      },
      update: {},
      create: {
        projectId: projectByKey.get(follow.projectKey)!.id,
        userId: profileByKey.get(follow.userKey)!.id,
      },
    });
  }

  const notifications = [
    {
      id: '16cbf5ea-ae97-4445-b1e8-63559095cde4',
      userKey: 'memberRae' as const,
      projectKey: 'solanaRadar' as const,
      postId: '68a39068-c3c2-47f1-8689-90864d183c31',
      urgency: PostUrgency.high,
      title: 'Urgent: Solana Epoch Upgrade',
      body: 'Snapshot opens soon. Complete wallet signing before deadline.',
    },
    {
      id: 'cae4d98b-e0a5-4f14-84f0-72e9fc68957d',
      userKey: 'memberKai' as const,
      projectKey: 'coreMines' as const,
      postId: '2cedde8c-c577-46e5-b753-c1f101ef181f',
      urgency: PostUrgency.high,
      title: 'Action Needed: Core Node Snapshot',
      body: 'Snapshot deadline moved earlier. Sync and validate node today.',
    },
    {
      id: 'f8f0141d-9c27-47be-8b1c-669ff84ae2ea',
      userKey: 'memberMila' as const,
      projectKey: 'bscLaunchFlow' as const,
      postId: 'd3e85f87-eb7f-4f9d-ab7d-88f8460288c0',
      urgency: PostUrgency.high,
      title: 'Reminder: BSC KYC Deadline',
      body: 'Complete KYC in the next 24 hours to remain eligible.',
    },
    {
      id: '301fede7-f3f3-4b77-a7d6-e9222fca44d0',
      userKey: 'owner' as const,
      projectKey: 'ethWatch' as const,
      postId: '453bc9cb-40d4-4bbe-b379-5ef3c4e9bd4e',
      urgency: PostUrgency.medium,
      title: 'Review: Ethereum Governance Vote',
      body: 'Admin Delta posted a governance vote summary for member action.',
    },
  ];

  for (const notification of notifications) {
    await prisma.notification.upsert({
      where: { id: notification.id },
      update: {
        type: NotificationType.project_update,
        userId: profileByKey.get(notification.userKey)!.id,
        projectId: projectByKey.get(notification.projectKey)!.id,
        postId: notification.postId,
        urgency: notification.urgency,
        title: notification.title,
        body: notification.body,
      },
      create: {
        id: notification.id,
        type: NotificationType.project_update,
        userId: profileByKey.get(notification.userKey)!.id,
        projectId: projectByKey.get(notification.projectKey)!.id,
        postId: notification.postId,
        urgency: notification.urgency,
        title: notification.title,
        body: notification.body,
      },
    });
  }

  const stats = await Promise.all([
    prisma.profile.count(),
    prisma.userRole.count(),
    prisma.project.count(),
    prisma.post.count(),
    prisma.projectFollow.count(),
    prisma.notification.count(),
  ]);

  console.log(
    `[seed] completed | profiles=${stats[0]} roles=${stats[1]} projects=${stats[2]} posts=${stats[3]} follows=${stats[4]} notifications=${stats[5]}`,
  );
  console.log(`[seed] owner email: ${ownerEmail}`);
}

main()
  .catch((error) => {
    console.error('[seed] Failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
