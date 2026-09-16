import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/data/models/pending_handover_model.dart';
import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

/// One of the hunter's own updates on a gem, as the gem page lists it.
class HunterGemEvent {
  const HunterGemEvent({
    required this.id,
    required this.title,
    required this.priority,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.tipsAtomic,
    this.editedAt,
    this.tipsCurrencyCode,
    this.tipsCurrencyDecimals,
  });

  final String id;
  final String title;

  /// `low` | `medium` | `high`, as the backend sends urgency.
  final String priority;
  final DateTime createdAt;
  final DateTime? editedAt;
  final int likesCount;
  final int commentsCount;

  /// Atomic units of [tipsCurrencyCode] tipped on this update.
  final BigInt tipsAtomic;
  final String? tipsCurrencyCode;
  final int? tipsCurrencyDecimals;

  factory HunterGemEvent.fromApi(Map<String, dynamic> json) {
    return HunterGemEvent(
      id: jsonString(json['id']),
      title: jsonString(json['title']),
      priority: jsonString(json['priority'], fallback: 'low').toLowerCase(),
      createdAt: jsonDate(json['createdAt']),
      editedAt: jsonDateOrNull(json['editedAt']),
      likesCount: jsonInt(json['likesCount']),
      commentsCount: jsonInt(json['commentsCount']),
      tipsAtomic: jsonBigInt(json['tipsAtomic']),
      tipsCurrencyCode: jsonStringOrNull(json['tipsCurrencyCode']),
      tipsCurrencyDecimals: jsonIntOrNull(json['tipsCurrencyDecimals']),
    );
  }
}

/// `GET /me/hunter/gems/:projectId` — one gem and the hunter's updates on it,
/// newest first.
class HunterGemDetail {
  const HunterGemDetail({
    required this.gem,
    required this.updates,
    this.gapDays,
    this.pendingHandover,
  });

  final HunterBoardGem gem;
  final List<HunterGemEvent> updates;

  /// Days since the newest update, when the backend considers it a gap worth
  /// drawing. Null otherwise.
  final int? gapDays;

  /// The caller's open handover of this gem (`gem.pendingHandover`), if any.
  final PendingHandover? pendingHandover;

  factory HunterGemDetail.fromApi(Map<String, dynamic> json) {
    final gem = jsonMap(json['gem']);
    return HunterGemDetail(
      gem: HunterBoardGem.fromApi(gem),
      updates: jsonMapList(json['updates'])
          .map(HunterGemEvent.fromApi)
          .toList(growable: false),
      gapDays: jsonIntOrNull(json['gapDays']),
      pendingHandover: PendingHandover.fromApi(gem['pendingHandover']),
    );
  }
}
