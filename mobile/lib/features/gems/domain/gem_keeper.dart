import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/levels/data/models/user_level_model.dart';
import 'package:blocnet/features/projects/data/models/admin_model.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';

/// The hunter who keeps a gem, and how reliably, as far as the phone knows.
///
/// The standing and coverage come from the server (`ownerReliability` on the
/// project, or a full `/hunters/:id/reliability` read). Nothing here is
/// computed on the phone.
class GemKeeper {
  const GemKeeper({
    required this.profileId,
    required this.name,
    required this.standing,
    this.handle,
    this.avatarUrl,
    this.level,
    this.coverage,
    this.gemsOwned,
    this.cadenceDays,
    this.response,
    this.responseAnswered,
    this.responseAsked,
    this.followersTotal,
  });

  final String profileId;
  final String name;

  /// `@handle`, or null when the phone has no username for this hunter.
  final String? handle;
  final String? avatarUrl;
  final UserLevelModel? level;
  final ReliabilityStanding standing;
  final double? coverage;
  final int? gemsOwned;
  final double? cadenceDays;
  final double? response;
  final int? responseAnswered;
  final int? responseAsked;
  final int? followersTotal;

  /// "@handle" when known, else the display name.
  String get label => handle ?? name;

  /// "4 of 5 gems current", "80% of gems current", or null when the server
  /// has no coverage for this hunter yet.
  String? get coverageLine => coverageText(coverage, gemsOwned);

  /// What the public profile sheet opens with.
  Admin toAdmin() => Admin(
        id: profileId,
        name: name,
        username: handle ?? '',
        imageUrl: avatarUrl ?? '',
        followers: followersTotal ?? 0,
        currentLevel: level,
      );

  /// From a full reliability read (leaderboard row or profile read).
  factory GemKeeper.fromReliability(HunterReliability r) {
    return GemKeeper(
      profileId: r.profileId,
      name: r.name,
      handle: _handle(r.username),
      avatarUrl: r.avatarUrl,
      level: levelModelFrom(r.level),
      standing: r.standing,
      coverage: r.coverage,
      gemsOwned: r.gemsOwned,
      cadenceDays: r.cadenceDays,
      response: r.response,
      responseAnswered: r.responseAnswered,
      responseAsked: r.responseAsked,
      followersTotal: r.followersTotal,
    );
  }

  /// Who keeps [project]. [known] holds full reads by profile id (the
  /// leaderboard), which name a keeper who is not the project's admin.
  static GemKeeper? forProject(
    Project project, {
    Map<String, HunterReliability> known = const {},
  }) {
    final owner = project.ownerReliability;
    final admin = project.admin;
    if (owner == null) {
      if (admin == null || admin.id.isEmpty) return null;
      return _fromAdmin(admin, ReliabilityStanding.unknown, null);
    }
    final full = known[owner.profileId];
    if (full != null) {
      final keeper = GemKeeper.fromReliability(full);
      // The project read is newer than a cached leaderboard page.
      return keeper._withStanding(owner.standing, owner.coverage);
    }
    if (admin != null && admin.id == owner.profileId) {
      return _fromAdmin(admin, owner.standing, owner.coverage);
    }
    return GemKeeper(
      profileId: owner.profileId,
      name: 'Hunter',
      standing: owner.standing,
      coverage: owner.coverage,
    );
  }

  static GemKeeper _fromAdmin(
    Admin admin,
    ReliabilityStanding standing,
    double? coverage,
  ) {
    return GemKeeper(
      profileId: admin.id,
      name: admin.name,
      handle: _handle(admin.username),
      avatarUrl: admin.imageUrl,
      level: admin.currentLevel,
      standing: standing,
      coverage: coverage,
      followersTotal: admin.followers,
    );
  }

  GemKeeper _withStanding(ReliabilityStanding standing, double? coverage) {
    return GemKeeper(
      profileId: profileId,
      name: name,
      handle: handle,
      avatarUrl: avatarUrl,
      level: level,
      standing: standing,
      coverage: coverage ?? this.coverage,
      gemsOwned: gemsOwned,
      cadenceDays: cadenceDays,
      response: response,
      responseAnswered: responseAnswered,
      responseAsked: responseAsked,
      followersTotal: followersTotal,
    );
  }

  static String? _handle(String? raw) {
    final value = raw?.trim().replaceAll('@', '') ?? '';
    return value.isEmpty ? null : '@$value';
  }
}

/// "4 of 5 gems current" when the gem count is known, else a percentage.
String? coverageText(double? coverage, int? gemsOwned) {
  if (coverage == null) return null;
  final share = coverage.clamp(0.0, 1.0);
  if (gemsOwned != null && gemsOwned > 0) {
    final current = (share * gemsOwned).round();
    final noun = gemsOwned == 1 ? 'gem' : 'gems';
    return '$current of $gemsOwned $noun current';
  }
  return '${(share * 100).round()}% of gems current';
}

/// The level badge wants the full level model; reliability reads carry the
/// few fields the badge draws.
UserLevelModel? levelModelFrom(ReliabilityLevel? level) {
  if (level == null) return null;
  return UserLevelModel(
    id: level.id,
    slug: level.slug,
    name: level.name,
    description: '',
    iconUrl: level.iconUrl,
    level: level.level,
    requiredBnp: '0',
    requiredComments: 0,
    requiredDaysActive: 0,
    requiredQuests: 0,
    requiredUpdates: 0,
    requiredProjects: 0,
    color: level.color,
    isActive: true,
    sortOrder: level.level,
  );
}
