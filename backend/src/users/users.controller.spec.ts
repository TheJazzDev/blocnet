import {
  type ExecutionContext,
  type INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AuthGuard } from '../common/guards/auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { EdgeEngineService } from '../edge-engine/edge-engine.service';
import { MeRadarService } from '../me-radar/me-radar.service';
import { PrismaService } from '../prisma/prisma.service';
import { ReferralsService } from '../referrals/referrals.service';
import { UpdatesService } from '../updates/updates.service';
import { UserDigestService } from './user-digest.service';
import { UsersAdminService } from './users-admin.service';
import { AdminUsersController, UsersController } from './users.controller';
import { UsersService } from './users.service';

// AuthGuard imports AuthService, which pulls in the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

/**
 * Route-level checks for the self-service account lifecycle endpoints.
 * Guards are stubbed; the goal is to pin the paths and the service calls.
 */
describe('UsersController (self-service deactivate/reactivate)', () => {
  const currentUser = { id: 'user-1', email: 'user@test.dev', roles: ['user'] };

  const usersService = {
    deactivateAccount: jest.fn(),
    reactivateAccount: jest.fn(),
  };

  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      controllers: [UsersController, AdminUsersController],
      providers: [
        { provide: UsersService, useValue: usersService },
        { provide: UserDigestService, useValue: {} },
        { provide: UpdatesService, useValue: {} },
        { provide: EdgeEngineService, useValue: {} },
        { provide: MeRadarService, useValue: {} },
        { provide: PrismaService, useValue: {} },
        { provide: UsersAdminService, useValue: {} },
        { provide: ReferralsService, useValue: {} },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({
        canActivate: (context: ExecutionContext) => {
          context.switchToHttp().getRequest().user = currentUser;
          return true;
        },
      })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
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
  });

  it('POST /me/deactivate deactivates the caller with the given reason', async () => {
    usersService.deactivateAccount.mockResolvedValue({
      id: 'user-1',
      isDeactivated: true,
    });

    const response = await request(app.getHttpServer())
      .post('/me/deactivate')
      .send({ reason: 'taking a break' })
      .expect(201);

    expect(response.body).toEqual({ id: 'user-1', isDeactivated: true });
    expect(usersService.deactivateAccount).toHaveBeenCalledWith(
      'user-1',
      'taking a break',
    );
  });

  it('POST /me/deactivate accepts an empty body', async () => {
    usersService.deactivateAccount.mockResolvedValue({
      id: 'user-1',
      isDeactivated: true,
    });

    await request(app.getHttpServer()).post('/me/deactivate').expect(201);

    expect(usersService.deactivateAccount).toHaveBeenCalledWith(
      'user-1',
      undefined,
    );
  });

  it('POST /me/reactivate reactivates the caller', async () => {
    usersService.reactivateAccount.mockResolvedValue({
      id: 'user-1',
      isDeactivated: false,
    });

    await request(app.getHttpServer()).post('/me/reactivate').expect(201);

    expect(usersService.reactivateAccount).toHaveBeenCalledWith('user-1');
  });

  it('no longer exposes the self-service routes under /admin/users', async () => {
    await request(app.getHttpServer())
      .post('/admin/users/me/deactivate')
      .expect(404);
    await request(app.getHttpServer())
      .post('/admin/users/me/reactivate')
      .expect(404);

    expect(usersService.deactivateAccount).not.toHaveBeenCalled();
    expect(usersService.reactivateAccount).not.toHaveBeenCalled();
  });
});
