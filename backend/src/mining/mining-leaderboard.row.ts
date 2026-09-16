import { toCurrentLevelDto } from '../levels/level-summary';
import { MiningCalculatorService } from './mining-calculator.service';
import { isClaimable } from './mining-settlement';
import type { LeaderboardProfile } from './mining-leaderboard.query';

type MiningSessionStatus = 'idle' | 'running' | 'claimable';

type ClaimWindowConfig = Parameters<typeof isClaimable>[2];

export type LeaderboardRowContext = {
  asOf: Date;
  config: ClaimWindowConfig;
  miningCalculator: MiningCalculatorService;
  includePrivateFields: boolean;
};

export function toLeaderboardRow(
  profile: LeaderboardProfile,
  rank: number,
  maturedUnclaimedPoints: number,
  ctx: LeaderboardRowContext,
) {
  const { asOf, config } = ctx;
  const currentSession = profile.miningSessions[0] ?? null;
  // Keep BigInt arithmetic in BigInt space and serialize to string at
  // the response boundary (never as a JS number) to avoid precision
  // loss once mining points scale past Number.MAX_SAFE_INTEGER.
  const claimedTotalPointsBigInt = profile.miningClaimedPoints;
  const lifetimeEarnedPointsBigInt =
    claimedTotalPointsBigInt + BigInt(maturedUnclaimedPoints);
  // A cycle past its claim window is no longer claimable even if the
  // owner has not hit a mining endpoint yet to have it settled, so the
  // board must not badge it CLAIMABLE (F-39).
  const sessionIsLive =
    currentSession !== null && currentSession.endsAt.getTime() > asOf.getTime();
  const sessionIsClaimable =
    currentSession !== null && isClaimable(currentSession, asOf, config);
  const sessionStatus: MiningSessionStatus = sessionIsLive
    ? 'running'
    : sessionIsClaimable
      ? 'claimable'
      : 'idle';
  const displaySession =
    sessionIsLive || sessionIsClaimable ? currentSession : null;

  return {
    rank,
    userId: profile.id,
    email: ctx.includePrivateFields ? profile.email : undefined,
    username: profile.username,
    displayName: profile.displayName,
    avatarUrl: profile.avatarUrl,
    primaryBadge: profile.primaryBadge ?? null,
    currentLevel: toCurrentLevelDto(profile.currentLevel),
    claimedTotalPoints: claimedTotalPointsBigInt.toString(),
    maturedUnclaimedPoints,
    lifetimeEarnedPoints: lifetimeEarnedPointsBigInt.toString(),
    sessionStatus,
    sessionProgressPct: displaySession
      ? ctx.miningCalculator.computeProgressPct(
          displaySession.startsAt,
          displaySession.endsAt,
          asOf,
        )
      : 0,
    sessionEndsAt: displaySession?.endsAt ?? null,
    boostBpsSnapshot: displaySession?.boostBpsSnapshot ?? 0,
    activeReferralsSnapshot: displaySession?.activeReferralsSnapshot ?? 0,
  };
}

export type LeaderboardRow = ReturnType<typeof toLeaderboardRow>;

/** The caller's own row, pinned by the app; `isMiningNow` mirrors `sessionStatus === 'running'`. */
export type LeaderboardMe = LeaderboardRow & { isMiningNow: boolean };
