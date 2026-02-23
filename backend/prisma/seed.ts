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

const defaultWalletFeeConfigs = [
  {
    key: 'withdrawal_bnt_v1',
    flatFee: '1',
    percentFee: '0',
    minFee: '1',
    maxFee: null as string | null,
    isActive: true,
  },
  {
    key: 'withdrawal_bnb_v1',
    flatFee: '0.0008',
    percentFee: '0',
    minFee: '0.0008',
    maxFee: null as string | null,
    isActive: true,
  },
  {
    key: 'withdrawal_usdt_v1',
    flatFee: '0.5',
    percentFee: '0',
    minFee: '0.5',
    maxFee: null as string | null,
    isActive: true,
  },
] as const;

const defaultAssetPriceConfigs = [
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

const defaultTipCurrencies = [
  {
    code: 'MCR',
    name: 'Mine Credits',
    symbol: 'MCR',
    decimals: 3,
    kind: 'points' as const,
    isEnabled: true,
    isActiveTippingCurrency: true,
    feeBps: 500,
    minTipAtomic: 1n,
    minFeeAtomic: 0n,
    senderPaysFee: true,
  },
  {
    code: 'BNT',
    name: 'BlocNet Token',
    symbol: 'BNT',
    decimals: 18,
    kind: 'token' as const,
    isEnabled: true,
    isActiveTippingCurrency: false,
    feeBps: 500,
    minTipAtomic: 1000000000000000n,
    minFeeAtomic: 0n,
    senderPaysFee: true,
  },
] as const;

async function main() {
  await prisma.miningConfig.upsert({
    where: { id: 'default' },
    update: {
      enabled: true,
      referralsEnabled: true,
      cycleHours: 24,
      basePointsPerCycle: 120,
      perActiveReferralBoostBps: 500,
      maxBoostBps: 10000,
      activeReferralWindowHours: 168,
      referralBindWindowHours: 24,
    },
    create: {
      id: 'default',
      enabled: true,
      referralsEnabled: true,
      cycleHours: 24,
      basePointsPerCycle: 120,
      perActiveReferralBoostBps: 500,
      maxBoostBps: 10000,
      activeReferralWindowHours: 168,
      referralBindWindowHours: 24,
    },
  });

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

  for (const feeConfig of defaultWalletFeeConfigs) {
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

  for (const priceConfig of defaultAssetPriceConfigs) {
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

  for (const currency of defaultTipCurrencies) {
    await prisma.tipCurrency.upsert({
      where: { code: currency.code },
      update: {
        name: currency.name,
        symbol: currency.symbol,
        decimals: currency.decimals,
        kind: currency.kind,
        isEnabled: currency.isEnabled,
        isActiveTippingCurrency: currency.isActiveTippingCurrency,
      },
      create: {
        code: currency.code,
        name: currency.name,
        symbol: currency.symbol,
        decimals: currency.decimals,
        kind: currency.kind,
        isEnabled: currency.isEnabled,
        isActiveTippingCurrency: currency.isActiveTippingCurrency,
      },
    });

    await prisma.tipFeeConfig.upsert({
      where: { currencyCode: currency.code },
      update: {
        feeBps: currency.feeBps,
        minTipAtomic: currency.minTipAtomic,
        minFeeAtomic: currency.minFeeAtomic,
        senderPaysFee: currency.senderPaysFee,
        isActive: true,
      },
      create: {
        currencyCode: currency.code,
        feeBps: currency.feeBps,
        minTipAtomic: currency.minTipAtomic,
        minFeeAtomic: currency.minFeeAtomic,
        senderPaysFee: currency.senderPaysFee,
        isActive: true,
      },
    });

    await prisma.tipAccount.upsert({
      where: {
        accountType_ownerRef_currencyCode: {
          accountType: 'fee_vault',
          ownerRef: 'FEE_VAULT',
          currencyCode: currency.code,
        },
      },
      update: {},
      create: {
        accountType: 'fee_vault',
        ownerRef: 'FEE_VAULT',
        currencyCode: currency.code,
        balanceAtomic: 0n,
      },
    });
  }

  await prisma.tipCurrency.updateMany({
    where: {},
    data: {
      isActiveTippingCurrency: false,
    },
  });

  await prisma.tipCurrency.update({
    where: { code: 'MCR' },
    data: { isActiveTippingCurrency: true },
  });

  const [primaryCount, secondaryCount, riskCount, miningConfigCount, tipCurrencyCount] =
    await Promise.all([
      prisma.primaryTag.count(),
      prisma.secondaryTag.count(),
      prisma.riskLimit.count(),
      prisma.miningConfig.count(),
      prisma.tipCurrency.count(),
    ]);

  console.log(
    `[seed] completed | primaryTags=${primaryCount} secondaryTags=${secondaryCount} riskLimits=${riskCount} miningConfigs=${miningConfigCount} tipCurrencies=${tipCurrencyCount}`,
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
