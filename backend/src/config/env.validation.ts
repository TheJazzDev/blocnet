import * as Joi from 'joi';

const evmAddressPattern = /^0x[a-fA-F0-9]{40}$/;
const optionalString = Joi.string().allow('').optional();
const optionalUri = Joi.string().uri().allow('').optional();
const optionalAddress = Joi.string()
  .pattern(evmAddressPattern)
  .allow('')
  .optional();

const requireWhenTurnkeyReal = (
  requiredSchema: Joi.Schema,
  optionalSchema: Joi.Schema,
) =>
  Joi.when('TURNKEY_MODE', {
    switch: [
      { is: 'mock', then: optionalSchema },
      { is: 'real', then: requiredSchema },
      {
        is: 'auto',
        then: Joi.when('NODE_ENV', {
          is: 'production',
          then: requiredSchema,
          otherwise: optionalSchema,
        }),
      },
    ],
    otherwise: optionalSchema,
  });

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  PORT: Joi.number().port().default(3080),

  DATABASE_URL: Joi.string().min(1).required(),

  SUPABASE_URL: Joi.string().uri().required(),
  SUPABASE_SECRET_KEY: Joi.string().allow('').optional(),
  SUPABASE_SERVICE_ROLE_KEY: Joi.string().allow('').optional(),
  SUPABASE_AVATARS_BUCKET: Joi.string().default('avatars'),
  SUPABASE_QUEST_PROOFS_BUCKET: Joi.string().default('quest-proofs'),
  PUBLISHABLE_KEY: Joi.string().allow('').optional(),
  SUPABASE_JWKS_URL: Joi.string().uri().allow('').empty('').optional(),
  SUPABASE_JWT_SECRET: Joi.string().min(1).allow('').empty('').optional(),

  FIREBASE_PROJECT_ID: Joi.string().allow('').optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().allow('').optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().allow('').optional(),
  RESEND_API_KEY: Joi.string().allow('').optional(),
  EMAIL_FROM_ADDRESS: Joi.string().allow('').optional(),
  FROM_EMAIL: Joi.string().allow('').optional(),
  EMAIL_REPLY_TO: Joi.string().allow('').optional(),

  OWNER_USER_ID: Joi.string().min(1).optional(),
  OWNER_EMAIL: Joi.string()
    .email({ tlds: { allow: false } })
    .optional(),

  ENABLE_ALPHA_RADAR: Joi.boolean().default(true),
  ENABLE_BEE: Joi.boolean().default(true),
  ENABLE_FOLLOW_PREFS: Joi.boolean().default(true),
  ENABLE_EVENT_NOTIFICATIONS: Joi.boolean().default(true),
  ENABLE_WEEKLY_DIGEST: Joi.boolean().default(true),
  NOTIFICATION_DIGEST_ENABLED: Joi.boolean().default(true),
  NOTIFICATION_DIGEST_SEND_WINDOW_MINUTES: Joi.number()
    .integer()
    .min(1)
    .max(60)
    .default(10),
  NOTIFICATION_DIGEST_BATCH_SIZE: Joi.number()
    .integer()
    .min(10)
    .max(1000)
    .default(200),
  ENABLE_MINING: Joi.boolean().default(true),
  ENABLE_REFERRALS: Joi.boolean().default(true),

  WALLET_ENABLED: Joi.boolean().default(false),
  DEPOSITS_ENABLED: Joi.boolean().default(false),
  WITHDRAWALS_ENABLED: Joi.boolean().default(false),
  WALLET_CHAIN_ENVIRONMENT: Joi.string()
    .valid('testnet', 'mainnet')
    .allow('')
    .optional(),
  WALLET_ASSET_BNT_ENABLED: Joi.boolean().default(true),
  WALLET_ASSET_BNB_ENABLED: Joi.boolean().default(true),
  WALLET_ASSET_USDT_ENABLED: Joi.boolean().default(true),
  WALLET_WITHDRAWAL_ASSETS: Joi.string()
    .pattern(/^[A-Za-z,\s]*$/)
    .allow('')
    .optional(),
  TURNKEY_MODE: Joi.string().valid('auto', 'mock', 'real').default('auto'),
  // Deprecated: use TURNKEY_MODE instead.
  TURNKEY_DEV_MOCK: Joi.boolean().optional(),
  WALLET_DEPOSIT_POLL_INTERVAL_MS: Joi.number()
    .integer()
    .min(1000)
    .default(15000),
  WALLET_DEPOSIT_REALTIME_ENABLED: Joi.boolean().default(true),
  WALLET_DEPOSIT_BLOCK_CHUNK_SIZE: Joi.number().integer().min(50).default(1000),
  WALLET_DEPOSIT_ADDRESS_CHUNK_SIZE: Joi.number()
    .integer()
    .min(10)
    .default(100),
  WALLET_DEPOSIT_MAX_RANGE_PER_TICK: Joi.number()
    .integer()
    .min(100)
    .default(5000),
  WALLET_DEPOSIT_INITIAL_LOOKBACK_BLOCKS: Joi.number()
    .integer()
    .min(100)
    .default(2000),
  WALLET_DEPOSIT_CONFIRMATIONS: Joi.number().integer().min(1).optional(),
  WALLET_WITHDRAWAL_POLL_INTERVAL_MS: Joi.number()
    .integer()
    .min(1000)
    .default(15000),
  WALLET_WITHDRAWAL_CONFIRMATIONS: Joi.number().integer().min(1).optional(),
  WALLET_DEPOSIT_START_BLOCK: Joi.number()
    .integer()
    .min(0)
    .allow(null)
    .empty('')
    .optional(),

  BSC_RPC_URL: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(Joi.string().uri().required(), optionalUri),
    otherwise: optionalUri,
  }),
  BSC_RPC_WS_URL: optionalUri,
  BSC_CHAIN_ID: Joi.number().integer().min(1).optional(),

  TURNKEY_BASE_URL: Joi.string().uri().default('https://api.turnkey.com'),
  TURNKEY_ORGANIZATION_ID: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(
      Joi.string().min(1).required(),
      optionalString,
    ),
    otherwise: optionalString,
  }),
  TURNKEY_API_PUBLIC_KEY: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(
      Joi.string().min(1).required(),
      optionalString,
    ),
    otherwise: optionalString,
  }),
  TURNKEY_API_PRIVATE_KEY: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(
      Joi.string().min(1).required(),
      optionalString,
    ),
    otherwise: optionalString,
  }),
  TURNKEY_API_KEY_ID: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(
      Joi.string().min(1).required(),
      optionalString,
    ),
    otherwise: optionalString,
  }),

  BNT_TOKEN_ADDRESS: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('WALLET_ASSET_BNT_ENABLED', {
      is: true,
      then: requireWhenTurnkeyReal(
        Joi.string().pattern(evmAddressPattern).required(),
        optionalAddress,
      ),
      otherwise: optionalAddress,
    }),
    otherwise: optionalAddress,
  }),
  USDT_TOKEN_ADDRESS: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('WALLET_ASSET_USDT_ENABLED', {
      is: true,
      then: requireWhenTurnkeyReal(
        Joi.string().pattern(evmAddressPattern).required(),
        optionalAddress,
      ),
      otherwise: optionalAddress,
    }),
    otherwise: optionalAddress,
  }),
  TREASURY_ADDRESS: optionalAddress,
  TREASURY_WALLET_ID: Joi.when('WALLET_ENABLED', {
    is: true,
    then: requireWhenTurnkeyReal(
      Joi.string().min(1).required(),
      optionalString,
    ),
    otherwise: optionalString,
  }),
}).or('SUPABASE_JWKS_URL', 'SUPABASE_JWT_SECRET');
