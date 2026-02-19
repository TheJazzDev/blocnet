import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { config as loadEnv } from 'dotenv';

loadEnv({ path: '.env.local', override: true, quiet: true });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required for prisma seed.');
}

const pool = new Pool({ connectionString });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

const primaryTags: Array<{ name: string; slug: string }> = [
  { name: 'Core', slug: 'core' },
  { name: 'Solana', slug: 'solana' },
  { name: 'Ethereum', slug: 'ethereum' },
  { name: 'Ice Open Network', slug: 'ice-open-network' },
  { name: 'Telegram Network', slug: 'telegram-network' },
  { name: 'Binance Smart Chain', slug: 'binance-smart-chain' },
];

const secondaryTags: Array<{ name: string; slug: string }> = [
  { name: 'Launching', slug: 'launching' },
  { name: 'IDO', slug: 'ido' },
  { name: 'Airdrops', slug: 'airdrops' },
  { name: 'Mining', slug: 'mining' },
  { name: 'Partnership', slug: 'partnership' },
  { name: 'Governance', slug: 'governance' },
  { name: 'Staking', slug: 'staking' },
  { name: 'Token Burn', slug: 'token-burn' },
  { name: 'Farming', slug: 'farming' },
  { name: 'NFT', slug: 'nft' },
  { name: 'Trading', slug: 'trading' },
  { name: 'ICO/IDO', slug: 'ico-ido' },
  { name: 'Gaming', slug: 'gaming' },
  { name: 'Wallet', slug: 'wallet' },
  { name: 'Security', slug: 'security' },
  { name: 'Metaverse', slug: 'metaverse' },
];

async function main() {
  for (const tag of primaryTags) {
    await prisma.primaryTag.upsert({
      where: { slug: tag.slug },
      update: { name: tag.name },
      create: { name: tag.name, slug: tag.slug },
    });
  }

  for (const tag of secondaryTags) {
    await prisma.secondaryTag.upsert({
      where: { slug: tag.slug },
      update: { name: tag.name },
      create: { name: tag.name, slug: tag.slug },
    });
  }

  const [primaryCount, secondaryCount] = await Promise.all([
    prisma.primaryTag.count(),
    prisma.secondaryTag.count(),
  ]);

  console.log(
    `[seed] completed | primaryTags=${primaryCount} secondaryTags=${secondaryCount}`,
  );
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
