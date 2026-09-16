/**
 * The thresholds behind a hunter's reliability.
 *
 * Each one is a product judgement (owner decision 2026-09-16, APP_MAP §2), so
 * each lives here once. Changing a number here changes it for the hunter's own
 * board, the public profile, the leaderboard and the moderator queue together.
 */

export const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * A gem untouched this long is quiet.
 *
 * Two weeks — the same rule the Home board's `QuietGems` uses on the phone, so
 * a member and a hunter never disagree about whether a gem has gone quiet.
 */
export const QUIET_AFTER_DAYS = 14;

/**
 * A gem untouched this long is due: not yet quiet, but the hunter should post.
 *
 * Ten days leaves the hunter four days of warning before members see the gem
 * as quiet.
 */
export const DUE_AFTER_DAYS = 10;

/**
 * How far back cadence and response look.
 *
 * A quarter: long enough that one busy fortnight does not define a hunter,
 * short enough that a hunter who has improved is not held to last year.
 */
export const RELIABILITY_WINDOW_DAYS = 90;

/**
 * How long a hunter has to answer a week of member asks with an update.
 *
 * A week, matching the cadence at which asks are aggregated and the hunter is
 * notified (`NUDGE_COOLDOWN_MS` in project-attention).
 */
export const RESPONSE_WINDOW_DAYS = 7;

/** "Members waiting" counts asks this recent — the nudge cooldown. */
export const MEMBERS_WAITING_DAYS = 7;

/** `updates30d` looks back this far. */
export const RECENT_UPDATES_DAYS = 30;

/** Coverage at or above this is `reliable`. */
export const RELIABLE_MIN_COVERAGE = 0.8;

/** Coverage at or above this (and below reliable) is `slipping`; below is `quiet`. */
export const SLIPPING_MIN_COVERAGE = 0.5;

/**
 * A hunter whose first gem was listed more recently than this is `new`.
 *
 * Same fourteen days as the quiet rule: before then, no gem of theirs can have
 * gone quiet, so a coverage figure would flatter them without meaning anything.
 */
export const NEW_HUNTER_DAYS = QUIET_AFTER_DAYS;
