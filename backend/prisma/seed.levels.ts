import { PrismaClient } from '@prisma/client';

export interface LevelConfig {
  level: number;
  slug: string;
  name: string;
  description: string;
  iconUrl: string;
  requiredBnp: string;
  requiredComments: number;
  requiredDaysActive: number;
  requiredQuests: number;
  requiredUpdates: number;
  requiredProjects: number;
  color: string;
  sortOrder: number;
}

// 15-Level progression system for Blocnet
const levels: LevelConfig[] = [
  // Tier 1-3: Newcomer Stage
  {
    level: 1,
    slug: 'newcomer',
    name: 'Newcomer',
    description: 'Welcome to the Blocnet community! Start your journey here.',
    iconUrl: '',
    requiredBnp: '0',
    requiredComments: 0,
    requiredDaysActive: 0,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#9CA3AF', // Gray
    sortOrder: 1,
  },
  {
    level: 2,
    slug: 'explorer',
    name: 'Explorer',
    description: 'You\'re exploring the Blocnet ecosystem. Keep going!',
    iconUrl: '',
    requiredBnp: '500',
    requiredComments: 0,
    requiredDaysActive: 3,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#60A5FA', // Blue
    sortOrder: 2,
  },
  {
    level: 3,
    slug: 'pathfinder',
    name: 'Pathfinder',
    description: 'You\'re carving your path through the Blocnet ecosystem.',
    iconUrl: '',
    requiredBnp: '2000',
    requiredComments: 5,
    requiredDaysActive: 7,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#34D399', // Green
    sortOrder: 3,
  },

  // Tier 4-6: Active Member Stage
  {
    level: 4,
    slug: 'contributor',
    name: 'Contributor',
    description: 'Your contributions are making a difference in the community.',
    iconUrl: '',
    requiredBnp: '5000',
    requiredComments: 20,
    requiredDaysActive: 14,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#10B981', // Emerald
    sortOrder: 4,
  },
  {
    level: 5,
    slug: 'builder',
    name: 'Builder',
    description: 'You\'re building the future of crypto updates with us!',
    iconUrl: '',
    requiredBnp: '10000',
    requiredComments: 50,
    requiredDaysActive: 30,
    requiredQuests: 2,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#14B8A6', // Teal
    sortOrder: 5,
  },
  {
    level: 6,
    slug: 'advocate',
    name: 'Advocate',
    description: 'A true advocate spreading the Blocnet vision.',
    iconUrl: '',
    requiredBnp: '25000',
    requiredComments: 100,
    requiredDaysActive: 60,
    requiredQuests: 5,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#06B6D4', // Cyan
    sortOrder: 6,
  },

  // Tier 7-9: Veteran Stage
  {
    level: 7,
    slug: 'veteran',
    name: 'Veteran',
    description: 'A seasoned veteran with extensive community knowledge.',
    iconUrl: '',
    requiredBnp: '50000',
    requiredComments: 200,
    requiredDaysActive: 90,
    requiredQuests: 10,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#8B5CF6', // Purple
    sortOrder: 7,
  },
  {
    level: 8,
    slug: 'champion',
    name: 'Champion',
    description: 'A champion of the Blocnet community!',
    iconUrl: '',
    requiredBnp: '100000',
    requiredComments: 350,
    requiredDaysActive: 120,
    requiredQuests: 15,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#A855F7', // Purple-500
    sortOrder: 8,
  },
  {
    level: 9,
    slug: 'elite',
    name: 'Elite',
    description: 'Part of the elite circle of dedicated Blocnetters.',
    iconUrl: '',
    requiredBnp: '200000',
    requiredComments: 500,
    requiredDaysActive: 180,
    requiredQuests: 20,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#C084FC', // Purple-400
    sortOrder: 9,
  },

  // Tier 10-12: Expert Stage
  {
    level: 10,
    slug: 'expert',
    name: 'Expert',
    description: 'An expert with deep knowledge of the crypto ecosystem.',
    iconUrl: '',
    requiredBnp: '400000',
    requiredComments: 750,
    requiredDaysActive: 240,
    requiredQuests: 25,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#F59E0B', // Amber
    sortOrder: 10,
  },
  {
    level: 11,
    slug: 'guardian',
    name: 'Guardian',
    description: 'A guardian protecting and growing the community.',
    iconUrl: '',
    requiredBnp: '750000',
    requiredComments: 1000,
    requiredDaysActive: 300,
    requiredQuests: 30,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#F59E0B', // Amber-500
    sortOrder: 11,
  },
  {
    level: 12,
    slug: 'master',
    name: 'Master',
    description: 'A master of the Blocnet platform.',
    iconUrl: '',
    requiredBnp: '1500000',
    requiredComments: 1500,
    requiredDaysActive: 365,
    requiredQuests: 35,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#FB923C', // Orange-400
    sortOrder: 12,
  },

  // Tier 13-15: Legendary Stage
  {
    level: 13,
    slug: 'legend',
    name: 'Legend',
    description: 'A legendary figure in the Blocnet history.',
    iconUrl: '',
    requiredBnp: '3000000',
    requiredComments: 2500,
    requiredDaysActive: 500,
    requiredQuests: 40,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#EF4444', // Red
    sortOrder: 13,
  },
  {
    level: 14,
    slug: 'titan',
    name: 'Titan',
    description: 'A titan among Blocnetters. Truly exceptional!',
    iconUrl: '',
    requiredBnp: '6000000',
    requiredComments: 5000,
    requiredDaysActive: 730,
    requiredQuests: 45,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#DC2626', // Red-600
    sortOrder: 14,
  },
  {
    level: 15,
    slug: 'pioneer',
    name: 'Pioneer',
    description: 'A true pioneer who helped shape Blocnet from the beginning.',
    iconUrl: '',
    requiredBnp: '10000000',
    requiredComments: 10000,
    requiredDaysActive: 1000,
    requiredQuests: 50,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: '#7C2D12', // Red-900 (gold/bronze feel)
    sortOrder: 15,
  },
];

function resolveSeedLevelIconUrl(iconUrl: string): string {
  if (!iconUrl.startsWith('/images/levels/')) {
    return iconUrl;
  }

  const supabaseUrl = process.env.SUPABASE_URL?.trim();
  if (!supabaseUrl) {
    return iconUrl;
  }

  const bucketName =
    process.env.SUPABASE_LEVEL_BADGES_BUCKET?.trim() || 'level-badges';
  const fileName = iconUrl.split('/').pop();
  if (!fileName) {
    return iconUrl;
  }

  return `${supabaseUrl.replace(/\/+$/, '')}/storage/v1/object/public/${bucketName}/defaults/${fileName}`;
}

export async function seedLevels(prisma: PrismaClient) {
  console.log('[seed.levels] Seeding user levels...');

  for (const levelConfig of levels) {
    const iconUrl = resolveSeedLevelIconUrl(levelConfig.iconUrl);

    await prisma.userLevel.upsert({
      where: { slug: levelConfig.slug },
      update: {
        name: levelConfig.name,
        description: levelConfig.description,
        iconUrl,
        level: levelConfig.level,
        requiredBnp: BigInt(levelConfig.requiredBnp),
        requiredComments: levelConfig.requiredComments,
        requiredDaysActive: levelConfig.requiredDaysActive,
        requiredQuests: levelConfig.requiredQuests,
        requiredUpdates: levelConfig.requiredUpdates,
        requiredProjects: levelConfig.requiredProjects,
        color: levelConfig.color,
        sortOrder: levelConfig.sortOrder,
        isActive: true,
      },
      create: {
        slug: levelConfig.slug,
        name: levelConfig.name,
        description: levelConfig.description,
        iconUrl,
        level: levelConfig.level,
        requiredBnp: BigInt(levelConfig.requiredBnp),
        requiredComments: levelConfig.requiredComments,
        requiredDaysActive: levelConfig.requiredDaysActive,
        requiredQuests: levelConfig.requiredQuests,
        requiredUpdates: levelConfig.requiredUpdates,
        requiredProjects: levelConfig.requiredProjects,
        color: levelConfig.color,
        sortOrder: levelConfig.sortOrder,
        isActive: true,
      },
    });
  }

  const levelCount = await prisma.userLevel.count();
  console.log(`[seed.levels] ✅ Seeded ${levelCount} user levels`);
}
