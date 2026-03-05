import 'package:blocnet/features/community/data/models/community_post_comment_model.dart';
import 'package:blocnet/features/community/data/models/community_post_model.dart';
import 'package:blocnet/features/community/data/models/community_topic.dart';
import 'package:blocnet/services/api/api_client.dart';

class CommunityPostsApiRepository {
  CommunityPostsApiRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CommunityPost>> fetchPosts({
    int limit = 100,
    int offset = 0,
    CommunityTopic? topic,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
    };

    if (topic != null) {
      query['topic'] = topic.apiValue;
    }

    final response = await _apiClient.get('/community-posts', query: query);
    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(CommunityPost.fromApi)
        .toList();
  }

  Future<CommunityPost?> fetchPostById(String postId) async {
    final response = await _apiClient.get('/community-posts/$postId');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<CommunityPost?> createPost({
    required String content,
    required CommunityTopic topic,
  }) async {
    final response = await _apiClient.post(
      '/community-posts',
      body: {
        'content': content,
        'topic': topic.apiValue,
      },
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<List<CommunityPostComment>> fetchComments(
    String postId, {
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
        await _apiClient.get('/community-posts/$postId/comments', query: query);
    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(CommunityPostComment.fromApi)
        .toList();
  }

  Future<CommunityPostComment?> createComment({
    required String postId,
    required String content,
    String? replyToId,
  }) async {
    final body = <String, dynamic>{'content': content};
    if (replyToId != null) {
      body['replyToId'] = replyToId;
    }

    final response = await _apiClient.post(
      '/community-posts/$postId/comments',
      body: body,
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPostComment.fromApi(response);
  }

  Future<CommunityPost?> likePost(String postId) async {
    final response = await _apiClient.post(
      '/community-posts/$postId/reactions',
      body: {'kind': 'like'},
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<CommunityPost?> unlikePost(String postId) async {
    final response =
        await _apiClient.delete('/community-posts/$postId/reactions');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<CommunityPost?> bookmarkPost(String postId) async {
    final response = await _apiClient.post('/community-posts/$postId/bookmark');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<CommunityPost?> unbookmarkPost(String postId) async {
    final response =
        await _apiClient.delete('/community-posts/$postId/bookmark');
    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPost.fromApi(response);
  }

  Future<List<CommunityPost>> fetchBookmarks({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/me/bookmarks',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(CommunityPost.fromApi)
        .toList();
  }

  Future<CommunityPostComment?> likeComment(String commentId) async {
    final response = await _apiClient.post(
      '/community-post-comments/$commentId/reactions',
      body: {'kind': 'like'},
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPostComment.fromApi(response);
  }

  Future<CommunityPostComment?> unlikeComment(String commentId) async {
    final response = await _apiClient.delete(
      '/community-post-comments/$commentId/reactions',
    );

    if (response is! Map<String, dynamic>) {
      return null;
    }

    return CommunityPostComment.fromApi(response);
  }
}
