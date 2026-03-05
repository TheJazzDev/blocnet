import { PrismaClient, RoleName } from '@prisma/client';

type CliOptions = {
  apply: boolean;
  dryRun: boolean;
  convertAdminIds: Set<string>;
  convertAdminEmails: Set<string>;
  dropAdminOnConvert: boolean;
};

function parseCsvArg(value: string | undefined): Set<string> {
  if (!value) return new Set<string>();
  return new Set(
    value
      .split(',')
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0),
  );
}

function parseArgs(argv: string[]): CliOptions {
  const args = new Map<string, string | true>();

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index] ?? '';
    if (!arg.startsWith('--')) continue;

    const [rawKey, rawValue] = arg.split('=', 2);
    const key = rawKey.trim();

    if (rawValue !== undefined) {
      args.set(key, rawValue.trim());
      continue;
    }

    const next = argv[index + 1];
    if (next && !next.startsWith('--')) {
      args.set(key, next.trim());
      index += 1;
      continue;
    }

    args.set(key, true);
  }

  const apply = args.has('--apply');
  const dryRun = !apply || args.has('--dry-run');

  return {
    apply,
    dryRun,
    convertAdminIds: parseCsvArg(args.get('--convert-admin-ids') as string | undefined),
    convertAdminEmails: new Set(
      [...parseCsvArg(args.get('--convert-admin-emails') as string | undefined)]
        .map((entry) => entry.toLowerCase()),
    ),
    dropAdminOnConvert: args.has('--drop-admin-on-convert'),
  };
}

async function main() {
  const prisma = new PrismaClient();
  const options = parseArgs(process.argv.slice(2));

  try {
    const legacyModerators = await prisma.userRole.findMany({
      where: { role: RoleName.moderator },
      select: { userId: true },
      distinct: ['userId'],
    });

    const legacyModeratorIds = legacyModerators.map((entry) => entry.userId);

    const existingCommunityModerators =
      legacyModeratorIds.length > 0
        ? await prisma.userRole.findMany({
            where: {
              role: RoleName.community_moderator,
              userId: { in: legacyModeratorIds },
            },
            select: { userId: true },
            distinct: ['userId'],
          })
        : [];

    const hasCommunityModerator = new Set(
      existingCommunityModerators.map((entry) => entry.userId),
    );

    const moderatorBackfillIds = legacyModeratorIds.filter(
      (userId) => !hasCommunityModerator.has(userId),
    );

    const allAdminRows = await prisma.userRole.findMany({
      where: { role: RoleName.admin },
      select: {
        userId: true,
        user: {
          select: {
            email: true,
          },
        },
      },
    });

    const selectedAdmins = allAdminRows
      .filter((entry) => {
        if (options.convertAdminIds.has(entry.userId)) return true;
        const email = entry.user?.email?.trim().toLowerCase();
        return email ? options.convertAdminEmails.has(email) : false;
      })
      .map((entry) => ({
        userId: entry.userId,
        email: entry.user?.email ?? null,
      }));

    const selectedAdminIds = selectedAdmins.map((entry) => entry.userId);

    const existingCommunityAdmins =
      selectedAdminIds.length > 0
        ? await prisma.userRole.findMany({
            where: {
              role: RoleName.community_admin,
              userId: { in: selectedAdminIds },
            },
            select: { userId: true },
            distinct: ['userId'],
          })
        : [];

    const hasCommunityAdmin = new Set(
      existingCommunityAdmins.map((entry) => entry.userId),
    );

    const adminPromotionsNeeded = selectedAdmins.filter(
      (entry) => !hasCommunityAdmin.has(entry.userId),
    );

    console.log('\n=== Community Role Backfill Plan ===');
    console.log(`Mode: ${options.dryRun ? 'DRY RUN' : 'APPLY'}`);
    console.log(`Legacy moderator records found: ${legacyModeratorIds.length}`);
    console.log(
      `Need community_moderator add: ${moderatorBackfillIds.length}`,
    );
    console.log(`Current admin records: ${allAdminRows.length}`);
    console.log(
      `Selected admin users for conversion: ${selectedAdmins.length}`,
    );
    console.log(
      `Need community_admin add for selected users: ${adminPromotionsNeeded.length}`,
    );
    console.log(
      `Drop admin on selected users: ${options.dropAdminOnConvert ? 'yes' : 'no'}`,
    );

    if (options.dryRun) {
      if (moderatorBackfillIds.length > 0) {
        console.log('\nLegacy moderator userIds to backfill:');
        for (const userId of moderatorBackfillIds.slice(0, 25)) {
          console.log(`- ${userId}`);
        }
        if (moderatorBackfillIds.length > 25) {
          console.log(`... and ${moderatorBackfillIds.length - 25} more`);
        }
      }

      if (selectedAdmins.length > 0) {
        console.log('\nSelected admin users:');
        for (const entry of selectedAdmins.slice(0, 25)) {
          console.log(`- ${entry.userId} (${entry.email ?? 'no-email'})`);
        }
        if (selectedAdmins.length > 25) {
          console.log(`... and ${selectedAdmins.length - 25} more`);
        }
      }

      console.log('\nNo changes applied. Re-run with --apply to execute.');
      return;
    }

    await prisma.$transaction(async (tx) => {
      for (const userId of moderatorBackfillIds) {
        await tx.userRole.upsert({
          where: {
            userId_role: {
              userId,
              role: RoleName.community_moderator,
            },
          },
          update: {},
          create: {
            userId,
            role: RoleName.community_moderator,
          },
        });
      }

      for (const entry of adminPromotionsNeeded) {
        await tx.userRole.upsert({
          where: {
            userId_role: {
              userId: entry.userId,
              role: RoleName.community_admin,
            },
          },
          update: {},
          create: {
            userId: entry.userId,
            role: RoleName.community_admin,
          },
        });
      }

      if (options.dropAdminOnConvert && selectedAdmins.length > 0) {
        await tx.userRole.deleteMany({
          where: {
            role: RoleName.admin,
            userId: {
              in: selectedAdmins.map((entry) => entry.userId),
            },
          },
        });
      }
    });

    console.log('\nApplied successfully.');
    console.log(`community_moderator upserts: ${moderatorBackfillIds.length}`);
    console.log(`community_admin upserts: ${adminPromotionsNeeded.length}`);
    if (options.dropAdminOnConvert) {
      console.log(`admin removals: ${selectedAdmins.length}`);
    }
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
