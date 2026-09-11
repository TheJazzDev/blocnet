import { UnauthorizedException } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { AuthService } from './auth.service';

jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

describe('AuthService', () => {
  const configService = {
    get: jest.fn(),
  };

  const prisma = {
    profile: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    userRole: {
      findMany: jest.fn(),
      create: jest.fn(),
    },
  };

  const walletProvisioningService = {
    ensureWalletForUser: jest.fn().mockResolvedValue(undefined),
  };
  const notificationsService = {
    notifyMany: jest.fn().mockResolvedValue(undefined),
  };
  const runtimeFeatureFlagsService = {
    isClosedAlphaEnabled: jest.fn().mockReturnValue(false),
    getConfig: jest.fn().mockResolvedValue({ closedAlphaEnabled: false }),
  };
  const closedAlphaAccessService = {
    isEmailAllowed: jest.fn().mockResolvedValue(true),
  };

  beforeEach(() => {
    jest.resetAllMocks();
    configService.get.mockReturnValue(undefined);
    prisma.userRole.findMany.mockResolvedValue([{ role: RoleName.user }]);
    walletProvisioningService.ensureWalletForUser.mockResolvedValue(undefined);
    notificationsService.notifyMany.mockResolvedValue(undefined);
    runtimeFeatureFlagsService.isClosedAlphaEnabled.mockReturnValue(false);
    runtimeFeatureFlagsService.getConfig.mockResolvedValue({
      closedAlphaEnabled: false,
    });
    closedAlphaAccessService.isEmailAllowed.mockResolvedValue(true);
  });

  function createService() {
    return new AuthService(
      configService as any,
      prisma as any,
      walletProvisioningService as any,
      notificationsService as any,
      runtimeFeatureFlagsService as any,
      closedAlphaAccessService as any,
    );
  }

  function mockDeactivatedProfile(userId: string) {
    prisma.profile.findUnique.mockResolvedValue({
      id: userId,
      isDeactivated: true,
      referralCode: 'REF00001',
      username: 'sleeper',
    });
    prisma.profile.update.mockResolvedValue(undefined);
  }

  it('rejects deactivated accounts by default', async () => {
    mockDeactivatedProfile('user-3');
    const service = createService();
    jest.spyOn<any, any>(service as any, 'verifyToken').mockResolvedValue({
      sub: 'user-3',
      email: 'user3@test.dev',
    });

    await expect(service.authenticateRequest('token')).rejects.toThrow(
      new UnauthorizedException('Account is deactivated'),
    );
    expect(prisma.profile.update).not.toHaveBeenCalled();
  });

  it('lets deactivated accounts through when allowDeactivated is set', async () => {
    mockDeactivatedProfile('user-3');
    const service = createService();
    jest.spyOn<any, any>(service as any, 'verifyToken').mockResolvedValue({
      sub: 'user-3',
      email: 'user3@test.dev',
    });

    const user = await service.authenticateRequest('token', {
      allowDeactivated: true,
    });

    expect(user).toEqual({
      id: 'user-3',
      email: 'user3@test.dev',
      roles: ['user'],
    });
  });

  it('auto-binds referral from signup metadata on first profile creation', async () => {
    prisma.profile.findUnique.mockImplementation(
      async ({ where }: { where: { id?: string; referralCode?: string } }) => {
        if (where.id === 'user-1') {
          return null;
        }
        if (where.referralCode === 'AB12CD34') {
          return { id: 'referrer-1' };
        }
        return null;
      },
    );
    prisma.profile.create.mockResolvedValue(undefined);

    const service = new AuthService(
      configService as any,
      prisma as any,
      walletProvisioningService as any,
      notificationsService as any,
      runtimeFeatureFlagsService as any,
      closedAlphaAccessService as any,
    );
    jest.spyOn<any, any>(service as any, 'verifyToken').mockResolvedValue({
      sub: 'user-1',
      email: 'user1@test.dev',
      user_metadata: {
        username: 'newbie',
        referralCode: 'ab12cd34',
      },
    });

    await service.authenticateRequest('token');

    expect(prisma.profile.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          id: 'user-1',
          referredById: 'referrer-1',
          referredAt: expect.any(Date),
        }),
      }),
    );
  });

  it('does not bind referral when metadata code is missing/invalid', async () => {
    prisma.profile.findUnique.mockImplementation(
      async ({ where }: { where: { id?: string; referralCode?: string } }) => {
        if (where.id === 'user-2') {
          return null;
        }
        return null;
      },
    );
    prisma.profile.create.mockResolvedValue(undefined);

    const service = new AuthService(
      configService as any,
      prisma as any,
      walletProvisioningService as any,
      notificationsService as any,
      runtimeFeatureFlagsService as any,
      closedAlphaAccessService as any,
    );
    jest.spyOn<any, any>(service as any, 'verifyToken').mockResolvedValue({
      sub: 'user-2',
      email: 'user2@test.dev',
      user_metadata: {
        username: 'newbie2',
        referralCode: 'BAD',
      },
    });

    await service.authenticateRequest('token');

    expect(prisma.profile.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.not.objectContaining({
          referredById: expect.anything(),
        }),
      }),
    );
  });
});
