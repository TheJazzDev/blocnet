import { HealthService } from './health.service';
import { DatabaseHealthService } from '../prisma/database-health.service';

describe('HealthService', () => {
  const databaseHealthServiceMock = {
    getSnapshot: jest.fn(async () => ({
      healthy: true,
      checkedAt: new Date().toISOString(),
      lastError: null,
    })),
  } as unknown as DatabaseHealthService;

  it('returns healthy payload', () => {
    const service = new HealthService(databaseHealthServiceMock);
    const result = service.getHealth();

    expect(result.status).toBe('ok');
    expect(result.service).toBe('blocnet-backend');
    expect(typeof result.uptimeSeconds).toBe('number');
    expect(result.environment).toBeDefined();
    expect(result.version).toBeDefined();
    expect(result.timestamp).toBeDefined();
  });

  it('returns readiness payload with checks', async () => {
    const service = new HealthService(databaseHealthServiceMock);
    const result = await service.getReadiness();

    expect(result.status).toBe('ok');
    expect(result.checks).toBeDefined();
    expect(typeof result.checks.database.configured).toBe('boolean');
    expect(typeof result.checks.database.healthy).toBe('boolean');
    expect(typeof result.checks.supabaseAuthConfigured).toBe('boolean');
  });
});
