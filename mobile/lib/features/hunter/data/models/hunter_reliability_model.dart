import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

/// A hunter's standing, as the backend computes it.
///
/// `newHunter` is the backend's `new` (a Dart keyword). [unknown] covers a
/// value this build does not know yet.
enum ReliabilityStanding {
  reliable,
  slipping,
  quiet,
  newHunter,
  unknown;

  static ReliabilityStanding fromApi(Object? raw) {
    switch (raw) {
      case 'reliable':
        return ReliabilityStanding.reliable;
      case 'slipping':
        return ReliabilityStanding.slipping;
      case 'quiet':
        return ReliabilityStanding.quiet;
      case 'new':
        return ReliabilityStanding.newHunter;
      default:
        return ReliabilityStanding.unknown;
    }
  }

  String get label {
    switch (this) {
      case ReliabilityStanding.reliable:
        return 'Reliable';
      case ReliabilityStanding.slipping:
        return 'Slipping';
      case ReliabilityStanding.quiet:
        return 'Quiet';
      case ReliabilityStanding.newHunter:
        return 'New';
      case ReliabilityStanding.unknown:
        return 'Unknown';
    }
  }
}

class ReliabilityLevel {
  const ReliabilityLevel({
    required this.id,
    required this.slug,
    required this.name,
    required this.level,
    required this.iconUrl,
    this.color,
  });

  final String id;
  final String slug;
  final String name;
  final int level;
  final String iconUrl;
  final String? color;

  static ReliabilityLevel? fromApi(Object? raw) {
    if (raw is! Map) return null;
    final json = jsonMap(raw);
    return ReliabilityLevel(
      id: jsonString(json['id']),
      slug: jsonString(json['slug']),
      name: jsonString(json['name']),
      level: jsonInt(json['level']),
      iconUrl: jsonString(json['iconUrl']),
      color: jsonStringOrNull(json['color']),
    );
  }
}

/// `GET /hunters/:profileId/reliability`, and the header of the hunter board.
///
/// Shares ([coverage], [response]) are 0–1. Every nullable score is null when
/// the backend has too little evidence to say — show that as "not enough
/// data", never as zero.
class HunterReliability {
  const HunterReliability({
    required this.profileId,
    required this.standing,
    required this.gemsOwned,
    required this.updates30d,
    required this.followersTotal,
    required this.tipsReceivedTotal,
    required this.membersWaiting,
    required this.openReports,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.level,
    this.coverage,
    this.cadenceDays,
    this.response,
    this.tipsCurrencyCode,
    this.tipsCurrencyDecimals,
    this.computedAt,
    this.responseAnswered,
    this.responseAsked,
    this.escalatesAtWaiting = defaultEscalatesAtWaiting,
  });

  /// Where the backend puts a gem in the reassignment queue when the field is
  /// missing from an older payload.
  static const int defaultEscalatesAtWaiting = 50;

  final String profileId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final ReliabilityLevel? level;
  final ReliabilityStanding standing;
  final double? coverage;
  final double? cadenceDays;
  final double? response;
  final int gemsOwned;
  final int updates30d;
  final int followersTotal;

  /// Atomic units of [tipsCurrencyCode].
  final BigInt tipsReceivedTotal;
  final String? tipsCurrencyCode;
  final int? tipsCurrencyDecimals;
  final int membersWaiting;
  final int openReports;
  final DateTime? computedAt;

  /// Asks that got an update within a week, and asks in total. Null on a
  /// backend that predates the fields; [response] is the share either way.
  final int? responseAnswered;
  final int? responseAsked;

  /// Members waiting at which a gem is queued for reassignment.
  final int escalatesAtWaiting;

  factory HunterReliability.fromApi(Map<String, dynamic> json) {
    return HunterReliability(
      profileId: jsonString(json['profileId']),
      username: jsonStringOrNull(json['username']),
      displayName: jsonStringOrNull(json['displayName']),
      avatarUrl: jsonStringOrNull(json['avatarUrl']),
      level: ReliabilityLevel.fromApi(json['level']),
      standing: ReliabilityStanding.fromApi(json['standing']),
      coverage: jsonDoubleOrNull(json['coverage']),
      cadenceDays: jsonDoubleOrNull(json['cadenceDays']),
      response: jsonDoubleOrNull(json['response']),
      gemsOwned: jsonInt(json['gemsOwned']),
      updates30d: jsonInt(json['updates30d']),
      followersTotal: jsonInt(json['followersTotal']),
      tipsReceivedTotal: jsonBigInt(json['tipsReceivedTotal']),
      tipsCurrencyCode: jsonStringOrNull(json['tipsCurrencyCode']),
      tipsCurrencyDecimals: jsonIntOrNull(json['tipsCurrencyDecimals']),
      membersWaiting: jsonInt(json['membersWaiting']),
      openReports: jsonInt(json['openReports']),
      computedAt: jsonDateOrNull(json['computedAt']),
      responseAnswered: jsonIntOrNull(json['responseAnswered']),
      responseAsked: jsonIntOrNull(json['responseAsked']),
      escalatesAtWaiting: jsonInt(
        json['escalatesAtWaiting'],
        fallback: defaultEscalatesAtWaiting,
      ),
    );
  }

  String get name => displayName ?? username ?? 'Hunter';
}

/// The compact owner reliability carried on project list/detail responses as
/// `ownerReliability`.
class OwnerReliability {
  const OwnerReliability({
    required this.profileId,
    required this.standing,
    this.coverage,
  });

  final String profileId;
  final ReliabilityStanding standing;
  final double? coverage;

  static OwnerReliability? fromApi(Object? raw) {
    if (raw is! Map) return null;
    final json = jsonMap(raw);
    return OwnerReliability(
      profileId: jsonString(json['profileId']),
      standing: ReliabilityStanding.fromApi(json['standing']),
      coverage: jsonDoubleOrNull(json['coverage']),
    );
  }
}
