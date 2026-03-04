import { Pool } from 'pg';
import { config as loadEnv } from 'dotenv';
import { readFileSync } from 'fs';
import { join } from 'path';

loadEnv({ path: '.env.local', override: false, quiet: true });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is required');
}

async function applyMigration() {
  const pool = new Pool({ connectionString });

  try {
    const migrationSQL = readFileSync(
      join(__dirname, '../prisma/migrations/20260303120000_add_user_level_system/migration.sql'),
      'utf-8'
    );

    console.log('[migration] Applying user level system migration...');
    await pool.query(migrationSQL);
    console.log('[migration] ✅ Migration applied successfully');
  } catch (error) {
    console.error('[migration] ❌ Migration failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

applyMigration()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
