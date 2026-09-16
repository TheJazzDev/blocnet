import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

/// How much a gem needs its hunter, as the backend decides it
/// (current < 10 days quiet ≤ due < 14 days ≤ quiet).
enum GemState {
  current,
  due,
  quiet,
  unknown;

  static GemState fromApi(Object? raw) {
    switch (raw) {
      case 'current':
        return GemState.current;
      case 'due':
        return GemState.due;
      case 'quiet':
        return GemState.quiet;
      default:
        return GemState.unknown;
    }
  }
}

class BoardGemLastUpdate {
  const BoardGemLastUpdate({
    required this.id,
    required this.title,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final DateTime publishedAt;

  static BoardGemLastUpdate? fromApi(Object? raw) {
    if (raw is! Map) return null;
    final json = jsonMap(raw);
    return BoardGemLastUpdate(
      id: jsonString(json['id']),
      title: jsonString(json['title']),
      publishedAt: jsonDate(json['publishedAt']),
    );
  }
}

/// One gem on the hunter's own board.
class HunterBoardGem {
  const HunterBoardGem({
    required this.projectId,
    required this.name,
    required this.primaryTag,
    required this.followersCount,
    required this.listedAt,
    required this.lastActivityAt,
    required this.daysQuiet,
    required this.state,
    required this.membersWaiting,
    required this.openReports,
    this.logoUrl,
    this.lastUpdate,
    this.nextDeadlineAt,
  });

  final String projectId;
  final String name;
  final String? logoUrl;
  final String primaryTag;
  final int followersCount;
  final DateTime listedAt;
  final DateTime lastActivityAt;

  /// Null when the gem has never had a published update.
  final BoardGemLastUpdate? lastUpdate;
  final int daysQuiet;
  final GemState state;
  final int membersWaiting;
  final int openReports;
  final DateTime? nextDeadlineAt;

  factory HunterBoardGem.fromApi(Map<String, dynamic> json) {
    return HunterBoardGem(
      projectId: jsonString(json['projectId']),
      name: jsonString(json['name']),
      logoUrl: jsonStringOrNull(json['logoUrl']),
      primaryTag: jsonString(json['primaryTag']),
      followersCount: jsonInt(json['followersCount']),
      listedAt: jsonDate(json['listedAt']),
      lastActivityAt: jsonDate(json['lastActivityAt']),
      lastUpdate: BoardGemLastUpdate.fromApi(json['lastUpdate']),
      daysQuiet: jsonInt(json['daysQuiet']),
      state: GemState.fromApi(json['state']),
      membersWaiting: jsonInt(json['membersWaiting']),
      openReports: jsonInt(json['openReports']),
      nextDeadlineAt: jsonDateOrNull(json['nextDeadlineAt']),
    );
  }
}

/// `GET /me/hunter/board`. [gems] arrive already sorted worst first; keep
/// that order.
class HunterBoard {
  const HunterBoard({required this.reliability, required this.gems});

  final HunterReliability reliability;
  final List<HunterBoardGem> gems;

  factory HunterBoard.fromApi(Map<String, dynamic> json) {
    return HunterBoard(
      reliability: HunterReliability.fromApi(jsonMap(json['reliability'])),
      gems: jsonMapList(json['gems'])
          .map(HunterBoardGem.fromApi)
          .toList(growable: false),
    );
  }
}
