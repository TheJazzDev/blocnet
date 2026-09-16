import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_gem_detail_model.dart';
import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/models/project_invite_model.dart';
import 'package:blocnet/features/projects/data/models/project_proposal_model.dart';

/// Fixture data mirroring the approved canvas
/// (`docs/artifacts/blocnet-hunter-hub.html`): same names, same numbers.

/// Wednesday 16 Sep 2026, 12:00 local — the canvas's "now".
final DateTime hubNow = DateTime(2026, 9, 16, 12);

/// Friday 18:00 local — Terra Vault's stated deadline.
final DateTime fridayEvening = DateTime(2026, 9, 18, 18);

BigInt bnp(int whole) => BigInt.from(whole) * BigInt.from(10).pow(18);

HunterBoardGem gem(
  String name, {
  String tag = 'Ethereum',
  int followers = 0,
  GemState state = GemState.current,
  Duration ago = const Duration(days: 1),
  int? daysQuiet,
  String? lastTitle = 'An update',
  int waiting = 0,
  int reports = 0,
  DateTime? deadline,
  bool? neverUpdated,
  DateTime? listedAt,
}) {
  final touched = hubNow.subtract(ago);
  return HunterBoardGem(
    projectId: 'p-${name.toLowerCase().replaceAll(' ', '-')}',
    name: name,
    primaryTag: tag,
    followersCount: followers,
    listedAt: listedAt ?? hubNow.subtract(const Duration(days: 60)),
    lastActivityAt: touched,
    lastUpdate: lastTitle == null
        ? null
        : BoardGemLastUpdate(
            id: 'u-$name',
            title: lastTitle,
            publishedAt: touched,
          ),
    daysQuiet: daysQuiet ?? ago.inDays,
    state: state,
    membersWaiting: waiting,
    openReports: reports,
    nextDeadlineAt: deadline,
    neverUpdated: neverUpdated,
  );
}

HunterReliability reliability({
  String name = 'Jazzdev',
  String handle = 'jazzdev',
  int level = 15,
  String levelName = 'Pioneer',
  ReliabilityStanding standing = ReliabilityStanding.reliable,
  int answered = 4,
  int asked = 4,
  double? cadence = 5,
  int waiting = 0,
  int reports = 0,
  int gems = 5,
  int followers = 26465,
  int tips = 18240,
  bool withLevel = true,
}) {
  return HunterReliability(
    profileId: 'me',
    username: handle,
    displayName: name,
    level: withLevel
        ? ReliabilityLevel(
            id: 'l$level',
            slug: levelName.toLowerCase(),
            name: levelName,
            level: level,
            iconUrl: '',
          )
        : null,
    standing: standing,
    coverage: 1,
    cadenceDays: cadence,
    response: asked == 0 ? null : answered / asked,
    responseAnswered: answered,
    responseAsked: asked,
    gemsOwned: gems,
    updates30d: 10,
    followersTotal: followers,
    tipsReceivedTotal: bnp(tips),
    tipsCurrencyCode: 'BNP',
    tipsCurrencyDecimals: 18,
    membersWaiting: waiting,
    openReports: reports,
  );
}

HunterBoardGem coreMines([Duration ago = const Duration(hours: 3)]) =>
    gem('Core Mines', tag: 'Core', followers: 8412, ago: ago);
HunterBoardGem bless50ing() => gem('Bless50ing',
    tag: 'Telegram Network', followers: 3109, ago: const Duration(days: 1));
HunterBoardGem nebulaSwap() => gem('Nebula Swap',
    tag: 'Solana', followers: 12740, ago: const Duration(days: 2));
HunterBoardGem orbitLend([Duration ago = const Duration(days: 4)]) =>
    gem('Orbit Lend', tag: 'Ethereum', followers: 1884, ago: ago);
HunterBoardGem solarRelay() => gem('Solar Relay',
    tag: 'Binance Smart Chain', followers: 2204, ago: const Duration(days: 6));

HunterBoardGem haloPoints({int waiting = 31, int reports = 2}) => gem(
      'Halo Points',
      tag: 'Ethereum',
      followers: 4730,
      state: GemState.quiet,
      ago: const Duration(days: 19),
      lastTitle: 'Farming round 2 is live',
      waiting: waiting,
      reports: reports,
    );

HunterBoardGem terraVault({int waiting = 7}) => gem(
      'Terra Vault',
      tag: 'Ice Open Network',
      followers: 1402,
      state: GemState.due,
      ago: const Duration(days: 11),
      lastTitle: 'Vault caps raised to 5M',
      waiting: waiting,
      deadline: fridayEvening,
    );

HunterBoardGem aegisNode() => gem(
      'Aegis Node',
      tag: 'Binance Smart Chain',
      followers: 6015,
      state: GemState.quiet,
      ago: const Duration(days: 21),
      lastTitle: 'Node sale allocations sent',
      waiting: 28,
      reports: 3,
    );

HunterBoardGem prismYield() => gem(
      'Prism Yield',
      tag: 'Solana',
      followers: 88,
      state: GemState.due,
      lastTitle: null,
      daysQuiet: 12,
      listedAt: hubNow.subtract(const Duration(days: 12)),
    );

/// State 1 · All current.
HunterBoard allCurrentBoard() => HunterBoard(
      reliability: reliability(),
      gems: [
        coreMines(),
        bless50ing(),
        nebulaSwap(),
        orbitLend(),
        solarRelay()
      ],
    );

/// State 2 · One gem slipping.
HunterBoard slippingBoard() => HunterBoard(
      reliability: reliability(
        standing: ReliabilityStanding.slipping,
        answered: 2,
        asked: 5,
        cadence: 9,
        waiting: 38,
        reports: 2,
      ),
      gems: [
        haloPoints(),
        terraVault(),
        coreMines(),
        bless50ing(),
        nebulaSwap()
      ],
    );

/// State 3 · Day one.
HunterBoard dayOneBoard() => HunterBoard(
      reliability: reliability(
        name: 'Mikko',
        handle: 'mikko',
        level: 2,
        levelName: 'Explorer',
        standing: ReliabilityStanding.newHunter,
        answered: 0,
        asked: 0,
        cadence: null,
        gems: 0,
        followers: 0,
        tips: 0,
      ),
      gems: const [],
    );

/// State 4 · Invites and reviews.
HunterBoard invitesBoard() => HunterBoard(
      reliability: reliability(
        name: 'Ada',
        handle: 'ada',
        level: 9,
        levelName: 'Elite',
        answered: 3,
        asked: 3,
        cadence: 4,
        gems: 2,
      ),
      gems: [
        orbitLend(const Duration(hours: 5)),
        gem('Ice Drift',
            tag: 'Ice Open Network',
            followers: 962,
            ago: const Duration(days: 3)),
      ],
    );

ProjectInviteModel nebulaInvite() => ProjectInviteModel(
      id: 'inv-1',
      projectId: 'p-nebula-swap',
      projectName: 'Nebula Swap',
      projectSlug: 'nebula-swap',
      status: 'pending',
      createdAt: hubNow.subtract(const Duration(days: 1)),
      primaryTag: 'Solana',
      followersCount: 12740,
      updatesCount: 34,
      lastUpdateAt: hubNow.subtract(const Duration(days: 2)),
      inviterUsername: 'abtoonzz',
    );

ProjectProposalModel lumenPay() => ProjectProposalModel(
      id: 'pp-1',
      name: 'Lumen Pay',
      status: 'pending',
      createdAt: hubNow.subtract(const Duration(days: 2)),
    );

/// State 5 · A dozen gems.
HunterBoard dozenBoard() => HunterBoard(
      reliability: reliability(
        standing: ReliabilityStanding.slipping,
        answered: 6,
        asked: 9,
        cadence: 7,
        waiting: 52,
        reports: 3,
        gems: 12,
      ),
      gems: [
        aegisNode(),
        haloPoints(waiting: 19, reports: 0),
        terraVault(waiting: 5),
        for (var i = 0; i < 9; i++)
          gem('Current $i',
              tag: 'Solana', followers: 100 + i, ago: Duration(days: i % 6)),
      ],
    );

/// State 6 · The gem page, opened from Halo Points.
HunterGemDetail haloDetail({int waiting = 31, int reports = 2}) =>
    HunterGemDetail(
      gem: haloPoints(waiting: waiting, reports: reports),
      gapDays: 19,
      updates: [
        HunterGemEvent(
          id: 'e1',
          title: 'Farming round 2 is live — deposit before the cap fills',
          priority: 'high',
          createdAt: DateTime(2026, 8, 20, 10),
          likesCount: 412,
          commentsCount: 38,
          tipsAtomic: bnp(2100),
          tipsCurrencyCode: 'BNP',
          tipsCurrencyDecimals: 18,
        ),
        HunterGemEvent(
          id: 'e2',
          title: 'Points multiplier changed for LP positions',
          priority: 'medium',
          createdAt: DateTime(2026, 8, 6, 10),
          likesCount: 156,
          commentsCount: 11,
          tipsAtomic: BigInt.zero,
        ),
        HunterGemEvent(
          id: 'e3',
          title: "Halo Points listed — here's the diligence",
          priority: 'low',
          createdAt: DateTime(2026, 7, 28, 10),
          likesCount: 203,
          commentsCount: 27,
          tipsAtomic: bnp(640),
          tipsCurrencyCode: 'BNP',
          tipsCurrencyDecimals: 18,
        ),
      ],
    );
