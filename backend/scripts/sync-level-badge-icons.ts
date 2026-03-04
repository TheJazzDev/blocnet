import { createClient } from '@supabase/supabase-js';
import { config as loadEnv } from 'dotenv';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { Pool } from 'pg';

loadEnv({ quiet: true });
loadEnv({ path: '.env.local', override: true, quiet: true });

const databaseUrl =
  process.env.DIRECT_URL?.trim() || process.env.DATABASE_URL?.trim();

if (!databaseUrl) {
  throw new Error('DIRECT_URL or DATABASE_URL is required');
}

const pool = new Pool({
  connectionString: databaseUrl,
});

function requiredEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`${name} is required`);
  }
  return value;
}

function resolveLevelsDirectory(): string {
  const candidates = [
    join(process.cwd(), 'public', 'images', 'levels'),
    join(process.cwd(), 'backend', 'public', 'images', 'levels'),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error('Could not locate backend/public/images/levels directory');
}

function buildLevelFileMap(levelsDir: string): Map<number, string> {
  const map = new Map<number, string>();
  const entries = readdirSync(levelsDir).filter((file) =>
    /\.(svg|png|webp|jpe?g)$/i.test(file),
  );

  for (const file of entries) {
    const match = file.match(/^level-(\d+)-.+\.(svg|png|webp|jpe?g)$/i);
    if (!match) continue;
    const levelNumber = Number(match[1]);
    if (!Number.isFinite(levelNumber)) continue;
    map.set(levelNumber, join(levelsDir, file));
  }

  return map;
}

function contentTypeForFileName(fileName: string): string {
  const lower = fileName.toLowerCase();
  if (lower.endsWith('.svg')) return 'image/svg+xml';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

async function ensurePublicBucket(
  supabase: any,
  bucketName: string,
): Promise<void> {
  const { data: buckets, error: listError } = await supabase.storage.listBuckets();
  if (listError) {
    throw new Error(`Failed to list buckets: ${listError.message}`);
  }

  const exists = buckets.some((bucket) => bucket.name === bucketName);
  if (exists) return;

  const { error: createError } = await supabase.storage.createBucket(bucketName, {
    public: true,
  });

  if (createError) {
    throw new Error(`Failed to create bucket ${bucketName}: ${createError.message}`);
  }
}

async function main() {
  const supabaseUrl = requiredEnv('SUPABASE_URL').replace(/\/+$/, '');
  const supabaseKey =
    process.env.SUPABASE_SECRET_KEY?.trim() ||
    process.env.SUPABASE_SERVICE_ROLE_KEY?.trim();

  if (!supabaseKey) {
    throw new Error('SUPABASE_SECRET_KEY or SUPABASE_SERVICE_ROLE_KEY is required');
  }

  const bucketName =
    process.env.SUPABASE_LEVEL_BADGES_BUCKET?.trim() || 'level-badges';

  const supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  await ensurePublicBucket(supabase, bucketName);

  const levelsDir = resolveLevelsDirectory();
  const levelFileMap = buildLevelFileMap(levelsDir);

  const levelsResult = await pool.query<{
    id: string;
    level: number;
    name: string;
  }>('SELECT id, level, name FROM "UserLevel" ORDER BY level ASC');

  const levels = levelsResult.rows;

  if (levels.length === 0) {
    console.log('[sync-level-icons] No levels found. Nothing to sync.');
    return;
  }

  for (const level of levels) {
    const localPath = levelFileMap.get(level.level);
    if (!localPath) {
      console.warn(`[sync-level-icons] Missing SVG for level ${level.level}. Skipping.`);
      continue;
    }

    const fileName = basename(localPath);
    const objectPath = `defaults/${fileName}`;
    const fileBuffer = readFileSync(localPath);
    const contentType = contentTypeForFileName(fileName);

    const { error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(objectPath, fileBuffer, {
        contentType,
        cacheControl: '31536000',
        upsert: true,
      });

    if (uploadError) {
      throw new Error(
        `Failed to upload ${fileName} for level ${level.level}: ${uploadError.message}`,
      );
    }

    const {
      data: { publicUrl },
    } = supabase.storage.from(bucketName).getPublicUrl(objectPath);

    await pool.query(
      'UPDATE "UserLevel" SET "iconUrl" = $1, "updatedAt" = NOW() WHERE "id" = $2',
      [publicUrl, level.id],
    );

    console.log(
      `[sync-level-icons] Level ${level.level} (${level.name}) => ${publicUrl}`,
    );
  }

  console.log('[sync-level-icons] ✅ Completed syncing level badge icons.');
}

main()
  .catch((error) => {
    console.error('[sync-level-icons] ❌ Failed:', error instanceof Error ? error.message : error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
