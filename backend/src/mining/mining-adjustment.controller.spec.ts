import 'reflect-metadata';
import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { AdminTwoFactorService } from '../admin-security/admin-two-factor.service';
import { ROLES_KEY } from '../common/decorators/roles.decorator';
import { AppRole } from '../common/enums/role.enum';
import { RolesGuard } from '../common/guards/roles.guard';
import { CreateBnpAdjustmentDto } from './dto/create-bnp-adjustment.dto';
import { MiningAdminController } from './mining-admin.controller';

// AuthGuard imports AuthService, which pulls in the ESM-only `jose` package.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

describe('BNP adjustment routes (F-66)', () => {
  describe('roles', () => {
    const reflector = new Reflector();
    const handlers = [
      MiningAdminController.prototype.createAdjustment,
      MiningAdminController.prototype.listAdjustments,
    ];

    it.each(handlers)('requires owner or admin', (handler) => {
      expect(reflector.get(ROLES_KEY, handler)).toEqual([
        AppRole.OWNER,
        AppRole.ADMIN,
      ]);
    });

    function guardFor(roles: AppRole[]) {
      const twoFactor = {
        shouldEnforceChallengeForAdminPanel: jest.fn().mockResolvedValue(false),
        validateSession: jest.fn(),
      } as unknown as AdminTwoFactorService;
      const guard = new RolesGuard(reflector, twoFactor);
      const context = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { id: 'u1', email: null, roles },
            headers: {},
          }),
        }),
        getHandler: () => MiningAdminController.prototype.createAdjustment,
        getClass: () => MiningAdminController,
      } as never;
      return guard.canActivate(context);
    }

    it.each([[[AppRole.USER, AppRole.OWNER]], [[AppRole.USER, AppRole.ADMIN]]])(
      'lets %j through',
      async (roles) => {
        await expect(guardFor(roles)).resolves.toBe(true);
      },
    );

    it.each([
      [[AppRole.USER]],
      [[AppRole.USER, AppRole.COMMUNITY_MODERATOR]],
      [[AppRole.USER, AppRole.CORE_TEAM, AppRole.HUNTER]],
    ])('rejects %j', async (roles) => {
      await expect(guardFor(roles)).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  describe('CreateBnpAdjustmentDto validation', () => {
    const valid = {
      amount: 250,
      reason: 'Refund for a failed claim',
      idempotencyKey: '3f2b7c1e-9a4d-4c8e-b1f0-2d6a8e5c7b91',
    };

    async function errorsFor(body: Record<string, unknown>) {
      const errors = await validate(
        plainToInstance(CreateBnpAdjustmentDto, body),
        {
          whitelist: true,
          forbidNonWhitelisted: true,
        },
      );
      return errors.map((error) => error.property);
    }

    it('accepts a valid credit and debit', async () => {
      expect(await errorsFor(valid)).toEqual([]);
      expect(await errorsFor({ ...valid, amount: -1_000_000 })).toEqual([]);
    });

    it.each([0, 1.5, 1_000_001, -1_000_001, '10', null])(
      'rejects amount %p',
      async (amount) => {
        expect(await errorsFor({ ...valid, amount })).toEqual(['amount']);
      },
    );

    it('trims the reason before checking its length', async () => {
      const dto = plainToInstance(CreateBnpAdjustmentDto, {
        ...valid,
        reason: '   Refund ok   ',
      });
      expect(dto.reason).toBe('Refund ok');
      expect(await errorsFor({ ...valid, reason: '   Refund ok   ' })).toEqual([
        'reason',
      ]);
    });

    it.each([undefined, '', 'short', 'x'.repeat(501)])(
      'rejects reason %p',
      async (reason) => {
        expect(await errorsFor({ ...valid, reason })).toEqual(['reason']);
      },
    );

    it.each([undefined, 'not-a-uuid'])(
      'rejects idempotencyKey %p',
      async (idempotencyKey) => {
        expect(await errorsFor({ ...valid, idempotencyKey })).toEqual([
          'idempotencyKey',
        ]);
      },
    );

    it('rejects unknown fields', async () => {
      expect(await errorsFor({ ...valid, userId: 'x' })).toEqual(['userId']);
    });
  });
});
