import 'package:blocnet/features/comments/data/models/comment_model.dart';
import 'package:blocnet/services/api/api_client.dart';

class CommentsApiRepository {
  CommentsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CommentModel>> fetchComments(
    String updateId, {
    int limit = 40,
    String? beforeCreatedAt,
    String? beforeId,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
    };
    if (beforeCreatedAt != null && beforeCreatedAt.isNotEmpty) {
      query['beforeCreatedAt'] = beforeCreatedAt;
    }
    if (beforeId != null && beforeId.isNotEmpty) {
      query['beforeId'] = beforeId;
    }

    final response =
        await _apiClient.get('/updates/$updateId/comments', query: query);

    if (response is! List) return [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(CommentModel.fromApi)
        .toList();
  }

  Future<CommentModel?> createComment({
    required String updateId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      '/updates/$updateId/comments',
      body: {'content': content},
    );

    if (response is! Map<String, dynamic>) return null;
    return CommentModel.fromApi(response);
  }

  Future<CommentModel?> updateComment({
    required String commentId,
    required String content,
  }) async {
    final response = await _apiClient.patch(
      '/comments/$commentId',
      body: {'content': content},
    );

    if (response is! Map<String, dynamic>) return null;
    return CommentModel.fromApi(response);
  }

  Future<bool> deleteComment(String commentId) async {
    final response = await _apiClient.delete('/comments/$commentId');
    if (response is! Map<String, dynamic>) return true;
    return response['deleted'] == true;
  }
}
