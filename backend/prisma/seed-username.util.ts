import type { PrismaClient } from '@prisma/client';

/** Same shape the API accepts: 3-24 lowercase letters, digits, underscores. */
const USERNAME_PATTERN = /^[a-z0-9_]{3,24}$/;

export function toSeedUsername(value: string): string {
  const cleaned = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 24);
  return cleaned.padEnd(3, '0');
}

/**
 * Gives a seeded profile a username only when it has none, so re-running a
 * seed never overwrites a name someone already set. Falls back to
 * `<preferred>_2`, `_3`... when the preferred name belongs to someone else.
 * Returns the username the profile ends up with.
 */
export async function ensureSeedUsername(
  prisma: PrismaClient,
  profileId: string,
  preferred: string,
): Promise<string | null> {
  const current = await prisma.profile.findUnique({
    where: { id: profileId },
    select: { username: true },
  });
  if (!current) return null;
  if (current.username) return current.username;

  const base = toSeedUsername(preferred);
  for (let attempt = 1; attempt <= 50; attempt += 1) {
    const suffix = attempt === 1 ? '' : `_${attempt}`;
    const candidate = `${base.slice(0, 24 - suffix.length)}${suffix}`;
    if (!USERNAME_PATTERN.test(candidate)) continue;

    const taken = await prisma.profile.findUnique({
      where: { username: candidate },
      select: { id: true },
    });
    if (taken) continue;

    // `username: null` keeps this a no-op if a name was set meanwhile.
    const { count } = await prisma.profile.updateMany({
      where: { id: profileId, username: null },
      data: { username: candidate },
    });
    if (count === 0) {
      const latest = await prisma.profile.findUnique({
        where: { id: profileId },
        select: { username: true },
      });
      return latest?.username ?? null;
    }
    return candidate;
  }

  throw new Error(`Could not find a free username for seeded ${profileId}`);
}
