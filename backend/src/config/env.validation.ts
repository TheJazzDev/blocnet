import * as Joi from 'joi';

const evmAddressPattern = /^0x[a-fA-F0-9]{40}$/;

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  PORT: Joi.number().port().default(3080),

  DATABASE_URL: Joi.string().min(1).required(),

  SUPABASE_URL: Joi.string().uri().required(),
  PUBLISHABLE_KEY: Joi.string().allow('').optional(),
  SUPABASE_JWKS_URL: Joi.string().uri().allow('').empty('').optional(),
  SUPABASE_JWT_SECRET: Joi.string().min(1).allow('').empty('').optional(),

  FIREBASE_PROJECT_ID: Joi.string().allow('').optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().allow('').optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().allow('').optional(),

  OWNER_USER_ID: Joi.string().min(1).optional(),
  OWNER_EMAIL: Joi.string()
    .email({ tlds: { allow: false } })
    .optional(),

  WALLET_ENABLED: Joi.boolean().default(false),
  DEPOSITS_ENABLED: Joi.boolean().default(false),
  WITHDRAWALS_ENABLED: Joi.boolean().default(false),

  BSC_RPC_TESTNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().uri().required(),
      otherwise: Joi.string().uri().allow('').optional(),
    }),
    otherwise: Joi.string().uri().allow('').optional(),
  }),
  BSC_RPC_MAINNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().uri().required(),
      otherwise: Joi.string().uri().allow('').optional(),
    }),
    otherwise: Joi.string().uri().allow('').optional(),
  }),
  BSC_CHAIN_ID_TESTNET: Joi.number().valid(97).default(97),
  BSC_CHAIN_ID_MAINNET: Joi.number().valid(56).default(56),

  TURNKEY_BASE_URL: Joi.string().uri().default('https://api.turnkey.com'),
  TURNKEY_DEV_MOCK: Joi.boolean().default(false),
  TURNKEY_ORGANIZATION_ID: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),
  TURNKEY_API_PUBLIC_KEY: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),
  TURNKEY_API_PRIVATE_KEY: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),
  TURNKEY_PRIVATE_KEY_ID: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),

  BNT_TOKEN_ADDRESS_TESTNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().pattern(evmAddressPattern).required(),
      otherwise: Joi.string().pattern(evmAddressPattern).allow('').optional(),
    }),
    otherwise: Joi.string().pattern(evmAddressPattern).allow('').optional(),
  }),
  BNT_TOKEN_ADDRESS_MAINNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().pattern(evmAddressPattern).required(),
      otherwise: Joi.string().pattern(evmAddressPattern).allow('').optional(),
    }),
    otherwise: Joi.string().pattern(evmAddressPattern).allow('').optional(),
  }),
  TREASURY_WALLET_ID_TESTNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),
  TREASURY_WALLET_ID_MAINNET: Joi.when('WALLET_ENABLED', {
    is: true,
    then: Joi.when('NODE_ENV', {
      is: 'production',
      then: Joi.string().min(1).required(),
      otherwise: Joi.string().allow('').optional(),
    }),
    otherwise: Joi.string().allow('').optional(),
  }),
}).or('SUPABASE_JWKS_URL', 'SUPABASE_JWT_SECRET');
