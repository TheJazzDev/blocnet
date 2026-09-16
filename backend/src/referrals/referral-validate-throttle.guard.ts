import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Optional,
} from '@nestjs/common';

export const REFERRAL_THROTTLE_CLOCK = Symbol('REFERRAL_THROTTLE_CLOCK');

const LIMIT = 30;
const WINDOW_MS = 60_000;
/** Sweep expired buckets once the map grows past this, so it cannot grow unbounded. */
const SWEEP_THRESHOLD = 10_000;

type Bucket = { count: number; resetAt: number };

type RequestLike = {
  ip?: string;
  headers?: Record<string, string | string[] | undefined>;
};

/**
 * Per-IP fixed-window limit for the public `GET /referrals/validate` (F-46):
 * 30 requests a minute, in memory, per process.
 *
 * The app runs behind Railway's proxy without `trust proxy`, so `req.ip` is the
 * proxy. The client is keyed on the right-most `X-Forwarded-For` hop, the one
 * the proxy appends. The left-most hops are client-supplied and would let a
 * caller dodge the limit by rotating the header.
 */
@Injectable()
export class ReferralValidateThrottleGuard implements CanActivate {
  private readonly buckets = new Map<string, Bucket>();
  private readonly now: () => number;

  constructor(
    @Optional() @Inject(REFERRAL_THROTTLE_CLOCK) now?: () => number,
  ) {
    this.now = now ?? Date.now;
  }

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<RequestLike>();
    const key = clientKey(request);
    const now = this.now();

    if (this.buckets.size > SWEEP_THRESHOLD) {
      for (const [bucketKey, bucket] of this.buckets) {
        if (bucket.resetAt <= now) this.buckets.delete(bucketKey);
      }
    }

    const bucket = this.buckets.get(key);
    if (!bucket || bucket.resetAt <= now) {
      this.buckets.set(key, { count: 1, resetAt: now + WINDOW_MS });
      return true;
    }

    if (bucket.count >= LIMIT) {
      throw new HttpException(
        {
          statusCode: HttpStatus.TOO_MANY_REQUESTS,
          code: 'rate_limited',
          message: 'Too many referral code checks. Try again in a minute.',
          retryAfterSeconds: Math.ceil((bucket.resetAt - now) / 1000),
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    bucket.count += 1;
    return true;
  }
}

function clientKey(request: RequestLike): string {
  const header = request.headers?.['x-forwarded-for'];
  const raw = Array.isArray(header) ? header[header.length - 1] : header;
  const hops = (raw ?? '')
    .split(',')
    .map((hop) => hop.trim())
    .filter(Boolean);
  return hops[hops.length - 1] ?? request.ip ?? 'unknown';
}
