import { Reflector } from '@nestjs/core';
import { RolesGuard } from './roles.guard';
import { AppRole } from '../enums/role.enum';

function createContext(request: {
  user?: {
    id: string;
    email: string | null;
    roles: AppRole[];
    realRoles?: AppRole[];
    actingAsRole?: AppRole | null;
  };
  headers: Record<string, string | string[] | undefined>;
}) {
  return {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
    getHandler: jest.fn(),
    getClass: jest.fn(),
  } as any;
}

describe('RolesGuard', () => {
  it('uses effective roles for authorization checks', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([AppRole.MODERATOR]),
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);

    const request = {
      user: {
        id: 'u1',
        email: 'owner@blocnet.io',
        roles: [AppRole.OWNER, AppRole.HUNTER],
      },
      headers: {
        'x-admin-view-as-role': AppRole.MODERATOR,
      },
    };

    const result = guard.canActivate(createContext(request));
    expect(result).toBe(true);
    expect(request.user?.realRoles).toEqual([AppRole.OWNER, AppRole.HUNTER]);
    expect(request.user?.roles).toEqual([AppRole.HUNTER, AppRole.MODERATOR]);
    expect(request.user?.actingAsRole).toBe(AppRole.MODERATOR);
  });

  it('ignores invalid or upward role requests', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([AppRole.MODERATOR]),
    } as unknown as Reflector;
    const guard = new RolesGuard(reflector);

    const request = {
      user: {
        id: 'u2',
        email: 'mod@blocnet.io',
        roles: [AppRole.MODERATOR],
      },
      headers: {
        'x-admin-view-as-role': AppRole.ADMIN,
      },
    };

    const result = guard.canActivate(createContext(request));
    expect(result).toBe(true);
    expect(request.user?.roles).toEqual([AppRole.MODERATOR]);
    expect(request.user?.actingAsRole).toBeNull();
  });
});
