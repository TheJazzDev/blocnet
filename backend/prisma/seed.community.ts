/**
 * Puts a handful of community posts and replies on the dev database so the
 * Community tab has something to show. Safe to re-run: rows use fixed ids and
 * are upserted; authors that do not exist are skipped.
 *
 *   bun run prisma:seed:community
 */
import { PrismaPg } from '@prisma/adapter-pg';
import { CommunityTopic, PrismaClient } from '@prisma/client';
import { config as loadEnv } from 'dotenv';
import { Pool } from 'pg';
import { buildSeedDevUsers, type SeedUserKey } from './seed-dev-users';

loadEnv({ path: '.env.local', override: true, quiet: true });

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for the community seed.');
}

const pool = new Pool({ connectionString });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

type SeedPost = {
  id: string;
  author: SeedUserKey;
  topic: CommunityTopic;
  hoursAgo: number;
  content: string;
  replies: {
    id: string;
    author: SeedUserKey;
    hoursAgo: number;
    content: string;
  }[];
};

const posts: SeedPost[] = [
  {
    id: '5e1d0c7a-0001-4c3e-9a51-6c0b1d000001',
    author: 'hunterSage',
    topic: CommunityTopic.general,
    hoursAgo: 3,
    content:
      'Ethereum Watch now posts a weekly recap every Monday. Ask on the gem page if you want something covered.',
    replies: [
      {
        id: '5e1d0c7a-0101-4c3e-9a51-6c0b1d000001',
        author: 'memberRae',
        hoursAgo: 2,
        content: 'Thanks. Could the next one cover the L2 fee changes?',
      },
      {
        id: '5e1d0c7a-0102-4c3e-9a51-6c0b1d000001',
        author: 'hunterSage',
        hoursAgo: 1,
        content: 'Yes, added to Monday.',
      },
    ],
  },
  {
    id: '5e1d0c7a-0002-4c3e-9a51-6c0b1d000002',
    author: 'memberKai',
    topic: CommunityTopic.general,
    hoursAgo: 20,
    content:
      'First week on Blocnet. Following 4 gems so far. Which hunters do you rely on most?',
    replies: [
      {
        id: '5e1d0c7a-0201-4c3e-9a51-6c0b1d000002',
        author: 'memberMila',
        hoursAgo: 18,
        content:
          'Check Gems › Hunters. I sort by who keeps their gems current.',
      },
    ],
  },
  {
    id: '5e1d0c7a-0003-4c3e-9a51-6c0b1d000003',
    author: 'adminDelta',
    topic: CommunityTopic.general,
    hoursAgo: 48,
    content:
      'Reminder: report a gem as inactive from its page if the hunter goes quiet. Moderators review every report.',
    replies: [],
  },
  {
    id: '5e1d0c7a-0004-4c3e-9a51-6c0b1d000004',
    author: 'memberMila',
    topic: CommunityTopic.market_talk,
    hoursAgo: 5,
    content:
      'BSC launchpad KYC closes this week. Anyone else still waiting on verification?',
    replies: [
      {
        id: '5e1d0c7a-0401-4c3e-9a51-6c0b1d000004',
        author: 'memberKai',
        hoursAgo: 4,
        content: 'Mine went through in about 6 hours.',
      },
    ],
  },
  {
    id: '5e1d0c7a-0005-4c3e-9a51-6c0b1d000005',
    author: 'hunterNexa',
    topic: CommunityTopic.market_talk,
    hoursAgo: 30,
    content:
      'Staking rewards on Solana Radar changed again. Full checklist is on the gem.',
    replies: [],
  },
];

const hoursAgo = (hours: number) => new Date(Date.now() - hours * 3_600_000);

async function main() {
  const users = new Map(
    buildSeedDevUsers(process.env).map((u) => [u.key, u.id]),
  );
  const existing = new Set(
    (
      await prisma.profile.findMany({
        where: { id: { in: [...users.values()] } },
        select: { id: true },
      })
    ).map((p) => p.id),
  );
  const authorId = (key: SeedUserKey) => {
    const id = users.get(key);
    return id && existing.has(id) ? id : null;
  };

  let postCount = 0;
  let replyCount = 0;
  for (const post of posts) {
    const author = authorId(post.author);
    if (!author) continue;
    await prisma.communityPost.upsert({
      where: { id: post.id },
      update: {},
      create: {
        id: post.id,
        authorId: author,
        topic: post.topic,
        content: post.content,
        createdAt: hoursAgo(post.hoursAgo),
      },
    });
    postCount++;
    for (const reply of post.replies) {
      const replyAuthor = authorId(reply.author);
      if (!replyAuthor) continue;
      await prisma.communityPostComment.upsert({
        where: { id: reply.id },
        update: {},
        create: {
          id: reply.id,
          postId: post.id,
          authorId: replyAuthor,
          content: reply.content,
          createdAt: hoursAgo(reply.hoursAgo),
        },
      });
      replyCount++;
    }
  }
  console.log(`[seed:community] ${postCount} posts, ${replyCount} replies`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
