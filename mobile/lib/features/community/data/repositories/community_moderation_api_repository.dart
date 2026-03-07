import 'package:blocnet/features/community/data/models/community_moderation_models.dart';
import 'package:blocnet/services/api/api_client.dart';

class CommunityModerationApiRepository {
  CommunityModerationApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<CommunityModerationReportsPage> fetchReports({
    int limit = 20,
    int offset = 0,
    String? q,
    CommunityReportStatus? status,
    CommunityReportTargetType? targetType,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };
    final search = q?.trim() ?? '';
    if (search.isNotEmpty) {
      query['q'] = search;
    }
    if (status != null) {
      query['status'] = status.apiValue;
    }
    if (targetType != null) {
      query['targetType'] = targetType.apiValue;
    }

    final response = await _apiClient.get(
      '/community/moderation/reports',
      query: query,
    );

    if (response is! Map<String, dynamic>) {
      return const CommunityModerationReportsPage(
        reports: [],
        total: 0,
        limit: 20,
        offset: 0,
      );
    }

    return CommunityModerationReportsPage.fromApi(response);
  }

  Future<void> reviewReport({
    required String reportId,
    required CommunityReportStatus status,
    String? note,
  }) async {
    if (status == CommunityReportStatus.open) {
      throw ApiException('Review status cannot be open.');
    }

    await _apiClient.patch(
      '/community/moderation/reports/$reportId',
      body: {
        'status': status.apiValue,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<void> moderateCommunityPostStatus({
    required String postId,
    required CommunityContentModerationStatus status,
    required String reason,
  }) async {
    await _apiClient.patch(
      '/admin/content/community-posts/$postId/status',
      body: {
        'status': status.apiValue,
        'reason': reason.trim(),
      },
    );
  }

  Future<void> moderateCommunityCommentStatus({
    required String commentId,
    required CommunityContentModerationStatus status,
    required String reason,
  }) async {
    await _apiClient.patch(
      '/admin/content/community-comments/$commentId/status',
      body: {
        'status': status.apiValue,
        'reason': reason.trim(),
      },
    );
  }

  Future<CommunityModerationUserState> getUserState(String userId) async {
    final response =
        await _apiClient.get('/community/moderation/users/$userId/state');
    if (response is! Map<String, dynamic>) {
      throw ApiException('Invalid moderation user state response.');
    }

    return CommunityModerationUserState.fromApi(response);
  }

  Future<CommunityModerationUserState> issueWarning({
    required String userId,
    required String reason,
    String? reportId,
  }) async {
    final response = await _apiClient.post(
      '/community/moderation/users/$userId/warnings',
      body: {
        'reason': reason.trim(),
        if (reportId != null && reportId.trim().isNotEmpty)
          'reportId': reportId.trim(),
      },
    );
    return _parseUserStateResponse(response);
  }

  Future<CommunityModerationUserState> applyMute({
    required String userId,
    required int durationHours,
    required String reason,
    String? reportId,
  }) async {
    final response = await _apiClient.post(
      '/community/moderation/users/$userId/mutes',
      body: {
        'durationHours': durationHours,
        'reason': reason.trim(),
        if (reportId != null && reportId.trim().isNotEmpty)
          'reportId': reportId.trim(),
      },
    );
    return _parseUserStateResponse(response);
  }

  Future<CommunityModerationUserState> applySuspension({
    required String userId,
    required int durationHours,
    required String reason,
    String? reportId,
  }) async {
    final response = await _apiClient.post(
      '/community/moderation/users/$userId/suspensions',
      body: {
        'durationHours': durationHours,
        'reason': reason.trim(),
        if (reportId != null && reportId.trim().isNotEmpty)
          'reportId': reportId.trim(),
      },
    );
    return _parseUserStateResponse(response);
  }

  Future<CommunityModerationUserState> applyRestrictions({
    required String userId,
    required String reason,
    int? postingHours,
    int? commentingHours,
    String? reportId,
  }) async {
    final response = await _apiClient.post(
      '/community/moderation/users/$userId/restrictions',
      body: {
        if (postingHours != null) 'postingHours': postingHours,
        if (commentingHours != null) 'commentingHours': commentingHours,
        'reason': reason.trim(),
        if (reportId != null && reportId.trim().isNotEmpty)
          'reportId': reportId.trim(),
      },
    );
    return _parseUserStateResponse(response);
  }

  Future<CommunityModerationUserState> clearRestrictions({
    required String userId,
    required String reason,
    String? reportId,
  }) async {
    final response = await _apiClient.post(
      '/community/moderation/users/$userId/restrictions/clear',
      body: {
        'reason': reason.trim(),
        if (reportId != null && reportId.trim().isNotEmpty)
          'reportId': reportId.trim(),
      },
    );
    return _parseUserStateResponse(response);
  }

  CommunityModerationUserState _parseUserStateResponse(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw ApiException('Invalid moderation response.');
    }
    return CommunityModerationUserState.fromApi(response);
  }
}
