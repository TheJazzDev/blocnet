import { Injectable } from '@nestjs/common';

@Injectable()
export class HealthService {
  getHealth() {
    return {
      status: 'ok',
      service: 'blocnet-backend',
      uptimeSeconds: Math.floor(process.uptime()),
      environment: process.env.NODE_ENV ?? 'development',
      version: process.env.APP_VERSION ?? 'dev',
      timestamp: new Date().toISOString(),
    };
  }

  getLiveness() {
    return this.getHealth();
  }

  getReadiness() {
    const checks = {
      databaseUrlConfigured: Boolean(process.env.DATABASE_URL),
      supabaseAuthConfigured: Boolean(process.env.SUPABASE_JWKS_URL),
    };

    return {
      ...this.getHealth(),
      checks,
    };
  }
}
