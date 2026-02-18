import { HealthService } from './health.service';

describe('HealthService', () => {
  it('returns healthy payload', () => {
    const service = new HealthService();
    const result = service.getHealth();

    expect(result.status).toBe('ok');
    expect(result.service).toBe('blocnet-backend');
    expect(typeof result.uptimeSeconds).toBe('number');
    expect(result.environment).toBeDefined();
    expect(result.version).toBeDefined();
    expect(result.timestamp).toBeDefined();
  });

  it('returns readiness payload with checks', () => {
    const service = new HealthService();
    const result = service.getReadiness();

    expect(result.status).toBe('ok');
    expect(result.checks).toBeDefined();
    expect(typeof result.checks.databaseUrlConfigured).toBe('boolean');
    expect(typeof result.checks.supabaseAuthConfigured).toBe('boolean');
  });
});
