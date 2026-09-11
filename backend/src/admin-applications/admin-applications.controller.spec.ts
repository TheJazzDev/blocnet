import {
  type ExecutionContext,
  type INestApplication,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AdminTwoFactorService } from '../admin-security/admin-two-factor.service';
import { AppRole } from '../common/enums/role.enum';
import { AuthGuard } from '../common/guards/auth.guard';
import { AdminApplicationsController } from './admin-applications.controller';
import { AdminApplicationsService } from './admin-applications.service';

// AuthGuard imports AuthService, which pulls in the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

const CALLER_ID = '6d1f3c2a-8b4e-4f6a-9c1d-2e3f4a5b6c7d';
const OTHER_USER_ID = 'e9a8b7c6-d5e4-4f3a-b2c1-d0e9f8a7b6c5';
const APPLICATION_ID = '3f2b7c1e-9a4d-4c8e-b1f0-2d6a8e5c7b91';

/**
 * HTTP-level checks for `GET /admin-applications/mine`. AuthGuard is stubbed to
 * inject `currentUser` only when a bearer header is present (so the 401 path
 * is exercised); the real RolesGuard runs so the owner/admin list stays gated.
 */
describe('AdminApplicationsController', () => {
  const currentUser = {
    id: CALLER_ID,
    email: 'applicant@test.dev',
    roles: [AppRole.USER] as AppRole[],
  };

  const mineRows = [
    {
      id: APPLICATION_ID,
      targetRole: 'hunter',
      status: 'rejected',
      reason: 'I curate DeFi projects',
      createdAt: new Date('2026-09-01T10:00:00.000Z'),
      reviewedAt: new Date('2026-09-02T09:30:00.000Z'),
    },
  ];

  const adminApplicationsService = {
    create: jest.fn(),
    list: jest.fn(),
    listMine: jest.fn(),
    review: jest.fn(),
  };

  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [AdminApplicationsController],
      providers: [
        {
          provide: AdminApplicationsService,
          useValue: adminApplicationsService,
        },
        {
          provide: AdminTwoFactorService,
          useValue: { shouldEnforceChallengeForAdminPanel: () => false },
        },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          const req = context.switchToHttp().getRequest();
          if (!req.headers.authorization) {
            throw new UnauthorizedException('Missing Authorization header');
          }
          req.user = { ...currentUser, roles: [...currentUser.roles] };
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
    currentUser.roles = [AppRole.USER];
    adminApplicationsService.listMine.mockResolvedValue(mineRows);
    adminApplicationsService.list.mockResolvedValue([]);
  });

  const asCaller = (req: request.Test) =>
    req.set('Authorization', 'Bearer test-token');

  describe('GET /admin-applications/mine', () => {
    it("returns the caller's rows, scoped by the authenticated user id", async () => {
      const response = await asCaller(
        request(app.getHttpServer()).get('/admin-applications/mine'),
      ).expect(200);

      expect(adminApplicationsService.listMine).toHaveBeenCalledTimes(1);
      expect(adminApplicationsService.listMine).toHaveBeenCalledWith(
        CALLER_ID,
        {},
      );
      expect(adminApplicationsService.listMine).not.toHaveBeenCalledWith(
        OTHER_USER_ID,
        expect.anything(),
      );
      expect(response.body).toEqual([
        {
          id: APPLICATION_ID,
          targetRole: 'hunter',
          status: 'rejected',
          reason: 'I curate DeFi projects',
          createdAt: '2026-09-01T10:00:00.000Z',
          reviewedAt: '2026-09-02T09:30:00.000Z',
        },
      ]);
    });

    it('is open to any signed-in user, not only owner/admin', async () => {
      currentUser.roles = [AppRole.USER];
      await asCaller(
        request(app.getHttpServer()).get('/admin-applications/mine'),
      ).expect(200);

      expect(adminApplicationsService.list).not.toHaveBeenCalled();
    });

    it('passes a valid targetRole filter through', async () => {
      await asCaller(
        request(app.getHttpServer()).get(
          '/admin-applications/mine?targetRole=hunter',
        ),
      ).expect(200);

      expect(adminApplicationsService.listMine).toHaveBeenCalledWith(
        CALLER_ID,
        { targetRole: 'hunter' },
      );
    });

    it('rejects an unknown targetRole with 400', async () => {
      await asCaller(
        request(app.getHttpServer()).get(
          '/admin-applications/mine?targetRole=wizard',
        ),
      ).expect(400);

      expect(adminApplicationsService.listMine).not.toHaveBeenCalled();
    });

    it('rejects unknown query params with 400', async () => {
      await asCaller(
        request(app.getHttpServer()).get(
          `/admin-applications/mine?userId=${OTHER_USER_ID}`,
        ),
      ).expect(400);

      expect(adminApplicationsService.listMine).not.toHaveBeenCalled();
    });

    it('returns 401 without a bearer token', async () => {
      await request(app.getHttpServer())
        .get('/admin-applications/mine')
        .expect(401);

      expect(adminApplicationsService.listMine).not.toHaveBeenCalled();
    });
  });

  describe('route shape', () => {
    it('`mine` is never captured by the :id review route', async () => {
      await asCaller(
        request(app.getHttpServer()).get('/admin-applications/mine'),
      ).expect(200);

      expect(adminApplicationsService.review).not.toHaveBeenCalled();
      expect(adminApplicationsService.list).not.toHaveBeenCalled();
      expect(adminApplicationsService.listMine).toHaveBeenCalledTimes(1);
    });

    it('PATCH /admin-applications/mine/review is rejected as a non-UUID id', async () => {
      currentUser.roles = [AppRole.OWNER];

      await asCaller(
        request(app.getHttpServer())
          .patch('/admin-applications/mine/review')
          .send({ status: 'approved' }),
      ).expect(400);

      expect(adminApplicationsService.review).not.toHaveBeenCalled();
      expect(adminApplicationsService.listMine).not.toHaveBeenCalled();
    });
  });

  describe('GET /admin-applications (owner/admin list) is untouched', () => {
    it('still serves owner and admin', async () => {
      currentUser.roles = [AppRole.OWNER];
      await asCaller(
        request(app.getHttpServer()).get('/admin-applications'),
      ).expect(200);

      currentUser.roles = [AppRole.ADMIN];
      await asCaller(
        request(app.getHttpServer()).get('/admin-applications'),
      ).expect(200);

      expect(adminApplicationsService.list).toHaveBeenCalledTimes(2);
      expect(adminApplicationsService.listMine).not.toHaveBeenCalled();
    });

    it('still returns 403 for a plain user', async () => {
      currentUser.roles = [AppRole.USER];

      await asCaller(
        request(app.getHttpServer()).get('/admin-applications'),
      ).expect(403);

      expect(adminApplicationsService.list).not.toHaveBeenCalled();
    });
  });
});
