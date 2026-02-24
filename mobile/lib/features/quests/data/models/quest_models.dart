import 'package:blocnet/features/badges/data/models/badge_models.dart';

class QuestModel {
  const QuestModel({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.rewardPoints,
    this.rewardBadgeId,
    this.targetUrl,
    this.targetAction,
    required this.verificationMethod,
    this.requiredProof,
    required this.isActive,
    required this.sortOrder,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final QuestType type;
  final BadgeCategory category;
  final int rewardPoints;
  final String? rewardBadgeId;
  final String? targetUrl;
  final String? targetAction;
  final String verificationMethod;
  final String? requiredProof;
  final bool isActive;
  final int sortOrder;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory QuestModel.fromApi(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: QuestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestType.internalAction,
      ),
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BadgeCategory.engagement,
      ),
      rewardPoints: int.tryParse(json['rewardPoints']?.toString() ?? '') ?? 0,
      rewardBadgeId: json['rewardBadgeId'] as String?,
      targetUrl: json['targetUrl'] as String?,
      targetAction: json['targetAction'] as String?,
      verificationMethod: json['verificationMethod'] as String? ?? 'manual',
      requiredProof: json['requiredProof'] as String?,
      isActive: json['isActive'] == true,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get requiresManualVerification => verificationMethod == 'manual';
  bool get isAutoVerified => verificationMethod == 'auto';
}

enum QuestType {
  externalLink,
  internalAction,
  socialMedia,
}

extension QuestTypeExtension on QuestType {
  String get displayName {
    switch (this) {
      case QuestType.externalLink:
        return 'External Link';
      case QuestType.internalAction:
        return 'Action';
      case QuestType.socialMedia:
        return 'Social Media';
    }
  }

  int get icon {
    switch (this) {
      case QuestType.externalLink:
        return 0xe157; // link icon
      case QuestType.internalAction:
        return 0xe86c; // check_circle icon
      case QuestType.socialMedia:
        return 0xe80e; // share icon
    }
  }
}

enum QuestStatus {
  notStarted,
  inProgress,
  pendingVerification,
  completed,
}

extension QuestStatusExtension on QuestStatus {
  String get displayName {
    switch (this) {
      case QuestStatus.notStarted:
        return 'Not Started';
      case QuestStatus.inProgress:
        return 'In Progress';
      case QuestStatus.pendingVerification:
        return 'Pending Verification';
      case QuestStatus.completed:
        return 'Completed';
    }
  }

  int get color {
    switch (this) {
      case QuestStatus.notStarted:
        return 0xFF9E9E9E; // Gray
      case QuestStatus.inProgress:
        return 0xFF2196F3; // Blue
      case QuestStatus.pendingVerification:
        return 0xFFFF9800; // Orange
      case QuestStatus.completed:
        return 0xFF4CAF50; // Green
    }
  }
}

class UserQuestModel {
  const UserQuestModel({
    required this.id,
    required this.userId,
    required this.questId,
    required this.status,
    required this.progress,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.quest,
  });

  final String id;
  final String userId;
  final String questId;
  final QuestStatus status;
  final int progress;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final QuestModel quest;

  factory UserQuestModel.fromApi(Map<String, dynamic> json) {
    return UserQuestModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questId: json['questId'] as String,
      status: QuestStatus.values.firstWhere(
        (e) => _snakeToCamel(e.name) == json['status'],
        orElse: () => QuestStatus.notStarted,
      ),
      progress: int.tryParse(json['progress']?.toString() ?? '') ?? 0,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      quest: QuestModel.fromApi(json['quest'] as Map<String, dynamic>),
    );
  }
}

class UserQuestsResponse {
  const UserQuestsResponse({
    required this.quests,
    required this.totalCount,
    required this.completedCount,
    required this.inProgressCount,
  });

  final List<UserQuestModel> quests;
  final int totalCount;
  final int completedCount;
  final int inProgressCount;

  factory UserQuestsResponse.fromApi(Map<String, dynamic> json) {
    return UserQuestsResponse(
      quests: (json['quests'] as List<dynamic>? ?? [])
          .map((e) => UserQuestModel.fromApi(e as Map<String, dynamic>))
          .toList(),
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '') ?? 0,
      completedCount: int.tryParse(json['completedCount']?.toString() ?? '') ?? 0,
      inProgressCount: int.tryParse(json['inProgressCount']?.toString() ?? '') ?? 0,
    );
  }
}

class QuestSubmissionModel {
  const QuestSubmissionModel({
    required this.id,
    required this.userQuestId,
    required this.userId,
    this.proofUrl,
    this.proofText,
    this.screenshot,
    required this.verificationStatus,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    required this.submittedAt,
  });

  final String id;
  final String userQuestId;
  final String userId;
  final String? proofUrl;
  final String? proofText;
  final String? screenshot;
  final String verificationStatus;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final DateTime submittedAt;

  factory QuestSubmissionModel.fromApi(Map<String, dynamic> json) {
    return QuestSubmissionModel(
      id: json['id'] as String,
      userQuestId: json['userQuestId'] as String,
      userId: json['userId'] as String,
      proofUrl: json['proofUrl'] as String?,
      proofText: json['proofText'] as String?,
      screenshot: json['screenshot'] as String?,
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: DateTime.tryParse(json['submittedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// Helper function to convert snake_case to camelCase
String _snakeToCamel(String snake) {
  if (snake.isEmpty) return snake;
  final parts = snake.split('_');
  if (parts.length == 1) return snake;

  final firstPart = parts.first;
  final rest = parts.skip(1).map((part) {
    if (part.isEmpty) return part;
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }).join('');

  return firstPart + rest;
}
