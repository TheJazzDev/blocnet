import { HealthService } from './health.service';

describe('HealthService', () => {
  it('returns healthy payload', () => {
    const service = new HealthService();
    const result = service.getHealth();

    expect(result.status).toBe('ok');
    expect(result.timestamp).toBeDefined();
  });
});
