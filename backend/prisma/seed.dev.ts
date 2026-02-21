import { PrismaPg } from '@prisma/adapter-pg';
import {
  NotificationType,
  UpdateStatus,
  UpdateUrgency,
  PrismaClient,
  ProjectStatus,
  RoleName,
} from '@prisma/client';
import { Pool } from 'pg';
import { config as loadEnv } from 'dotenv';
import {
  backfillWalletDomainForUsers,
  parseBooleanEnv,
  resolveWalletChainEnvironment,
  resolveWalletChainId,
} from './wallet-seed.util';

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
  | 'hunterNexa'
  | 'hunterSage'
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

type PrimaryTagKey =
  | 'core'
  | 'solana'
  | 'ethereum'
  | 'iceOpenNetwork'
  | 'telegramNetwork'
  | 'binanceSmartChain';

type SecondaryTagKey =
  | 'launching'
  | 'ido'
  | 'airdrops'
  | 'mining'
  | 'partnership'
  | 'governance'
  | 'staking'
  | 'tokenBurn'
  | 'farming'
  | 'nft'
  | 'trading'
  | 'icoIdo'
  | 'gaming'
  | 'wallet'
  | 'security'
  | 'metaverse';

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
      displayName: 'Jazzdev',
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
      key: 'hunterNexa',
      id: '6d4ec119-bbb0-4d5a-b72e-569c5fb73916',
      email: 'hunter.nexa@blocknet.local',
      displayName: 'Hunter Nexa',
      roles: [RoleName.hunter, RoleName.user],
    },
    {
      key: 'hunterSage',
      id: '006a2a8f-f88c-4fc1-a895-0f8d6ceb35f4',
      email: 'hunter.sage@blocknet.local',
      displayName: 'Hunter Sage',
      roles: [RoleName.hunter, RoleName.user],
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
      where: { id: user.id },
      update: {
        email: user.email,
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
  const walletChainEnvironment = resolveWalletChainEnvironment(
    process.env.WALLET_CHAIN_ENVIRONMENT,
  );
  const walletChainId = resolveWalletChainId(walletChainEnvironment, process.env);
  const walletEnabled = parseBooleanEnv(process.env.WALLET_ENABLED, false);
  const seedReadyMockWallets = parseBooleanEnv(
    process.env.WALLET_SEED_READY_MOCK,
    true,
  );

  await backfillWalletDomainForUsers(
    prisma,
    users.map((user) => user.id),
    {
      chainEnvironment: walletChainEnvironment,
      chainId: walletChainId,
      walletEnabled,
      forceReadyMock: walletEnabled && seedReadyMockWallets,
    },
  );

  const primaryTags: Array<{ key: PrimaryTagKey; name: string; slug: string }> = [
    { key: 'core', name: 'Core', slug: 'core' },
    { key: 'solana', name: 'Solana', slug: 'solana' },
    { key: 'ethereum', name: 'Ethereum', slug: 'ethereum' },
    {
      key: 'iceOpenNetwork',
      name: 'Ice Open Network',
      slug: 'ice-open-network',
    },
    {
      key: 'telegramNetwork',
      name: 'Telegram Network',
      slug: 'telegram-network',
    },
    {
      key: 'binanceSmartChain',
      name: 'Binance Smart Chain',
      slug: 'binance-smart-chain',
    },
  ];

  const secondaryTags: Array<{ key: SecondaryTagKey; name: string; slug: string }> = [
    { key: 'launching', name: 'Launching', slug: 'launching' },
    { key: 'ido', name: 'IDO', slug: 'ido' },
    { key: 'airdrops', name: 'Airdrops', slug: 'airdrops' },
    { key: 'mining', name: 'Mining', slug: 'mining' },
    { key: 'partnership', name: 'Partnership', slug: 'partnership' },
    { key: 'governance', name: 'Governance', slug: 'governance' },
    { key: 'staking', name: 'Staking', slug: 'staking' },
    { key: 'tokenBurn', name: 'Token Burn', slug: 'token-burn' },
    { key: 'farming', name: 'Farming', slug: 'farming' },
    { key: 'nft', name: 'NFT', slug: 'nft' },
    { key: 'trading', name: 'Trading', slug: 'trading' },
    { key: 'icoIdo', name: 'ICO/IDO', slug: 'ico-ido' },
    { key: 'gaming', name: 'Gaming', slug: 'gaming' },
    { key: 'wallet', name: 'Wallet', slug: 'wallet' },
    { key: 'security', name: 'Security', slug: 'security' },
    { key: 'metaverse', name: 'Metaverse', slug: 'metaverse' },
  ];

  const riskLimits = [
    {
      tier: 'basic',
      description: 'Default tier for new users',
      requiresKyc: false,
      maxWithdrawalPerTx: '0',
      maxWithdrawalPerDay: '0',
      maxInternalTransferPerDay: '500',
    },
    {
      tier: 'verified',
      description: 'Manual KYC approved users',
      requiresKyc: true,
      maxWithdrawalPerTx: '1000',
      maxWithdrawalPerDay: '3000',
      maxInternalTransferPerDay: '5000',
    },
    {
      tier: 'high_trust',
      description: 'High-trust users with extended limits',
      requiresKyc: true,
      maxWithdrawalPerTx: '5000',
      maxWithdrawalPerDay: '20000',
      maxInternalTransferPerDay: '50000',
    },
  ] as const;

  const primaryTagByKey = new Map<PrimaryTagKey, { id: string }>();
  for (const tag of primaryTags) {
    const row = await prisma.primaryTag.upsert({
      where: { slug: tag.slug },
      update: { name: tag.name },
      create: { name: tag.name, slug: tag.slug },
      select: { id: true },
    });

    primaryTagByKey.set(tag.key, row);
  }

  const secondaryTagByKey = new Map<SecondaryTagKey, { id: string }>();
  for (const tag of secondaryTags) {
    const row = await prisma.secondaryTag.upsert({
      where: { slug: tag.slug },
      update: { name: tag.name },
      create: { name: tag.name, slug: tag.slug },
      select: { id: true },
    });

    secondaryTagByKey.set(tag.key, row);
  }

  for (const limit of riskLimits) {
    await prisma.riskLimit.upsert({
      where: { tier: limit.tier },
      update: {
        description: limit.description,
        requiresKyc: limit.requiresKyc,
        maxWithdrawalPerTx: limit.maxWithdrawalPerTx,
        maxWithdrawalPerDay: limit.maxWithdrawalPerDay,
        maxInternalTransferPerDay: limit.maxInternalTransferPerDay,
      },
      create: {
        tier: limit.tier,
        description: limit.description,
        requiresKyc: limit.requiresKyc,
        maxWithdrawalPerTx: limit.maxWithdrawalPerTx,
        maxWithdrawalPerDay: limit.maxWithdrawalPerDay,
        maxInternalTransferPerDay: limit.maxInternalTransferPerDay,
      },
    });
  }

  const walletFeeConfigs = [
    {
      key: 'withdrawal_bnt_v1',
      flatFee: '1',
      percentFee: '0',
      minFee: '1',
      maxFee: null,
      isActive: true,
    },
    {
      key: 'withdrawal_bnb_v1',
      flatFee: '0.0008',
      percentFee: '0',
      minFee: '0.0008',
      maxFee: null,
      isActive: true,
    },
    {
      key: 'withdrawal_usdt_v1',
      flatFee: '0.5',
      percentFee: '0',
      minFee: '0.5',
      maxFee: null,
      isActive: true,
    },
  ] as const;

  for (const feeConfig of walletFeeConfigs) {
    await prisma.walletFeeConfig.upsert({
      where: { key: feeConfig.key },
      update: {
        flatFee: feeConfig.flatFee,
        percentFee: feeConfig.percentFee,
        minFee: feeConfig.minFee,
        maxFee: feeConfig.maxFee,
        isActive: feeConfig.isActive,
      },
      create: {
        key: feeConfig.key,
        flatFee: feeConfig.flatFee,
        percentFee: feeConfig.percentFee,
        minFee: feeConfig.minFee,
        maxFee: feeConfig.maxFee,
        isActive: feeConfig.isActive,
      },
    });
  }

  const assetPriceConfigs = [
    {
      asset: 'BNT' as const,
      providerId: 'blocnet',
      fallbackUsdPrice: '0.5',
      isActive: true,
    },
    {
      asset: 'BNB' as const,
      providerId: 'binancecoin',
      fallbackUsdPrice: '0',
      isActive: true,
    },
    {
      asset: 'USDT' as const,
      providerId: 'tether',
      fallbackUsdPrice: '1',
      isActive: true,
    },
  ] as const;

  for (const priceConfig of assetPriceConfigs) {
    await prisma.walletAssetPriceConfig.upsert({
      where: { asset: priceConfig.asset },
      update: {
        providerId: priceConfig.providerId,
        fallbackUsdPrice: priceConfig.fallbackUsdPrice,
        isActive: priceConfig.isActive,
      },
      create: {
        asset: priceConfig.asset,
        providerId: priceConfig.providerId,
        fallbackUsdPrice: priceConfig.fallbackUsdPrice,
        isActive: priceConfig.isActive,
      },
    });
  }

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
      primaryTagKey: 'solana' as const,
      secondaryTagKeys: ['airdrops', 'governance'] as const,
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
      primaryTagKey: 'ethereum' as const,
      secondaryTagKeys: ['staking', 'governance'] as const,
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
      primaryTagKey: 'core' as const,
      secondaryTagKeys: ['mining', 'wallet'] as const,
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
      primaryTagKey: 'telegramNetwork' as const,
      secondaryTagKeys: ['airdrops', 'partnership'] as const,
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
      primaryTagKey: 'binanceSmartChain' as const,
      secondaryTagKeys: ['launching', 'ido'] as const,
      status: ProjectStatus.active,
      ownerAdminId: profileByKey.get('adminDelta')!.id,
    },
  ];

  const projectByKey = new Map<SeedProjectKey, { id: string; slug: string }>();

  for (const project of projects) {
    const normalizedName = project.name
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    const row = await prisma.project.upsert({
      where: { slug: project.slug },
      update: {
        name: project.name,
        normalizedName,
        description: project.description,
        primaryTagId: primaryTagByKey.get(project.primaryTagKey)!.id,
        status: project.status,
        ownerAdminId: project.ownerAdminId,
      },
      create: {
        id: project.id,
        slug: project.slug,
        name: project.name,
        normalizedName,
        description: project.description,
        primaryTagId: primaryTagByKey.get(project.primaryTagKey)!.id,
        status: project.status,
        ownerAdminId: project.ownerAdminId,
      },
      select: { id: true, slug: true },
    });

    projectByKey.set(project.key, row);

    await prisma.projectSecondaryTag.deleteMany({
      where: { projectId: row.id },
    });

    if (project.secondaryTagKeys.length > 0) {
      await prisma.projectSecondaryTag.createMany({
        data: project.secondaryTagKeys.map((secondaryTagKey) => ({
          projectId: row.id,
          secondaryTagId: secondaryTagByKey.get(secondaryTagKey)!.id,
        })),
        skipDuplicates: true,
      });
    }
  }

  const posterAssignments = [
    {
      projectKey: 'solanaRadar' as const,
      hunterKey: 'hunterNexa' as const,
      assignedBy: profileByKey.get('adminAlpha')!.id,
    },
    {
      projectKey: 'ethWatch' as const,
      hunterKey: 'hunterSage' as const,
      assignedBy: profileByKey.get('adminDelta')!.id,
    },
    {
      projectKey: 'coreMines' as const,
      hunterKey: 'hunterNexa' as const,
      assignedBy: ownerProfileId,
    },
    {
      projectKey: 'tonDropDesk' as const,
      hunterKey: 'hunterSage' as const,
      assignedBy: profileByKey.get('adminAlpha')!.id,
    },
    {
      projectKey: 'bscLaunchFlow' as const,
      hunterKey: 'hunterNexa' as const,
      assignedBy: profileByKey.get('adminDelta')!.id,
    },
  ];

  for (const assignment of posterAssignments) {
    const projectId = projectByKey.get(assignment.projectKey)!.id;
    const hunterId = profileByKey.get(assignment.hunterKey)!.id;

    await prisma.projectHunter.upsert({
      where: {
        projectId_hunterId: {
          projectId,
          hunterId,
        },
      },
      update: {
        assignedBy: assignment.assignedBy,
      },
      create: {
        projectId,
        hunterId,
        assignedBy: assignment.assignedBy,
      },
    });
  }

  const updates = [
    {
      id: '68a39068-c3c2-47f1-8689-90864d183c31',
      projectKey: 'solanaRadar' as const,
      authorKey: 'adminAlpha' as const,
      urgency: UpdateUrgency.high,
      title: 'Solana Epoch Upgrade Window',
      secondaryTagKeys: ['launching', 'wallet'] as const,
      contentMd:
        'Validator upgrade opens in **48 hours**.\n\n- Snapshot starts: tomorrow 14:00 UTC\n- Eligible wallets: active before snapshot\n- Action: complete wallet signing before deadline.',
    },
    {
      id: '2588f558-f380-46fe-99bb-3026f6417c26',
      projectKey: 'solanaRadar' as const,
      authorKey: 'hunterNexa' as const,
      urgency: UpdateUrgency.medium,
      title: 'Solana Staking Reward Checklist',
      secondaryTagKeys: ['staking', 'governance'] as const,
      contentMd:
        'Quick checklist for this week:\n\n1. Verify staking pool fees.\n2. Confirm validator uptime.\n3. Rebalance rewards every Friday.',
    },
    {
      id: '453bc9cb-40d4-4bbe-b379-5ef3c4e9bd4e',
      projectKey: 'ethWatch' as const,
      authorKey: 'adminDelta' as const,
      urgency: UpdateUrgency.high,
      title: 'Ethereum L2 Governance Vote Live',
      secondaryTagKeys: ['governance', 'ido'] as const,
      contentMd:
        'Governance proposal is now live.\n\n- Vote closes in 36 hours\n- Minimum token threshold applies\n- Focus: treasury allocation and validator incentives.',
    },
    {
      id: '264491cf-f4e1-40a2-b8de-203860241205',
      projectKey: 'ethWatch' as const,
      authorKey: 'hunterSage' as const,
      urgency: UpdateUrgency.low,
      title: 'Ethereum Ecosystem Weekly Recap',
      secondaryTagKeys: ['partnership'] as const,
      contentMd:
        'No urgent action today.\n\nHighlights include updated docs, new partnerships, and security advisory follow-ups.',
    },
    {
      id: 'f53093e9-da89-4f7d-aadf-c8f4477e4ffa',
      projectKey: 'coreMines' as const,
      authorKey: 'owner' as const,
      urgency: UpdateUrgency.medium,
      title: 'Core Mining Pool Difficulty Update',
      secondaryTagKeys: ['mining'] as const,
      contentMd:
        'Mining difficulty adjusted upward.\n\n- Estimated yield reduced by ~8%\n- Recompute electricity break-even\n- Consider auto-switch pools.',
    },
    {
      id: '2cedde8c-c577-46e5-b753-c1f101ef181f',
      projectKey: 'coreMines' as const,
      authorKey: 'hunterNexa' as const,
      urgency: UpdateUrgency.high,
      title: 'Core Node Snapshot Required',
      secondaryTagKeys: ['security', 'wallet'] as const,
      contentMd:
        'Node snapshot deadline moved earlier.\n\nRequired:\n- Backup keys\n- Sync latest snapshot\n- Confirm node health check before 22:00 UTC.',
    },
    {
      id: '3f2d7796-6fbc-4ebc-be77-bfb746f9e9cc',
      projectKey: 'tonDropDesk' as const,
      authorKey: 'adminAlpha' as const,
      urgency: UpdateUrgency.medium,
      title: 'TON Mini App Airdrop Eligibility',
      secondaryTagKeys: ['airdrops'] as const,
      contentMd:
        'Eligibility criteria published.\n\n- Account age > 14 days\n- Activity score minimum required\n- Claim window opens next Monday.',
    },
    {
      id: '4baf1ea7-cd09-43d8-bf43-fd9eb6af90f2',
      projectKey: 'tonDropDesk' as const,
      authorKey: 'hunterSage' as const,
      urgency: UpdateUrgency.low,
      title: 'TON Ecosystem New Partnership',
      secondaryTagKeys: ['partnership'] as const,
      contentMd:
        'Partnership announced with payments provider.\n\nNo immediate action needed. Monitoring integration milestones.',
    },
    {
      id: 'd3e85f87-eb7f-4f9d-ab7d-88f8460288c0',
      projectKey: 'bscLaunchFlow' as const,
      authorKey: 'adminDelta' as const,
      urgency: UpdateUrgency.high,
      title: 'BSC Launchpad KYC Deadline',
      secondaryTagKeys: ['security', 'ido'] as const,
      contentMd:
        'KYC deadline is in 24 hours.\n\n- Complete verification in-app\n- Document mismatch leads to rejection\n- Re-submit early to avoid queue delays.',
    },
    {
      id: '44172153-90bc-47c8-bb2a-454c5ca63b6c',
      projectKey: 'bscLaunchFlow' as const,
      authorKey: 'hunterNexa' as const,
      urgency: UpdateUrgency.medium,
      title: 'BSC Token Claim Process',
      secondaryTagKeys: ['launching', 'wallet'] as const,
      contentMd:
        'Claim process checklist:\n\n1. Confirm wallet network is BSC.\n2. Approve claim transaction.\n3. Verify receipt hash in tracker.',
    },
  ];

  for (const update of updates) {
    const row = await prisma.update.upsert({
      where: { id: update.id },
      update: {
        title: update.title,
        contentMd: update.contentMd,
        urgency: update.urgency,
        status: UpdateStatus.published,
        projectId: projectByKey.get(update.projectKey)!.id,
        authorId: profileByKey.get(update.authorKey)!.id,
      },
      create: {
        id: update.id,
        title: update.title,
        contentMd: update.contentMd,
        urgency: update.urgency,
        status: UpdateStatus.published,
        projectId: projectByKey.get(update.projectKey)!.id,
        authorId: profileByKey.get(update.authorKey)!.id,
      },
    });

    await prisma.updateSecondaryTag.deleteMany({
      where: { updateId: row.id },
    });

    if (update.secondaryTagKeys.length > 0) {
      await prisma.updateSecondaryTag.createMany({
        data: update.secondaryTagKeys.map((secondaryTagKey) => ({
          updateId: row.id,
          secondaryTagId: secondaryTagByKey.get(secondaryTagKey)!.id,
        })),
        skipDuplicates: true,
      });
    }
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
      updateId: '68a39068-c3c2-47f1-8689-90864d183c31',
      urgency: UpdateUrgency.high,
      title: 'Urgent: Solana Epoch Upgrade',
      body: 'Snapshot opens soon. Complete wallet signing before deadline.',
    },
    {
      id: 'cae4d98b-e0a5-4f14-84f0-72e9fc68957d',
      userKey: 'memberKai' as const,
      projectKey: 'coreMines' as const,
      updateId: '2cedde8c-c577-46e5-b753-c1f101ef181f',
      urgency: UpdateUrgency.high,
      title: 'Action Needed: Core Node Snapshot',
      body: 'Snapshot deadline moved earlier. Sync and validate node today.',
    },
    {
      id: 'f8f0141d-9c27-47be-8b1c-669ff84ae2ea',
      userKey: 'memberMila' as const,
      projectKey: 'bscLaunchFlow' as const,
      updateId: 'd3e85f87-eb7f-4f9d-ab7d-88f8460288c0',
      urgency: UpdateUrgency.high,
      title: 'Reminder: BSC KYC Deadline',
      body: 'Complete KYC in the next 24 hours to remain eligible.',
    },
    {
      id: '301fede7-f3f3-4b77-a7d6-e9222fca44d0',
      userKey: 'owner' as const,
      projectKey: 'ethWatch' as const,
      updateId: '453bc9cb-40d4-4bbe-b379-5ef3c4e9bd4e',
      urgency: UpdateUrgency.medium,
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
        updateId: notification.updateId,
        urgency: notification.urgency,
        title: notification.title,
        body: notification.body,
      },
      create: {
        id: notification.id,
        type: NotificationType.project_update,
        userId: profileByKey.get(notification.userKey)!.id,
        projectId: projectByKey.get(notification.projectKey)!.id,
        updateId: notification.updateId,
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
    prisma.update.count(),
    prisma.projectFollow.count(),
    prisma.notification.count(),
    prisma.riskLimit.count(),
  ]);

  console.log(
    `[seed] completed | profiles=${stats[0]} roles=${stats[1]} projects=${stats[2]} updates=${stats[3]} follows=${stats[4]} notifications=${stats[5]} riskLimits=${stats[6]}`,
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
