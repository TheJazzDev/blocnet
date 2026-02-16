import { config as loadEnv } from 'dotenv';
import { defineConfig } from 'prisma/config';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

loadEnv({ quiet: true });
loadEnv({ path: '.env.local', override: true, quiet: true });

const fallbackEnvPath = join(process.cwd(), 'backend/.env.local');
if (existsSync(fallbackEnvPath)) {
  loadEnv({ path: fallbackEnvPath, override: true, quiet: true });
}

const datasourceUrl = process.env.DIRECT_URL ?? process.env.DATABASE_URL;

if (!datasourceUrl) {
  throw new Error('DIRECT_URL or DATABASE_URL must be set for Prisma CLI.');
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    url: datasourceUrl,
  },
});
