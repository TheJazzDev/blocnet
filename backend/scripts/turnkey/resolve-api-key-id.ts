import { existsSync } from 'fs';
import { resolve } from 'path';
import { ApiKeyStamper } from '@turnkey/api-key-stamper';
import { TurnkeyClient } from '@turnkey/http';
import { config as loadDotenv } from 'dotenv';

function loadEnvFiles() {
  const cwd = process.cwd();
  const files =
    process.env.NODE_ENV === 'production'
      ? ['.env', '.env.prod', '.env.prod.local']
      : ['.env', '.env.local', '.env.development', '.env.development.local'];

  for (const file of files) {
    const fullPath = resolve(cwd, file);
    if (existsSync(fullPath)) {
      loadDotenv({ path: fullPath, override: true });
    }
  }
}

function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required env var: ${name}`);
  }
  return value;
}

function normalizeKey(value: string): string {
  return value.replace(/^0x/i, '').toLowerCase();
}

async function main() {
  loadEnvFiles();

  const organizationId = requireEnv('TURNKEY_ORGANIZATION_ID');
  const apiPublicKey = requireEnv('TURNKEY_API_PUBLIC_KEY');
  const apiPrivateKey = requireEnv('TURNKEY_API_PRIVATE_KEY');
  const baseUrl =
    process.env.TURNKEY_BASE_URL?.trim() || 'https://api.turnkey.com';

  const matchPublicKey =
    process.env.MATCH_TURNKEY_API_PUBLIC_KEY?.trim() || apiPublicKey;

  const client = new TurnkeyClient(
    { baseUrl },
    new ApiKeyStamper({
      apiPublicKey,
      apiPrivateKey,
    }),
  );

  const whoami = await client.getWhoami({ organizationId });
  const apiKeysResponse = await client.getApiKeys({
    organizationId,
    userId: whoami.userId,
  });

  const matchedKey = apiKeysResponse.apiKeys.find(
    (key) =>
      normalizeKey(key.credential.publicKey) === normalizeKey(matchPublicKey),
  );

  if (!matchedKey) {
    console.error('No API key matched MATCH_TURNKEY_API_PUBLIC_KEY.');
    console.error(
      'Available API keys for the current user (apiKeyName -> apiKeyId -> publicKey):',
    );
    for (const key of apiKeysResponse.apiKeys) {
      console.error(
        `${key.apiKeyName} -> ${key.apiKeyId} -> ${key.credential.publicKey}`,
      );
    }
    process.exit(1);
  }

  console.log(`TURNKEY_API_KEY_ID=${matchedKey.apiKeyId}`);
  console.log(`Matched key name: ${matchedKey.apiKeyName}`);
  console.log(`Matched userId: ${whoami.userId}`);
  console.log(`Matched organizationId: ${whoami.organizationId}`);
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Failed to resolve Turnkey API key ID: ${message}`);
  process.exit(1);
});
