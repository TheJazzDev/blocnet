import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

/// The hunter a pending handover was offered to.
class HandoverHunter {
  const HandoverHunter({
    required this.id,
    required this.username,
    this.displayName,
  });

  final String id;
  final String username;
  final String? displayName;

  factory HandoverHunter.fromApi(Map<String, dynamic> json) {
    return HandoverHunter(
      id: jsonString(json['id']),
      username: jsonString(json['username']),
      displayName: jsonStringOrNull(json['displayName']),
    );
  }
}

/// `gem.pendingHandover` — the caller's open handover invite for a gem.
class PendingHandover {
  const PendingHandover({
    required this.inviteId,
    required this.hunter,
    required this.createdAt,
  });

  final String inviteId;
  final HandoverHunter hunter;
  final DateTime createdAt;

  /// Null when the backend sends none (or one without an invite id).
  static PendingHandover? fromApi(Object? raw) {
    if (raw is! Map) return null;
    final json = jsonMap(raw);
    final inviteId = jsonString(json['inviteId']);
    if (inviteId.isEmpty) return null;
    return PendingHandover(
      inviteId: inviteId,
      hunter: HandoverHunter.fromApi(jsonMap(json['hunter'])),
      createdAt: jsonDate(json['createdAt']),
    );
  }
}
