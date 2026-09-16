import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/hunter/data/models/reliability_json.dart';

/// How a moderator closed the reports on a quiet gem. There is no
/// "reassign": that is decided by a person in the console.
enum InactiveGemOutcome {
  hunterContacted('hunter_contacted', 'Hunter contacted'),
  noAction('no_action', 'No action needed'),
  escalated('escalated', 'Escalate to admins');

  const InactiveGemOutcome(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class InactiveGemHunter {
  const InactiveGemHunter({
    required this.id,
    required this.standing,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.coverage,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final ReliabilityStanding standing;
  final double? coverage;

  factory InactiveGemHunter.fromApi(Map<String, dynamic> json) {
    return InactiveGemHunter(
      id: jsonString(json['id']),
      username: jsonStringOrNull(json['username']),
      displayName: jsonStringOrNull(json['displayName']),
      avatarUrl: jsonStringOrNull(json['avatarUrl']),
      standing: ReliabilityStanding.fromApi(json['standing']),
      coverage: jsonDoubleOrNull(json['coverage']),
    );
  }

  String get name => displayName ?? username ?? 'Unknown hunter';
}

/// One row of `GET /community/moderation/inactive-gems`: a gem members have
/// reported as abandoned, with at least one report still open.
class InactiveGemReport {
  const InactiveGemReport({
    required this.projectId,
    required this.projectName,
    required this.projectSlug,
    required this.projectStatus,
    required this.primaryTag,
    required this.hunters,
    required this.openReports,
    required this.firstReportedAt,
    required this.lastActivityAt,
    required this.daysQuiet,
    required this.membersWaiting,
  });

  final String projectId;
  final String projectName;
  final String projectSlug;
  final String projectStatus;
  final String primaryTag;
  final List<InactiveGemHunter> hunters;
  final int openReports;
  final DateTime firstReportedAt;
  final DateTime lastActivityAt;
  final int daysQuiet;
  final int membersWaiting;

  factory InactiveGemReport.fromApi(Map<String, dynamic> json) {
    final project = jsonMap(json['project']);
    return InactiveGemReport(
      projectId: jsonString(project['id']),
      projectName: jsonString(project['name'], fallback: 'Unnamed gem'),
      projectSlug: jsonString(project['slug']),
      projectStatus: jsonString(project['status'], fallback: 'active'),
      primaryTag: jsonString(project['primaryTag']),
      hunters: jsonMapList(json['hunters'])
          .map(InactiveGemHunter.fromApi)
          .toList(growable: false),
      openReports: jsonInt(json['openReports']),
      firstReportedAt: jsonDate(json['firstReportedAt']),
      lastActivityAt: jsonDate(json['lastActivityAt']),
      daysQuiet: jsonInt(json['daysQuiet']),
      membersWaiting: jsonInt(json['membersWaiting']),
    );
  }

  /// Parses the queue envelope `{ data, total, limit, offset }`.
  static List<InactiveGemReport> listFromApi(Object? response) {
    return jsonMapList(jsonMap(response)['data'])
        .map(InactiveGemReport.fromApi)
        .toList(growable: false);
  }
}
