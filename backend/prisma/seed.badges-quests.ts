import { PrismaPg } from '@prisma/adapter-pg';
import {
  BadgeCategory,
  BadgeRarity,
  PrismaClient,
  QuestType,
} from '@prisma/client';
import { Pool } from 'pg';
import { config as loadEnv } from 'dotenv';

export async function seedBadgesAndQuests(prisma: PrismaClient) {
  console.log('🎖️  Seeding badges and quests...\n');

  // ========== BADGES ==========
  console.log('Creating badges...');

  const badges = [
    // Special badges
    {
      slug: 'founding-member',
      name: 'Founding Member',
      description: 'One of the first 50 members to join Blocnet',
      imageUrl: '',
      category: BadgeCategory.special,
      rarity: BadgeRarity.legendary,
      pointsRequirement: 0,
      sortOrder: 1,
    },
    {
      slug: 'early-adopter',
      name: 'Early Adopter',
      description: 'Joined Blocnet in the first 200 members',
      imageUrl: '',
      category: BadgeCategory.special,
      rarity: BadgeRarity.epic,
      pointsRequirement: 0,
      sortOrder: 2,
    },
    {
      slug: 'pioneer',
      name: 'Pioneer',
      description: 'Joined Blocnet in the first month',
      imageUrl: '',
      category: BadgeCategory.special,
      rarity: BadgeRarity.rare,
      pointsRequirement: 0,
      sortOrder: 3,
    },

    // Mining badges
    {
      slug: 'mining-novice',
      name: 'Mining Novice',
      description: 'Claimed 1,000 mining points',
      imageUrl: '',
      category: BadgeCategory.mining,
      rarity: BadgeRarity.common,
      pointsRequirement: 1000,
      sortOrder: 10,
    },
    {
      slug: 'mining-pro',
      name: 'Mining Pro',
      description: 'Claimed 10,000 mining points',
      imageUrl: '',
      category: BadgeCategory.mining,
      rarity: BadgeRarity.rare,
      pointsRequirement: 10000,
      sortOrder: 11,
    },
    {
      slug: 'mining-expert',
      name: 'Mining Expert',
      description: 'Claimed 50,000 mining points',
      imageUrl: '',
      category: BadgeCategory.mining,
      rarity: BadgeRarity.epic,
      pointsRequirement: 50000,
      sortOrder: 12,
    },
    {
      slug: 'mining-legend',
      name: 'Mining Legend',
      description: 'Claimed 100,000 mining points',
      imageUrl: '',
      category: BadgeCategory.mining,
      rarity: BadgeRarity.legendary,
      pointsRequirement: 100000,
      sortOrder: 13,
    },

    // Engagement badges
    {
      slug: 'first-update',
      name: 'First Steps',
      description: 'Posted your first update',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.common,
      pointsRequirement: 0,
      sortOrder: 20,
    },
    {
      slug: 'content-creator',
      name: 'Content Creator',
      description: 'Posted 10 updates',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.rare,
      pointsRequirement: 0,
      sortOrder: 21,
    },
    {
      slug: 'prolific-creator',
      name: 'Prolific Creator',
      description: 'Posted 50 updates',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.epic,
      pointsRequirement: 0,
      sortOrder: 22,
    },
    {
      slug: 'first-comment',
      name: 'Conversation Starter',
      description: 'Made your first comment',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.common,
      pointsRequirement: 0,
      sortOrder: 23,
    },
    {
      slug: 'engaged-member',
      name: 'Engaged Member',
      description: 'Made 50 comments',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.rare,
      pointsRequirement: 0,
      sortOrder: 24,
    },
    {
      slug: 'community-champion',
      name: 'Community Champion',
      description: 'Made 100 comments',
      imageUrl: '',
      category: BadgeCategory.engagement,
      rarity: BadgeRarity.epic,
      pointsRequirement: 0,
      sortOrder: 25,
    },

    // Social badges
    {
      slug: 'rising-star',
      name: 'Rising Star',
      description: '10 followers',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.common,
      pointsRequirement: 0,
      sortOrder: 30,
    },
    {
      slug: 'social-butterfly',
      name: 'Social Butterfly',
      description: '100 followers',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.rare,
      pointsRequirement: 0,
      sortOrder: 31,
    },
    {
      slug: 'influencer',
      name: 'Influencer',
      description: '500 followers',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.epic,
      pointsRequirement: 0,
      sortOrder: 32,
    },
    {
      slug: 'first-referral',
      name: 'Team Builder',
      description: 'Referred your first user',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.common,
      pointsRequirement: 0,
      sortOrder: 33,
    },
    {
      slug: 'recruiter',
      name: 'Recruiter',
      description: 'Referred 5 users',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.rare,
      pointsRequirement: 0,
      sortOrder: 34,
    },
    {
      slug: 'talent-scout',
      name: 'Talent Scout',
      description: 'Referred 25 users',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.epic,
      pointsRequirement: 0,
      sortOrder: 35,
    },
    {
      slug: 'network-builder',
      name: 'Network Builder',
      description: 'Referred 100 users',
      imageUrl: '',
      category: BadgeCategory.social,
      rarity: BadgeRarity.legendary,
      pointsRequirement: 0,
      sortOrder: 36,
    },
  ];

  for (const badge of badges) {
    await prisma.badge.upsert({
      where: { slug: badge.slug },
      update: badge,
      create: badge,
    });
    console.log(`✅ Badge created: ${badge.name}`);
  }

  console.log(`\n✅ Created ${badges.length} badges\n`);

  // ========== QUESTS ==========
  console.log('Creating quests...');

  const quests = [
    // Onboarding quests
    {
      slug: 'complete-profile',
      title: 'Complete Your Profile',
      description: 'Add a profile picture, username, and bio to your profile',
      type: QuestType.internal_action,
      category: BadgeCategory.engagement,
      rewardPoints: 18,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: 'profile_complete',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 1,
    },
    {
      slug: 'follow-5-projects',
      title: 'Follow 5 Projects',
      description: 'Discover and follow 5 projects that interest you',
      type: QuestType.internal_action,
      category: BadgeCategory.engagement,
      rewardPoints: 18,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: 'follow_5_projects',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 2,
    },
    {
      slug: 'make-first-comment',
      title: 'Join the Conversation',
      description: 'Make your first comment on an update',
      type: QuestType.internal_action,
      category: BadgeCategory.engagement,
      rewardPoints: 35,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: 'first_comment',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 3,
    },
    {
      slug: 'create-first-update',
      title: 'Share Your First Update',
      description: 'Create your first project update',
      type: QuestType.internal_action,
      category: BadgeCategory.engagement,
      rewardPoints: 70,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: 'first_update',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 4,
    },

    // Social media quests
    {
      slug: 'follow-on-x',
      title: 'Follow Blocnet on X',
      description: 'Follow @Blocnet on X (formerly Twitter) and submit your X username',
      type: QuestType.social_media,
      category: BadgeCategory.social,
      rewardPoints: 35,
      rewardBadgeId: null,
      targetUrl: 'https://x.com/blocnet',
      targetAction: null,
      verificationMethod: 'manual',
      requiredProof: 'Your X (Twitter) username',
      sortOrder: 10,
    },
    {
      slug: 'join-discord',
      title: 'Join Blocnet Discord',
      description: 'Join our Discord community and submit your Discord username',
      type: QuestType.social_media,
      category: BadgeCategory.social,
      rewardPoints: 35,
      rewardBadgeId: null,
      targetUrl: 'https://discord.gg/blocnet',
      targetAction: null,
      verificationMethod: 'manual',
      requiredProof: 'Your Discord username',
      sortOrder: 11,
    },
    {
      slug: 'share-on-x',
      title: 'Share Blocnet on X',
      description: 'Share a post about Blocnet on X and submit the link',
      type: QuestType.social_media,
      category: BadgeCategory.social,
      rewardPoints: 70,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: null,
      verificationMethod: 'manual',
      requiredProof: 'Link to your X post',
      sortOrder: 12,
    },

    // Mining quests
    {
      slug: '7-day-mining-streak',
      title: '7-Day Mining Streak',
      description: 'Claim mining rewards for 7 consecutive days',
      type: QuestType.internal_action,
      category: BadgeCategory.mining,
      rewardPoints: 140,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: '7_day_streak',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 20,
    },
    {
      slug: 'refer-3-miners',
      title: 'Refer 3 Active Miners',
      description: 'Refer 3 friends who start mining on Blocnet',
      type: QuestType.internal_action,
      category: BadgeCategory.mining,
      rewardPoints: 350,
      rewardBadgeId: null,
      targetUrl: null,
      targetAction: 'refer_3_miners',
      verificationMethod: 'auto',
      requiredProof: null,
      sortOrder: 21,
    },
  ];

  for (const quest of quests) {
    await prisma.quest.upsert({
      where: { slug: quest.slug },
      update: quest,
      create: quest,
    });
    console.log(`✅ Quest created: ${quest.title}`);
  }

  console.log(`\n✅ Created ${quests.length} quests\n`);

  console.log('🎉 Badges and quests seeded successfully!');
}

async function runStandalone() {
  loadEnv({ path: '.env.local', override: true, quiet: true });

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL is required for prisma seed.');
  }

  const pool = new Pool({ connectionString });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

  try {
    await seedBadgesAndQuests(prisma);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

const scriptPath = process.argv[1] ?? '';
const isDirectRun =
  scriptPath.endsWith('/prisma/seed.badges-quests.ts') ||
  scriptPath.endsWith('\\prisma\\seed.badges-quests.ts');

if (isDirectRun) {
  runStandalone().catch((e) => {
    console.error('❌ Error seeding badges and quests:', e);
    process.exit(1);
  });
}
