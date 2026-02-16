import * as Joi from 'joi';

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'test', 'production')
    .default('development'),
  PORT: Joi.number().port().default(3080),

  DATABASE_URL: Joi.string().min(1).required(),

  SUPABASE_URL: Joi.string().uri().required(),
  SUPABASE_ANON_KEY: Joi.string().allow('').optional(),
  SUPABASE_JWKS_URL: Joi.string().uri().allow('').empty('').optional(),
  SUPABASE_JWT_SECRET: Joi.string().min(1).allow('').empty('').optional(),

  FIREBASE_PROJECT_ID: Joi.string().allow('').optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().allow('').optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().allow('').optional(),

  OWNER_USER_ID: Joi.string().min(1).optional(),
  OWNER_EMAIL: Joi.string().email({ tlds: { allow: false } }).optional(),
}).or('SUPABASE_JWKS_URL', 'SUPABASE_JWT_SECRET');
