import { ExecutionContext, HttpException, HttpStatus } from '@nestjs/common';
import {
  clientKey,
  ReferralValidateThrottleGuard,
} from './referral-validate-throttle.guard';

function contextFor(request: {
  ip?: string;
  headers?: Record<string, string | string[] | undefined>;
}): ExecutionContext {
  const req = { headers: {}, ...request };
  return {
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
}

describe('ReferralValidateThrottleGuard (F-46)', () => {
  let nowMs: number;
  let guard: ReferralValidateThrottleGuard;

  beforeEach(() => {
    nowMs = Date.parse('2026-09-16T12:00:00.000Z');
    guard = new ReferralValidateThrottleGuard(() => nowMs);
  });

  function hit(ip: string) {
    return guard.canActivate(contextFor({ ip }));
  }

  it('allows 30 requests per minute from one IP and rejects the 31st with 429', () => {
    for (let i = 0; i < 30; i += 1) {
      expect(hit('1.1.1.1')).toBe(true);
    }

    let thrown: unknown;
    try {
      hit('1.1.1.1');
    } catch (error) {
      thrown = error;
    }
    expect(thrown).toBeInstanceOf(HttpException);
    expect((thrown as HttpException).getStatus()).toBe(
      HttpStatus.TOO_MANY_REQUESTS,
    );
  });

  it('counts each IP separately', () => {
    for (let i = 0; i < 30; i += 1) hit('1.1.1.1');

    expect(hit('2.2.2.2')).toBe(true);
  });

  it('opens again once the window has passed', () => {
    for (let i = 0; i < 30; i += 1) hit('1.1.1.1');
    expect(() => hit('1.1.1.1')).toThrow(HttpException);

    nowMs += 60_000;

    expect(hit('1.1.1.1')).toBe(true);
  });

  it('keys on the first X-Forwarded-For entry, which Railway sets from the connecting IP', () => {
    // Railway strips client XFF at the edge and may append its own internal
    // hops, so the trailing entries are shared by every caller.
    for (let i = 0; i < 30; i += 1) {
      guard.canActivate(
        contextFor({
          ip: '10.0.0.1',
          headers: { 'x-forwarded-for': `3.3.3.3, 100.64.0.${i}` },
        }),
      );
    }

    expect(() =>
      guard.canActivate(
        contextFor({
          ip: '10.0.0.1',
          headers: { 'x-forwarded-for': '3.3.3.3, 100.64.0.99' },
        }),
      ),
    ).toThrow(HttpException);
    // A different client behind the same internal hop is unaffected.
    expect(
      guard.canActivate(
        contextFor({
          ip: '10.0.0.1',
          headers: { 'x-forwarded-for': '4.4.4.4, 100.64.0.99' },
        }),
      ),
    ).toBe(true);
  });

  it('falls back to X-Real-IP, then the socket address', () => {
    expect(
      clientKey({ ip: '10.0.0.1', headers: { 'x-real-ip': ' 5.5.5.5 ' } }),
    ).toBe('5.5.5.5');
    expect(clientKey({ ip: '10.0.0.1', headers: {} })).toBe('10.0.0.1');
    expect(
      clientKey({
        ip: '10.0.0.1',
        headers: { 'x-forwarded-for': ['6.6.6.6, 100.64.0.1', '7.7.7.7'] },
      }),
    ).toBe('6.6.6.6');
    expect(clientKey({ headers: { 'x-forwarded-for': ' , ' } })).toBe(
      'unknown',
    );
  });
});
