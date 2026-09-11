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
    await app.init();
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

    it('rejects a non-numeric limit instead of forwarding NaN', async () => {
      await request(app.getHttpServer())
        .get('/audit-log?limit=abc')
        .expect(400);

      expect(auditLogService.listForUser).not.toHaveBeenCalled();
    });
  });
});
