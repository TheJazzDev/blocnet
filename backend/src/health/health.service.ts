import { Injectable } from '@nestjs/common';
import { DatabaseHealthService } from '../prisma/database-health.service';

@Injectable()
export class HealthService {
  constructor(private readonly databaseHealthService: DatabaseHealthService) {}

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

  async getReadiness() {
    const database = await this.databaseHealthService.getSnapshot({
      force: true,
    });
    const checks = {
      database: {
        configured: Boolean(process.env.DATABASE_URL),
        healthy: database.healthy,
        checkedAt: database.checkedAt,
        lastError: database.lastError,
      },
      supabaseAuthConfigured: Boolean(process.env.SUPABASE_JWKS_URL),
    };

    return {
      ...this.getHealth(),
      status: database.healthy ? 'ok' : 'degraded',
      checks,
    };
  }
}
