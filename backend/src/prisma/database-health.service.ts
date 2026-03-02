import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from './prisma.service';

type DatabaseHealthSnapshot = {
  healthy: boolean;
  checkedAt: string | null;
  lastError: string | null;
};

@Injectable()
export class DatabaseHealthService {
  private readonly logger = new Logger(DatabaseHealthService.name);
  private readonly cacheMs = 5000;
  private readonly timeoutMs = 2000;

  private lastHealthy = false;
  private lastCheckedAt = 0;
  private lastError: string | null = null;
  private inFlightCheck: Promise<boolean> | null = null;

  constructor(private readonly prisma: PrismaService) {}

  async isDatabaseHealthy(options?: { force?: boolean }): Promise<boolean> {
    const force = options?.force ?? false;
    const now = Date.now();

    if (!force && now - this.lastCheckedAt <= this.cacheMs) {
      return this.lastHealthy;
    }

    if (this.inFlightCheck) {
      return this.inFlightCheck;
    }

    this.inFlightCheck = this.runCheck();
    try {
      const healthy = await this.inFlightCheck;
      this.lastHealthy = healthy;
      this.lastCheckedAt = Date.now();
      return healthy;
    } finally {
      this.inFlightCheck = null;
    }
  }

  async getSnapshot(options?: {
    force?: boolean;
  }): Promise<DatabaseHealthSnapshot> {
    const healthy = await this.isDatabaseHealthy({ force: options?.force });

    return {
      healthy,
      checkedAt:
        this.lastCheckedAt > 0
          ? new Date(this.lastCheckedAt).toISOString()
          : null,
      lastError: this.lastError,
    };
  }

  private async runCheck(): Promise<boolean> {
    const timeoutPromise = new Promise<boolean>((resolve) => {
      setTimeout(() => resolve(false), this.timeoutMs);
    });

    const queryPromise = this.prisma
      .$queryRawUnsafe('SELECT 1')
      .then(() => true)
      .catch((error: unknown) => {
        this.lastError = this.errorMessage(error);
        return false;
      });

    const healthy = await Promise.race([queryPromise, timeoutPromise]);
    if (healthy) {
      this.lastError = null;
      return true;
    }

    if (!this.lastError) {
      this.lastError = `Database health check timed out after ${this.timeoutMs}ms`;
    }
    this.logger.debug(`Database unhealthy: ${this.lastError}`);
    return false;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }
}
