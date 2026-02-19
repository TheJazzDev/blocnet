import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { config as loadEnv } from 'dotenv';
import { Pool } from 'pg';
import {
  backfillWalletDomainForUsers,
  parseBooleanEnv,
  resolveWalletChainEnvironment,
  resolveWalletChainId,
} from './wallet-seed.util';

loadEnv({ path: '.env.local', override: true, quiet: true });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required for wallet backfill seed.');
}

const pool = new Pool({ connectionString });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

async function main() {
  const profiles = await prisma.profile.findMany({
    select: { id: true },
  });

  const chainEnvironment = resolveWalletChainEnvironment(
    process.env.WALLET_CHAIN_ENVIRONMENT,
  );
  const chainId = resolveWalletChainId(chainEnvironment, process.env);
  const walletEnabled = parseBooleanEnv(process.env.WALLET_ENABLED, false);

  // Dev backfill defaults to ready mock wallets so the mobile wallet screen
  // is immediately usable for already-registered users.
  const forceReadyMock = parseBooleanEnv(
    process.env.WALLET_SEED_READY_MOCK,
    process.env.NODE_ENV !== 'production',
  );

  const result = await backfillWalletDomainForUsers(
    prisma,
    profiles.map((profile) => profile.id),
    {
      chainEnvironment,
      chainId,
      walletEnabled,
      forceReadyMock: walletEnabled && forceReadyMock,
    },
  );

  console.log(
    `[seed:wallets] completed | users=${result.processedUsers} walletsCreated=${result.walletsCreated} walletsUpdated=${result.walletsUpdated} kycCreated=${result.kycProfilesCreated} userAccounts=${result.userAccountsEnsured} holdAccounts=${result.holdAccountsEnsured}`,
  );
}

main()
  .catch((error) => {
    console.error('[seed:wallets] Failed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
