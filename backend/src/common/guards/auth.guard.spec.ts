import { UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthService } from '../../auth/auth.service';
import { AuthGuard } from './auth.guard';

// AuthService pulls in `jose`, which ships ESM only; jest cannot parse it.
jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(),
  jwtVerify: jest.fn(),
}));

function createContext(headers: Record<string, string | undefined>) {
  const request: { headers: typeof headers; user?: unknown } = { headers };
  return {
    request,
    context: {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: jest.fn(),
      getClass: jest.fn(),
    } as any,
  };
}

describe('AuthGuard', () => {
  const authService = {
    authenticateRequest: jest.fn(),
  } as unknown as jest.Mocked<Pick<AuthService, 'authenticateRequest'>>;

  const reflector = {
    getAllAndOverride: jest.fn(),
  } as unknown as jest.Mocked<Pick<Reflector, 'getAllAndOverride'>>;

  let guard: AuthGuard;

  beforeEach(() => {
    jest.clearAllMocks();
    reflector.getAllAndOverride.mockReturnValue(undefined);
    guard = new AuthGuard(
      authService as unknown as AuthService,
      reflector as unknown as Reflector,
    );
  });

  it('rejects requests without an Authorization header', async () => {
    const { context } = createContext({});
    await expect(guard.canActivate(context)).rejects.toThrow(
      UnauthorizedException,
    );
    expect(authService.authenticateRequest).not.toHaveBeenCalled();
  });

  it('authenticates with allowDeactivated=false by default', async () => {
    const user = { id: 'user-1', email: 'u@test.dev', roles: [] };
    authService.authenticateRequest.mockResolvedValue(user as any);
    const { context, request } = createContext({
      authorization: 'Bearer token-123',
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);

    expect(authService.authenticateRequest).toHaveBeenCalledWith('token-123', {
      allowDeactivated: false,
    });
    expect(request.user).toBe(user);
  });

  it('passes allowDeactivated=true when the handler opts in', async () => {
    reflector.getAllAndOverride.mockReturnValue(true);
    authService.authenticateRequest.mockResolvedValue({
      id: 'user-1',
      email: null,
      roles: [],
    } as any);
    const { context } = createContext({ authorization: 'Bearer token-123' });

    await guard.canActivate(context);

    expect(authService.authenticateRequest).toHaveBeenCalledWith('token-123', {
      allowDeactivated: true,
    });
  });
});
