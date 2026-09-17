import {
  type ExecutionContext,
  type INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AdminTwoFactorService } from '../admin-security/admin-two-factor.service';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { AuditLogController } from './audit-log.controller';
import { AuditLogService } from './audit-log.service';

// AuthGuard imports AuthService, which pulls in the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

/**
 * HTTP-level checks for the audit-log routes. AuthGuard is stubbed to inject
 * `currentUser`; the real RolesGuard runs so role denials are exercised.
 */
describe('AuditLogController', () => {
  const currentUser = {
    id: 'user-1',
    email: 'user@test.dev',
    roles: [AppRole.OWNER] as AppRole[],
  };

  const auditLogService = {
    listForUser: jest.fn(),
    listOpsEvents: jest.fn(),
    listSystemAlerts: jest.fn(),
  };

  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AuditLogController],
      providers: [
        { provide: AuditLogService, useValue: auditLogService },
        {
          provide: AdminTwoFactorService,
          useValue: { shouldEnforceChallengeForAdminPanel: () => false },
        },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          context.switchToHttp().getRequest().user = {
            ...currentUser,
            roles: [...currentUser.roles],
          };
          return true;
        },
      })
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    // Listen once, on the loopback address supertest dials. Left to itself,
    // supertest binds each request to `::` on a random port, and macOS lets
    // that share a port another process holds on 127.0.0.1 (emulator, adb,
    // IDE helpers), so the request lands on that process instead (F-71).
    await app.listen(0, '127.0.0.1');
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    currentUser.roles = [AppRole.OWNER];
    auditLogService.listForUser.mockResolvedValue([]);
  });

  describe('GET /audit-log', () => {
    it('includes view events by default', async () => {
      await request(app.getHttpServer()).get('/audit-log').expect(200);

      expect(auditLogService.listForUser).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'user-1' }),
        100,
        0,
        { includeViews: true },
      );
    });

    it('passes includeViews=false through with limit/offset', async () => {
      await request(app.getHttpServer())
        .get('/audit-log?includeViews=false&limit=25&offset=50')
        .expect(200);

      expect(auditLogService.listForUser).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'user-1' }),
        25,
        50,
        { includeViews: false },
      );
    });

    it('rejects a non-boolean includeViews', async () => {
      await request(app.getHttpServer())
        .get('/audit-log?includeViews=maybe')
        .expect(400);

      expect(auditLogService.listForUser).not.toHaveBeenCalled();
    });

    it('passes a comma-separated action filter through, trimmed and de-duplicated', async () => {
      await request(app.getHttpServer())
        .get(
          '/audit-log?action=admin.mining.config.update,%20settings.update,admin.mining.config.update&limit=20',
        )
        .expect(200);

      expect(auditLogService.listForUser).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'user-1' }),
        20,
        0,
        {
          includeViews: true,
          actions: ['admin.mining.config.update', 'settings.update'],
        },
      );
    });

    it('accepts repeated action params', async () => {
      await request(app.getHttpServer())
        .get('/audit-log?action=a.one&action=b.two')
        .expect(200);

      expect(auditLogService.listForUser).toHaveBeenCalledWith(
        expect.anything(),
        100,
        0,
        { includeViews: true, actions: ['a.one', 'b.two'] },
      );
    });

    it('omits actions when no action filter is given', async () => {
      await request(app.getHttpServer()).get('/audit-log').expect(200);

      const options = auditLogService.listForUser.mock.calls[0]?.[3];
      expect(options).not.toHaveProperty('actions');
    });

    it.each([
      [
        'more than 10 values',
        Array.from({ length: 11 }, (_, i) => `a.${i}`).join(','),
      ],
      ['a value over 64 chars', 'a'.repeat(65)],
      ['an empty value', 'admin.mining.config.update,'],
      ['an empty string', ''],
      ['disallowed characters', 'admin.mining%20config'],
      ['wildcard characters', 'admin.%25'],
    ])('rejects an action filter with %s', async (_label, value) => {
      await request(app.getHttpServer())
        .get(`/audit-log?action=${value}`)
        .expect(400);

      expect(auditLogService.listForUser).not.toHaveBeenCalled();
    });

    it('accepts exactly 10 values of 64 chars', async () => {
      const values = Array.from({ length: 10 }, (_, i) =>
        `${i}`.padEnd(64, 'x'),
      );
      await request(app.getHttpServer())
        .get(`/audit-log?action=${values.join(',')}`)
        .expect(200);

      expect(auditLogService.listForUser).toHaveBeenCalledWith(
        expect.anything(),
        100,
        0,
        { includeViews: true, actions: values },
      );
    });

    it('still refuses the action filter to non-admin roles', async () => {
      currentUser.roles = [AppRole.USER];

      await request(app.getHttpServer())
        .get('/audit-log?action=admin.mining.config.update')
        .expect(403);

      expect(auditLogService.listForUser).not.toHaveBeenCalled();
    });

    it('rejects a non-numeric limit instead of forwarding NaN', async () => {
      await request(app.getHttpServer())
        .get('/audit-log?limit=abc')
        .expect(400);

      expect(auditLogService.listForUser).not.toHaveBeenCalled();
    });
  });

  describe('GET /audit-log/system-alerts', () => {
    it('serves owner and dev', async () => {
      auditLogService.listSystemAlerts.mockResolvedValue([]);

      currentUser.roles = [AppRole.OWNER];
      await request(app.getHttpServer())
        .get('/audit-log/system-alerts')
        .expect(200);

      currentUser.roles = [AppRole.DEV];
      await request(app.getHttpServer())
        .get('/audit-log/system-alerts')
        .expect(200);

      expect(auditLogService.listSystemAlerts).toHaveBeenCalledTimes(2);
    });

    it('returns a displayable 403 body for admin', async () => {
      currentUser.roles = [AppRole.ADMIN];

      const response = await request(app.getHttpServer())
        .get('/audit-log/system-alerts')
        .expect(403);

      expect(response.body).toEqual({
        statusCode: 403,
        error: 'Forbidden',
        message: 'Only owner or dev can view system alerts',
      });
      expect(auditLogService.listSystemAlerts).not.toHaveBeenCalled();
    });
  });
});
