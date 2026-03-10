enum CommunityReportStatus {
  open,
  resolved,
  dismissed;

  static CommunityReportStatus fromApi(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'resolved':
        return CommunityReportStatus.resolved;
      case 'dismissed':
        return CommunityReportStatus.dismissed;
      case 'open':
      default:
        return CommunityReportStatus.open;
    }
  }

  String get apiValue {
    switch (this) {
      case CommunityReportStatus.open:
        return 'open';
      case CommunityReportStatus.resolved:
        return 'resolved';
      case CommunityReportStatus.dismissed:
        return 'dismissed';
    }
  }

  String get label {
    switch (this) {
      case CommunityReportStatus.open:
        return 'Open';
      case CommunityReportStatus.resolved:
        return 'Resolved';
      case CommunityReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}

enum CommunityContentModerationStatus {
  active,
  hidden,
  archived;

  String get apiValue {
    switch (this) {
      case CommunityContentModerationStatus.active:
        return 'active';
      case CommunityContentModerationStatus.hidden:
        return 'hidden';
      case CommunityContentModerationStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case CommunityContentModerationStatus.active:
        return 'Restore';
      case CommunityContentModerationStatus.hidden:
        return 'Hide';
      case CommunityContentModerationStatus.archived:
        return 'Archive';
    }
  }
}

enum CommunityReportTargetType {
  communityPost,
  communityComment,
  userProfile;

  static CommunityReportTargetType fromApi(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'community_comment':
        return CommunityReportTargetType.communityComment;
      case 'user_profile':
        return CommunityReportTargetType.userProfile;
      case 'community_post':
      default:
        return CommunityReportTargetType.communityPost;
    }
  }

  String get apiValue {
    switch (this) {
      case CommunityReportTargetType.communityPost:
        return 'community_post';
      case CommunityReportTargetType.communityComment:
        return 'community_comment';
      case CommunityReportTargetType.userProfile:
        return 'user_profile';
    }
  }

  String get label {
    switch (this) {
      case CommunityReportTargetType.communityPost:
        return 'Post';
      case CommunityReportTargetType.communityComment:
        return 'Comment';
      case CommunityReportTargetType.userProfile:
        return 'Profile';
    }
  }
}

enum CommunityReportReason {
  spam,
  harassment,
  hateSpeech,
  misinformation,
  inappropriateContent,
  scamOrFraud,
  violatesRules,
  other;

  String get label {
    switch (this) {
      case CommunityReportReason.spam:
        return 'Spam or promotional content';
      case CommunityReportReason.harassment:
        return 'Harassment or bullying';
      case CommunityReportReason.hateSpeech:
        return 'Hate speech or discrimination';
      case CommunityReportReason.misinformation:
        return 'False or misleading information';
      case CommunityReportReason.inappropriateContent:
        return 'Inappropriate or offensive content';
      case CommunityReportReason.scamOrFraud:
        return 'Scam or fraudulent activity';
      case CommunityReportReason.violatesRules:
        return 'Violates community rules';
      case CommunityReportReason.other:
        return 'Other (please specify)';
    }
  }

  String get description {
    switch (this) {
      case CommunityReportReason.spam:
        return 'Unsolicited promotional content or repetitive posts';
      case CommunityReportReason.harassment:
        return 'Targeting or threatening specific individuals';
      case CommunityReportReason.hateSpeech:
        return 'Content that attacks people based on protected characteristics';
      case CommunityReportReason.misinformation:
        return 'Deliberately false or misleading information';
      case CommunityReportReason.inappropriateContent:
        return 'Content that is offensive, explicit, or not suitable';
      case CommunityReportReason.scamOrFraud:
        return 'Fraudulent schemes or attempts to deceive users';
      case CommunityReportReason.violatesRules:
        return 'Breaks community guidelines or platform rules';
      case CommunityReportReason.other:
        return 'A reason not listed above';
    }
  }
}

class CreateCommunityReportRequest {
  const CreateCommunityReportRequest({
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.details,
  });

  final CommunityReportTargetType targetType;
  final String targetId;
  final String reason;
  final String? details;

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType.apiValue,
      'targetId': targetId,
      'reason': reason,
      if (details != null && details!.trim().isNotEmpty) 'details': details,
    };
  }
}

class CommunityActorSummary {
  const CommunityActorSummary({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  String get bestLabel {
    final name = displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return email;
  }

  factory CommunityActorSummary.fromApi(Map<String, dynamic> json) {
    return CommunityActorSummary(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
    );
  }
}

class CommunityModerationTargetUser {
  const CommunityModerationTargetUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String email;
  final String? username;
  final String? displayName;

  String get bestLabel {
    final display = displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    final handle = username?.trim() ?? '';
    if (handle.isNotEmpty) return handle;
    return email;
  }

  factory CommunityModerationTargetUser.fromApi(Map<String, dynamic> json) {
    return CommunityModerationTargetUser(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
    );
  }
}

class CommunityModerationReport {
  const CommunityModerationReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.targetUserId,
    required this.reason,
    required this.details,
    required this.status,
    required this.reviewedById,
    required this.reviewedAt,
    required this.resolutionNote,
    required this.createdAt,
    required this.updatedAt,
    required this.reporter,
    required this.reviewer,
    required this.targetUser,
  });

  final String id;
  final String reporterId;
  final CommunityReportTargetType targetType;
  final String targetId;
  final String? targetUserId;
  final String reason;
  final String? details;
  final CommunityReportStatus status;
  final String? reviewedById;
  final DateTime? reviewedAt;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommunityActorSummary reporter;
  final CommunityActorSummary? reviewer;
  final CommunityModerationTargetUser? targetUser;

  bool get isOpen => status == CommunityReportStatus.open;

  factory CommunityModerationReport.fromApi(Map<String, dynamic> json) {
    final reporterRaw = json['reporter'];
    final reviewerRaw = json['reviewer'];
    final targetUserRaw = json['targetUser'];
    return CommunityModerationReport(
      id: (json['id'] ?? '').toString(),
      reporterId: (json['reporterId'] ?? '').toString(),
      targetType:
          CommunityReportTargetType.fromApi(json['targetType']?.toString()),
      targetId: (json['targetId'] ?? '').toString(),
      targetUserId: json['targetUserId']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      details: json['details']?.toString(),
      status: CommunityReportStatus.fromApi(json['status']?.toString()),
      reviewedById: json['reviewedById']?.toString(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      reporter: reporterRaw is Map<String, dynamic>
          ? CommunityActorSummary.fromApi(reporterRaw)
          : const CommunityActorSummary(id: '', email: '', displayName: null),
      reviewer: reviewerRaw is Map<String, dynamic>
          ? CommunityActorSummary.fromApi(reviewerRaw)
          : null,
      targetUser: targetUserRaw is Map<String, dynamic>
          ? CommunityModerationTargetUser.fromApi(targetUserRaw)
          : null,
    );
  }
}

class CommunityModerationReportsPage {
  const CommunityModerationReportsPage({
    required this.reports,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<CommunityModerationReport> reports;
  final int total;
  final int limit;
  final int offset;

  factory CommunityModerationReportsPage.fromApi(Map<String, dynamic> json) {
    final rows = (json['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CommunityModerationReport.fromApi)
        .toList();

    int toInt(dynamic value, int fallback) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return CommunityModerationReportsPage(
      reports: rows,
      total: toInt(json['total'], rows.length),
      limit: toInt(json['limit'], rows.length),
      offset: toInt(json['offset'], 0),
    );
  }
}

class CommunityModerationUserState {
  const CommunityModerationUserState({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    required this.communityWarnCount,
    required this.communityLastWarnedAt,
    required this.communityMutedUntil,
    required this.communitySuspendedUntil,
    required this.communityPostingRestrictedUntil,
    required this.communityCommentingRestrictedUntil,
    required this.roles,
  });

  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final int communityWarnCount;
  final DateTime? communityLastWarnedAt;
  final DateTime? communityMutedUntil;
  final DateTime? communitySuspendedUntil;
  final DateTime? communityPostingRestrictedUntil;
  final DateTime? communityCommentingRestrictedUntil;
  final List<String> roles;

  String get bestLabel {
    final display = displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    final handle = username?.trim() ?? '';
    if (handle.isNotEmpty) return handle;
    return email;
  }

  factory CommunityModerationUserState.fromApi(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final roles = (json['roles'] as List? ?? const [])
        .map((role) => role.toString().trim().toLowerCase())
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList();

    return CommunityModerationUserState(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      communityWarnCount: toInt(json['communityWarnCount']),
      communityLastWarnedAt:
          DateTime.tryParse(json['communityLastWarnedAt']?.toString() ?? ''),
      communityMutedUntil:
          DateTime.tryParse(json['communityMutedUntil']?.toString() ?? ''),
      communitySuspendedUntil:
          DateTime.tryParse(json['communitySuspendedUntil']?.toString() ?? ''),
      communityPostingRestrictedUntil: DateTime.tryParse(
        json['communityPostingRestrictedUntil']?.toString() ?? '',
      ),
      communityCommentingRestrictedUntil: DateTime.tryParse(
        json['communityCommentingRestrictedUntil']?.toString() ?? '',
      ),
      roles: roles,
    );
  }
}
