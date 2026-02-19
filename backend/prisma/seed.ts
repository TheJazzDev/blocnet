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

const riskLimits: Array<{
  tier: string;
  description: string;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
}> = [
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
];

const defaultWalletFeeConfig = {
  key: 'withdrawal_bnt_v1',
  flatFee: '1',
  percentFee: '0',
  minFee: '1',
  maxFee: null as string | null,
  isActive: true,
};

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

  await prisma.walletFeeConfig.upsert({
    where: { key: defaultWalletFeeConfig.key },
    update: {
      flatFee: defaultWalletFeeConfig.flatFee,
      percentFee: defaultWalletFeeConfig.percentFee,
      minFee: defaultWalletFeeConfig.minFee,
      maxFee: defaultWalletFeeConfig.maxFee,
      isActive: defaultWalletFeeConfig.isActive,
    },
    create: {
      key: defaultWalletFeeConfig.key,
      flatFee: defaultWalletFeeConfig.flatFee,
      percentFee: defaultWalletFeeConfig.percentFee,
      minFee: defaultWalletFeeConfig.minFee,
      maxFee: defaultWalletFeeConfig.maxFee,
      isActive: defaultWalletFeeConfig.isActive,
    },
  });

  const [primaryCount, secondaryCount, riskCount] = await Promise.all([
    prisma.primaryTag.count(),
    prisma.secondaryTag.count(),
    prisma.riskLimit.count(),
  ]);

  console.log(
    `[seed] completed | primaryTags=${primaryCount} secondaryTags=${secondaryCount} riskLimits=${riskCount}`,
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
