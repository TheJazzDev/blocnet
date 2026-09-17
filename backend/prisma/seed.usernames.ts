/**
 * Gives every seeded dev profile a username without touching anything else.
 * Safe to re-run: profiles that already have a username are left alone, and
 * profiles that do not exist are skipped (this never creates one).
 *
 *   bun run prisma:seed:usernames
 */
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { config as loadEnv } from 'dotenv';
import { Pool } from 'pg';
import { buildSeedDevUsers } from './seed-dev-users';
import { ensureSeedUsername } from './seed-username.util';

loadEnv({ path: '.env.local', override: true, quiet: true });

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is required for the username backfill.');
}

const pool = new Pool({ connectionString });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

async function main() {
  for (const user of buildSeedDevUsers(process.env)) {
    const username = await ensureSeedUsername(prisma, user.id, user.username);
    console.log(
      `[seed:usernames] ${user.displayName}: ${username ?? '(no profile, skipped)'}`,
    );
  }
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
